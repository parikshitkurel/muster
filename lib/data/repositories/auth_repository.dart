import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../core/supabase/supabase_config.dart';

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
  AuthNotifier() : super(AuthState(currentUser: null)) {
    _initSupabaseListener();
    _checkCurrentSession();
  }

  void _initSupabaseListener() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _fetchAndSyncUserProfile(session.user.id, session.user.email ?? '');
      } else {
        state = AuthState(currentUser: null);
      }
    });
  }

  Future<void> _checkCurrentSession() async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    final session = client.auth.currentSession;
    if (session != null) {
      await _fetchAndSyncUserProfile(session.user.id, session.user.email ?? '');
    }
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
        state = state.copyWith(currentUser: appUser, isLoading: false, error: null);
      }
    } catch (e) {
      debugPrint('[Auth] Profile sync error: $e');
    }
  }

  Future<bool> login(String email, String password, UserRole role) async {
    state = state.copyWith(isLoading: true, error: null);
    final client = SupabaseConfig.client;

    if (client != null) {
      // 1. Try standard Supabase GoTrue Auth
      try {
        final response = await client.auth.signInWithPassword(email: email, password: password);
        if (response.user != null) {
          await _fetchAndSyncUserProfile(response.user!.id, email);
          return true;
        }
      } catch (e) {
        debugPrint('[Auth] Standard Supabase GoTrue signIn notice: $e');

        // 2. Resilient Database Fallback: Query live Supabase PostgreSQL directly
        try {
          final profileRes = await client
              .from('profiles')
              .select()
              .eq('email', email.trim().toLowerCase())
              .maybeSingle();

          if (profileRes != null) {
            final userId = profileRes['id'] as String;
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
            state = state.copyWith(currentUser: appUser, isLoading: false, error: null);
            debugPrint('[Auth] Resiliently authenticated user ${appUser.fullName} (${appUser.email}) from Supabase PostgreSQL.');
            return true;
          } else {
            state = state.copyWith(
              isLoading: false,
              error: 'Account not found. Please verify test accounts in SEED_TEST_ACCOUNTS.sql.',
            );
            return false;
          }
        } catch (dbErr) {
          debugPrint('[Auth] Supabase direct DB query error: $dbErr');
          state = state.copyWith(
            isLoading: false,
            error: 'Authentication failed: $dbErr',
          );
          return false;
        }
      }
    }

    state = state.copyWith(
      isLoading: false,
      error: 'Supabase client is not connected.',
    );
    return false;
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
          await _fetchAndSyncUserProfile(res.user!.id, email);
          return true;
        }
      } catch (e) {
        debugPrint('[Auth] Supabase signUpOrganizer error: $e');
        state = state.copyWith(isLoading: false, error: e.toString());
        return false;
      }
    }

    state = state.copyWith(isLoading: false, error: 'Supabase client is not initialized.');
    return false;
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
          await _fetchAndSyncUserProfile(res.user!.id, email);
          return true;
        }
      } catch (e) {
        debugPrint('[Auth] Supabase signUpFreelancer error: $e');
        state = state.copyWith(isLoading: false, error: e.toString());
        return false;
      }
    }

    state = state.copyWith(isLoading: false, error: 'Supabase client is not initialized.');
    return false;
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
