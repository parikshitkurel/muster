import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/freelancer.dart';
import '../../models/application.dart';
import '../../core/supabase/supabase_config.dart';

class FreelancerState {
  final List<FreelancerCandidate> allCandidates;
  final List<FreelancerApplication> myApplications;
  final bool isLoading;
  final String? error;

  FreelancerState({
    this.allCandidates = const [],
    this.myApplications = const [],
    this.isLoading = false,
    this.error,
  });

  FreelancerState copyWith({
    List<FreelancerCandidate>? allCandidates,
    List<FreelancerApplication>? myApplications,
    bool? isLoading,
    String? error,
  }) {
    return FreelancerState(
      allCandidates: allCandidates ?? this.allCandidates,
      myApplications: myApplications ?? this.myApplications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FreelancerNotifier extends StateNotifier<FreelancerState> {
  RealtimeChannel? _applicationsChannel;

  FreelancerNotifier()
      : super(FreelancerState(
          allCandidates: const [],
          myApplications: const [],
          isLoading: true,
        )) {
    fetchCandidatesFromSupabase();
    fetchApplicationsFromSupabase();
    _subscribeToApplications();
  }

  @override
  void dispose() {
    _applicationsChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToApplications() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      _applicationsChannel = client
          .channel('public:applications')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'applications',
            callback: (payload) {
              fetchApplicationsFromSupabase();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[Realtime] Applications subscription notice: $e');
    }
  }

  Future<void> fetchCandidatesFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      state = state.copyWith(allCandidates: const [], isLoading: false);
      return;
    }

    try {
      dynamic candidatesRes;
      try {
        candidatesRes = await client.from('freelancer_profiles').select('''
          *,
          profiles!id (full_name, email, phone, avatar_url),
          freelancer_skills!freelancer_id (skill_name)
        ''');
      } catch (fkeyErr) {
        debugPrint('[Supabase] Primary FK join notice: $fkeyErr. Trying secondary FK syntax...');
        try {
          candidatesRes = await client.from('freelancer_profiles').select('''
            *,
            profiles!id (full_name, email, phone, avatar_url),
            freelancer_skills!freelancer_skills_freelancer_id_fkey(*)
          ''');
        } catch (_) {
          candidatesRes = await client.from('freelancer_profiles').select('''
            *,
            profiles!id (full_name, email, phone, avatar_url),
            freelancer_skills (skill_name)
          ''');
        }
      }

      final List<FreelancerCandidate> list = [];
      for (var cMap in (candidatesRes as List)) {
        final skillsRes = cMap['freelancer_skills'] as List? ?? [];
        final skills = skillsRes.map((s) => s['skill_name'] as String).toList();
        list.add(FreelancerCandidate.fromSupabase(cMap, skillsList: skills));
      }
      state = state.copyWith(allCandidates: list, isLoading: false);
    } catch (e) {
      debugPrint('[Supabase] Candidates fetch error: $e');
      state = state.copyWith(allCandidates: const [], isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchApplicationsFromSupabase({String? userId}) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      state = state.copyWith(myApplications: const [], isLoading: false);
      return;
    }

    final targetUserId = userId ?? client.auth.currentUser?.id;
    if (targetUserId == null || targetUserId.isEmpty) {
      // Unauthenticated or unknown freelancer: myApplications must be empty
      state = state.copyWith(myApplications: const [], isLoading: false);
      return;
    }

    try {
      final appRes = await client
          .from('applications')
          .select('''
            *,
            events:event_id (name)
          ''')
          .eq('freelancer_id', targetUserId);

      final list = (appRes as List)
          .map((a) => FreelancerApplication.fromSupabase(a))
          .toList();
      state = state.copyWith(myApplications: list, isLoading: false);
    } catch (e) {
      debugPrint('[Supabase] Applications fetch error: $e');
      state = state.copyWith(myApplications: const [], isLoading: false, error: e.toString());
    }
  }

  Future<bool> applyToEvent(
    String eventId,
    String eventName,
    String freelancerId,
    String role,
    int rate,
  ) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase client is not connected.');
    }

    final validFreelancerId = (freelancerId.length == 36 && freelancerId.contains('-'))
        ? freelancerId
        : (client.auth.currentUser?.id ?? '00000000-0000-0000-0000-000000000002');

    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('[Supabase WRITE] Submitting application for event $eventId by freelancer $validFreelancerId...');
      final insertRes = await client.from('applications').insert({
        'event_id': eventId,
        'freelancer_id': validFreelancerId,
        'applied_role': role,
        'proposed_rate': rate,
        'status': 'pending',
        'feedback': 'Application submitted via MUSTER matching portal.',
      }).select().single();

      debugPrint('[Supabase WRITE SUCCESS] Application created with ID: ${insertRes['id']}');

      final newApp = FreelancerApplication(
        id: insertRes['id'] as String,
        eventId: eventId,
        eventName: eventName,
        freelancerId: validFreelancerId,
        appliedRole: role,
        proposedRate: rate,
        status: ApplicationStatus.pending,
        appliedDate: 'Just now',
      );

      final updatedList = [
        ...state.myApplications.where((a) => a.eventId != eventId),
        newApp,
      ];
      state = state.copyWith(myApplications: updatedList, isLoading: false);

      // Auto-create notification for organizer
      try {
        final evtRes = await client.from('events').select('organizer_id, name').eq('id', eventId).maybeSingle();
        if (evtRes != null && evtRes['organizer_id'] != null) {
          final orgId = evtRes['organizer_id'] as String;
          await client.from('notifications').insert({
            'user_id': orgId,
            'title': 'New Candidate Application',
            'message': 'A candidate applied for $role in ${evtRes['name']}.',
            'type': 'candidate_applied',
            'related_event_id': eventId,
          });
          debugPrint('[Supabase WRITE SUCCESS] Notification sent to organizer $orgId.');
        }
      } catch (notifErr) {
        debugPrint('[Supabase] Non-critical notification write error: $notifErr');
      }

      await fetchApplicationsFromSupabase(userId: validFreelancerId);
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Supabase WRITE FAILED] Application persist error: $e');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> updateApplicationStatus(String applicationId, ApplicationStatus status) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception('Supabase client is not connected.');
    }

    try {
      String statusStr = 'pending';
      if (status == ApplicationStatus.shortlisted) statusStr = 'shortlisted';
      if (status == ApplicationStatus.selected) statusStr = 'selected';
      if (status == ApplicationStatus.rejected) statusStr = 'rejected';

      debugPrint('[Supabase WRITE] Updating application $applicationId status to $statusStr...');
      await client.from('applications').update({
        'status': statusStr,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', applicationId);

      debugPrint('[Supabase WRITE SUCCESS] Application status updated.');
      await fetchApplicationsFromSupabase();
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Supabase WRITE FAILED] Update application status error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}

final freelancerProvider =
    StateNotifierProvider<FreelancerNotifier, FreelancerState>((ref) {
  return FreelancerNotifier();
});
