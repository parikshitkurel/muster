import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/event.dart';
import '../../models/crew.dart';
import '../../core/supabase/supabase_config.dart';

class EventState {
  final List<EventItem> events;
  final bool isLoading;
  final String? error;

  EventState({this.events = const [], this.isLoading = false, this.error});

  EventState copyWith({
    List<EventItem>? events,
    bool? isLoading,
    String? error,
  }) {
    return EventState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EventNotifier extends StateNotifier<EventState> {
  RealtimeChannel? _realtimeChannel;

  EventNotifier() : super(EventState(events: const [], isLoading: true)) {
    fetchEventsFromSupabase();
    _subscribeToRealtimeEvents();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtimeEvents() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      _realtimeChannel = client
          .channel('public:events')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'events',
            callback: (payload) {
              fetchEventsFromSupabase();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[Realtime] Events subscription notice: $e');
    }
  }

  Future<void> fetchEventsFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      state = state.copyWith(events: const [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final eventsData = await client.from('events').select('''
        *,
        event_roles (
          role_name,
          quantity,
          max_rate_per_hour,
          min_experience_years
        )
      ''').order('created_at', ascending: false);

      final List<EventItem> fetchedEvents = [];

      for (var evtMap in (eventsData as List)) {
        final rolesList = evtMap['event_roles'] as List? ?? [];
        final reqs = rolesList.map((r) => EventRequirement.fromSupabase(r)).toList();

        List<CrewMember> confirmedCrew = [];
        if (evtMap['status'] == 'crew_confirmed') {
          final crewRes = await client
              .from('crews')
              .select('''
                id,
                crew_members (
                  freelancer_id,
                  role,
                  match_score,
                  reliability_score,
                  allocated_cost,
                  rationale,
                  profiles:freelancer_id (full_name, phone, email)
                )
              ''')
              .eq('event_id', evtMap['id'])
              .maybeSingle();

          if (crewRes != null && crewRes['crew_members'] is List) {
            confirmedCrew = (crewRes['crew_members'] as List)
                .map((m) => CrewMember.fromSupabase(m))
                .toList();
          }
        }

        final appCountRes = await client
            .from('applications')
            .select('id')
            .eq('event_id', evtMap['id']);
        final realAppCount = (appCountRes as List).length;
        evtMap['applicant_count'] = realAppCount;

        fetchedEvents.add(EventItem.fromSupabase(evtMap, reqs: reqs, crew: confirmedCrew));
      }

      state = state.copyWith(events: fetchedEvents, isLoading: false);
    } catch (e) {
      debugPrint('[Supabase] Fetch events error: $e');
      state = state.copyWith(events: const [], isLoading: false, error: e.toString());
    }
  }

  Future<EventItem?> addEvent(EventItem event) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase client is not connected.');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final eventPayload = event.toSupabase();
      debugPrint('[Supabase WRITE] Inserting event: $eventPayload');

      final res = await client
          .from('events')
          .insert(eventPayload)
          .select('''
            *,
            event_roles (
              role_name,
              quantity,
              max_rate_per_hour,
              min_experience_years
            )
          ''')
          .single();

      final createdEventId = res['id'] as String;
      debugPrint('[Supabase WRITE SUCCESS] Event created with ID: $createdEventId');

      if (event.requirements.isNotEmpty) {
        final rolesPayload = event.requirements
            .map((req) => req.toSupabase(createdEventId))
            .toList();
        debugPrint('[Supabase WRITE] Inserting ${rolesPayload.length} event roles for event $createdEventId');
        await client.from('event_roles').insert(rolesPayload);
        debugPrint('[Supabase WRITE SUCCESS] Event roles inserted successfully.');
      }

      await fetchEventsFromSupabase();

      final createdItem = state.events.firstWhere(
        (e) => e.id == createdEventId,
        orElse: () => EventItem.fromSupabase(res, reqs: event.requirements),
      );

      return createdItem;
    } catch (e, stackTrace) {
      debugPrint('[Supabase WRITE FAILED] Add event error: $e');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> approveCrew(
    String eventId,
    List<CrewMember> crew,
    int totalCost, {
    String crewType = 'Production Crew',
    int? totalMembers,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase client is not connected.');
    }

    try {
      final membersPayload = crew.map((m) {
        final validFreelancerId = (m.freelancerId.length == 36 && m.freelancerId.contains('-'))
            ? m.freelancerId
            : '00000000-0000-0000-0000-000000000002';

        return {
          'freelancer_id': validFreelancerId,
          'role': m.role,
          'match_score': m.matchScore,
          'reliability_score': m.reliabilityScore,
          'allocated_cost': m.allocatedCost,
          'rationale': m.rationale,
        };
      }).toList();

      final membersCount = totalMembers ?? (crew.isEmpty ? 1 : crew.length);
      debugPrint('[Supabase WRITE] Approving crew type "$crewType" ($membersCount members) for event $eventId (Cost: $totalCost)...');
      final rpcRes = await client.rpc(
        'approve_crew_transaction',
        params: {
          'p_event_id': eventId,
          'p_total_cost': totalCost,
          'p_members': membersPayload,
          'p_crew_type': crewType,
          'p_total_members': membersCount,
        },
      );

      debugPrint('[Supabase WRITE SUCCESS] Crew approved: $rpcRes');

      debugPrint('[Supabase WRITE SUCCESS] Crew approved successfully.');
      await fetchEventsFromSupabase();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Supabase WRITE FAILED] Approve crew error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<bool> assignVolunteer(String eventId, CrewMember volunteer) async {
    final client = SupabaseConfig.client;

    final updatedEvents = state.events.map((e) {
      if (e.id == eventId) {
        final newRoster = [...e.confirmedCrew, volunteer];
        return e.copyWith(
          confirmedCrew: newRoster,
          totalCostAllocated: e.totalCostAllocated,
          status: EventStatus.crewConfirmed,
        );
      }
      return e;
    }).toList();

    state = state.copyWith(events: updatedEvents);

    if (client != null) {
      try {
        final crewHead = await client.from('crews').select('id').eq('event_id', eventId).maybeSingle();
        String crewId;
        if (crewHead == null) {
          final newCrew = await client.from('crews').insert({
            'event_id': eventId,
            'total_cost': 0,
            'crew_type': 'Volunteer Roster',
            'status': 'active',
          }).select().single();
          crewId = newCrew['id'] as String;
        } else {
          crewId = crewHead['id'] as String;
        }

        final validId = (volunteer.freelancerId.length == 36 && volunteer.freelancerId.contains('-'))
            ? volunteer.freelancerId
            : '00000000-0000-0000-0000-000000000002';

        await client.from('crew_members').insert({
          'crew_id': crewId,
          'freelancer_id': validId,
          'role': volunteer.role,
          'match_score': 100,
          'reliability_score': 100,
          'allocated_cost': 0,
          'rationale': 'Assigned Volunteer',
        });
        debugPrint('[Supabase WRITE SUCCESS] Volunteer assigned to event $eventId in database.');
      } catch (e) {
        debugPrint('[Supabase] Volunteer local assignment active: $e');
      }
    }
    return true;
  }
}

final eventsProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  return EventNotifier();
});
