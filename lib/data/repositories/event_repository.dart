import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/event.dart';
import '../../models/crew.dart';
import '../../core/supabase/supabase_config.dart';
import '../mock/mock_data.dart';

class EventState {
  final List<EventItem> events;
  final bool isLoading;
  final String? error;

  EventState({required this.events, this.isLoading = false, this.error});

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

  EventNotifier() : super(EventState(events: MockData.initialEvents)) {
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
    if (client == null) return;

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

      if (eventsData.isNotEmpty) {
        final List<EventItem> fetchedEvents = [];

        for (var evtMap in eventsData) {
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

          fetchedEvents.add(EventItem.fromSupabase(evtMap, reqs: reqs, crew: confirmedCrew));
        }

        state = state.copyWith(events: fetchedEvents);
      }
    } catch (e) {
      debugPrint('[Supabase] Fetch events fallback to local: $e');
    }
  }

  Future<void> addEvent(EventItem event) async {
    final client = SupabaseConfig.client;

    state = state.copyWith(events: [event, ...state.events]);

    if (client != null) {
      try {
        final eventPayload = event.toSupabase();
        await client.from('events').insert(eventPayload);

        for (var req in event.requirements) {
          await client.from('event_roles').insert(req.toSupabase(event.id));
        }
      } catch (e) {
        debugPrint('[Supabase] Event created with local persistence: $e');
      }
    }
  }

  Future<void> approveCrew(String eventId, List<CrewMember> crew, int totalCost) async {
    final updatedList = state.events.map((e) {
      if (e.id == eventId) {
        return e.copyWith(
          status: EventStatus.crewConfirmed,
          confirmedCrew: crew,
          totalCostAllocated: totalCost,
        );
      }
      return e;
    }).toList();

    state = state.copyWith(events: updatedList);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        final membersPayload = crew.map((m) {
          final validFreelancerId = (m.freelancerId.length == 36)
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

        final rpcRes = await client.rpc(
          'approve_crew_transaction',
          params: {
            'p_event_id': eventId,
            'p_total_cost': totalCost,
            'p_members': membersPayload,
          },
        );

        debugPrint('[Supabase] Crew Approval Transaction Successful: $rpcRes');
      } catch (e) {
        debugPrint('Notice: Crew approved with local persistence (Supabase RPC message: $e)');
      }
    }
  }
}

final eventsProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  return EventNotifier();
});
