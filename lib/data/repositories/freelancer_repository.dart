import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/freelancer.dart';
import '../../models/application.dart';
import '../../core/supabase/supabase_config.dart';
import '../mock/mock_data.dart';

class FreelancerState {
  final List<FreelancerCandidate> allCandidates;
  final List<FreelancerApplication> myApplications;
  final bool isLoading;

  FreelancerState({
    required this.allCandidates,
    required this.myApplications,
    this.isLoading = false,
  });

  FreelancerState copyWith({
    List<FreelancerCandidate>? allCandidates,
    List<FreelancerApplication>? myApplications,
    bool? isLoading,
  }) {
    return FreelancerState(
      allCandidates: allCandidates ?? this.allCandidates,
      myApplications: myApplications ?? this.myApplications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FreelancerNotifier extends StateNotifier<FreelancerState> {
  RealtimeChannel? _applicationsChannel;

  FreelancerNotifier()
      : super(FreelancerState(
          allCandidates: MockData.allCandidates,
          myApplications: MockData.initialApplications,
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
    if (client == null) return;

    try {
      final candidatesRes = await client.from('freelancer_profiles').select('''
        *,
        profiles:id (full_name, email, phone, avatar_url),
        freelancer_skills (skill_name)
      ''');

      if (candidatesRes.isNotEmpty) {
        final List<FreelancerCandidate> list = [];
        for (var cMap in candidatesRes) {
          final skillsRes = cMap['freelancer_skills'] as List? ?? [];
          final skills = skillsRes.map((s) => s['skill_name'] as String).toList();
          list.add(FreelancerCandidate.fromSupabase(cMap, skillsList: skills));
        }
        state = state.copyWith(allCandidates: list);
      }
    } catch (e) {
      debugPrint('[Supabase] Candidates fetch fallback: $e');
    }
  }

  Future<void> fetchApplicationsFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final appRes = await client.from('applications').select('''
        *,
        events:event_id (name)
      ''');

      if (appRes.isNotEmpty) {
        final list = appRes.map((a) => FreelancerApplication.fromSupabase(a)).toList();
        state = state.copyWith(myApplications: list);
      }
    } catch (e) {
      debugPrint('[Supabase] Applications fetch fallback: $e');
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
    } catch (e) {
      debugPrint('Notice: Application saved locally (Supabase insert message: $e)');
    }
  }
}

final freelancerProvider =
    StateNotifierProvider<FreelancerNotifier, FreelancerState>((ref) {
  return FreelancerNotifier();
});
