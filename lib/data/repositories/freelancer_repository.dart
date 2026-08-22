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
      final candidatesRes = await client.from('freelancer_profiles').select('''
        *,
        profiles:id (full_name, email, phone, avatar_url),
        freelancer_skills (skill_name)
      ''');

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

  Future<void> fetchApplicationsFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      state = state.copyWith(myApplications: const [], isLoading: false);
      return;
    }

    try {
      final appRes = await client.from('applications').select('''
        *,
        events:event_id (name)
      ''');

      final list = (appRes as List)
          .map((a) => FreelancerApplication.fromSupabase(a))
          .toList();
      state = state.copyWith(myApplications: list, isLoading: false);
    } catch (e) {
      debugPrint('[Supabase] Applications fetch error: $e');
      state = state.copyWith(myApplications: const [], isLoading: false, error: e.toString());
    }
  }

  bool applyToEvent(
    String eventId,
    String eventName,
    String freelancerId,
    String role,
    int rate,
  ) {
    if (state.myApplications.any((a) => a.eventId == eventId && a.freelancerId == freelancerId)) {
      return false;
    }

    final newApp = FreelancerApplication(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      eventName: eventName,
      freelancerId: freelancerId,
      appliedRole: role,
      proposedRate: rate,
      status: ApplicationStatus.pending,
      appliedDate: DateTime.now().toString().substring(0, 10),
      feedback: 'Application submitted via MUSTER matching portal.',
    );

    state = state.copyWith(myApplications: [newApp, ...state.myApplications]);
    _persistApplicationToSupabase(newApp);
    return true;
  }

  Future<void> _persistApplicationToSupabase(FreelancerApplication app) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final validFreelancerId = (app.freelancerId.length == 36)
          ? app.freelancerId
          : '00000000-0000-0000-0000-000000000002';

      await client.from('applications').insert({
        'event_id': app.eventId,
        'freelancer_id': validFreelancerId,
        'applied_role': app.appliedRole,
        'proposed_rate': app.proposedRate,
        'status': 'pending',
        'feedback': app.feedback,
      });
      debugPrint('[Supabase] Application persisted for ${app.eventName}');
      await fetchApplicationsFromSupabase();
    } catch (e) {
      debugPrint('[Supabase] Application persist error: $e');
    }
  }
}

final freelancerProvider =
    StateNotifierProvider<FreelancerNotifier, FreelancerState>((ref) {
  return FreelancerNotifier();
});
