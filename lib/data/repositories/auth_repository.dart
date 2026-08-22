import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../core/supabase/supabase_config.dart';
import '../mock/mock_data.dart';

class AuthState {
  final AppUser? currentUser;
  final bool isLoading;
  final String? error;

  AuthState({this.currentUser, this.isLoading = false, this.error});

  bool get isAuthenticated => currentUser != null;
  bool get isOrganizer => currentUser?.isOrganizer ?? false;
  bool get isFreelancer => currentUser?.isFreelancer ?? false;

  AuthState copyWith({AppUser? currentUser, bool? isLoading, String? error}) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(currentUser: MockData.organizerUser)) {
    _initSupabaseListener();
  }

  void _initSupabaseListener() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _fetchAndSyncUserProfile(session.user.id, session.user.email ?? '');
      }
    });
  }

  Future<void> _fetchAndSyncUserProfile(String userId, String email) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final profileRes = await client.from('profiles').select().eq('id', userId).maybeSingle();
      if (profileRes != null) {
        final roleStr = profileRes['role'] as String? ?? 'organizer';
        Map<String, dynamic>? roleProfile;
        List<String>? skillsList;

        if (roleStr == 'organizer') {
          roleProfile = await client.from('organizer_profiles').select().eq('id', userId).maybeSingle();
        } else {
          roleProfile = await client.from('freelancer_profiles').select().eq('id', userId).maybeSingle();
          final skillsRes = await client.from('freelancer_skills').select('skill_name').eq('freelancer_id', userId);
          skillsList = (skillsRes as List).map((s) => s['skill_name'] as String).toList();
        }

        final appUser = AppUser.fromSupabase(profileRes, roleMap: roleProfile, skillsList: skillsList);
        state = state.copyWith(currentUser: appUser, isLoading: false);
      }
    } catch (e) {
      debugPrint('[Auth] Profile sync error: $e');
    }
  }

  Future<bool> login(String email, String password, UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final response = await client.auth.signInWithPassword(email: email, password: password);
        if (response.user != null) {
          await _fetchAndSyncUserProfile(response.user!.id, email);
          return true;
        }
      } catch (e) {
        debugPrint('[Auth] Supabase signIn error: $e. Falling back to local authentication.');
      }
    }

    // Local fallback for offline/demo reliability
    await Future.delayed(const Duration(milliseconds: 300));
    AppUser demoUser;

    if (email == 'organizer02@muster.test') {
      demoUser = MockData.organizer02User;
    } else if (email.startsWith('freelancer') || role == UserRole.freelancer) {
      final cand = MockData.allCandidates.firstWhere(
        (c) => c.email == email,
        orElse: () => MockData.allCandidates.first,
      );
      demoUser = AppUser(
        id: cand.id,
        email: cand.email,
        fullName: cand.name,
        role: UserRole.freelancer,
        primaryRole: cand.role,
        expectedRate: cand.expectedRate,
        experienceYears: cand.experienceYears,
        reliabilityScore: cand.reliabilityScore,
        freelancerCity: 'Indore, Madhya Pradesh',
        skills: cand.skills,
      );
    } else {
      demoUser = MockData.organizerUser;
    }

    state = state.copyWith(currentUser: demoUser, isLoading: false);
    return true;
  }

  Future<bool> signUpOrganizer({
    required String email,
    required String password,
    required String fullName,
    required String companyName,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'role': 'organizer',
            'full_name': fullName,
            'company_name': companyName,
            'city': city,
          },
        );
        if (res.user != null) {
          final newUser = AppUser(
            id: res.user!.id,
            email: email,
            fullName: fullName,
            role: UserRole.organizer,
            companyName: companyName,
            organizerCity: city,
          );
          state = state.copyWith(currentUser: newUser, isLoading: false);
          return true;
        }
      } catch (e) {
        debugPrint('[Auth] Supabase signUpOrganizer message: $e');
      }
    }

    final newUser = AppUser(
      id: 'org_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      role: UserRole.organizer,
      companyName: companyName,
      organizerCity: city,
    );
    state = state.copyWith(currentUser: newUser, isLoading: false);
    return true;
  }

  Future<bool> signUpFreelancer({
    required String email,
    required String password,
    required String fullName,
    required String primaryRole,
    required int expectedRate,
    required String city,
    required List<String> skills,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'role': 'freelancer',
            'full_name': fullName,
            'primary_role': primaryRole,
            'hourly_rate': expectedRate,
            'city': city,
          },
        );
        if (res.user != null) {
          final newUser = AppUser(
            id: res.user!.id,
            email: email,
            fullName: fullName,
            role: UserRole.freelancer,
            primaryRole: primaryRole,
            expectedRate: expectedRate,
            freelancerCity: city,
            skills: skills,
          );
          state = state.copyWith(currentUser: newUser, isLoading: false);
          return true;
        }
      } catch (e) {
        debugPrint('[Auth] Supabase signUpFreelancer message: $e');
      }
    }

    final newUser = AppUser(
      id: 'free_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      role: UserRole.freelancer,
      primaryRole: primaryRole,
      expectedRate: expectedRate,
      freelancerCity: city,
      skills: skills,
    );
    state = state.copyWith(currentUser: newUser, isLoading: false);
    return true;
  }

  void switchRole(UserRole newRole) {
    if (newRole == UserRole.organizer) {
      state = state.copyWith(currentUser: MockData.organizerUser);
    } else {
      state = state.copyWith(currentUser: MockData.freelancerUser);
    }
  }

  Future<void> logout() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (_) {}
    }
    state = AuthState(currentUser: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
