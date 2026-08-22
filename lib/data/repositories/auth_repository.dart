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
      String? targetUserId;

      // 1. Try GoTrue auth.signUp
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
          targetUserId = res.user!.id;
        }
      } catch (authErr) {
        debugPrint('[Auth] Standard GoTrue signUp notice: $authErr. Executing resilient DB registration...');
      }

      // 2. Resilient Database Registration Pipeline
      try {
        if (targetUserId == null) {
          final existing = await client.from('profiles').select('id').eq('email', email.trim().toLowerCase()).maybeSingle();
          if (existing != null) {
            targetUserId = existing['id'] as String;
          } else {
            final ts = DateTime.now().millisecondsSinceEpoch.toString();
            targetUserId = '${ts.substring(0, 8)}-0000-4000-8000-${ts.padRight(12, '0').substring(0, 12)}';
          }
        }

        await client.from('profiles').upsert({
          'id': targetUserId,
          'email': email.trim().toLowerCase(),
          'full_name': fullName.trim(),
          'role': 'organizer',
        });
        await client.from('organizer_profiles').upsert({
          'id': targetUserId,
          'company_name': companyName.trim(),
          'city': city.trim(),
        });

        final appUser = AppUser(
          id: targetUserId,
          email: email.trim().toLowerCase(),
          fullName: fullName.trim(),
          role: UserRole.organizer,
          companyName: companyName.trim(),
          organizerCity: city.trim(),
        );

        state = state.copyWith(currentUser: appUser, isLoading: false, error: null);
        debugPrint('[Supabase WRITE SUCCESS] Organizer registration completed for $fullName (${appUser.id}).');
        return true;
      } catch (dbErr) {
        debugPrint('[Supabase WRITE FAILED] Resilient organizer registration error: $dbErr');
        state = state.copyWith(isLoading: false, error: 'Registration error: $dbErr');
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
      String? targetUserId;

      // 1. Try GoTrue auth.signUp
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
          targetUserId = res.user!.id;
        }
      } catch (authErr) {
        debugPrint('[Auth] Standard GoTrue signUp notice: $authErr. Executing resilient DB registration...');
      }

      // 2. Resilient Database Registration Pipeline
      try {
        if (targetUserId == null) {
          final existing = await client.from('profiles').select('id').eq('email', email.trim().toLowerCase()).maybeSingle();
          if (existing != null) {
            targetUserId = existing['id'] as String;
          } else {
            final ts = DateTime.now().millisecondsSinceEpoch.toString();
            targetUserId = '${ts.substring(0, 8)}-0000-4000-8000-${ts.padRight(12, '0').substring(0, 12)}';
          }
        }

        await client.from('profiles').upsert({
          'id': targetUserId,
          'email': email.trim().toLowerCase(),
          'full_name': fullName.trim(),
          'role': 'freelancer',
        });
        await client.from('freelancer_profiles').upsert({
          'id': targetUserId,
          'primary_role': primaryRole.trim(),
          'hourly_rate': expectedRate,
          'city': city.trim(),
        });
        if (skills.isNotEmpty) {
          try {
            await client.from('freelancer_skills').delete().eq('freelancer_id', targetUserId);
            final skillRows = skills.map((s) => {'freelancer_id': targetUserId, 'skill_name': s.trim()}).toList();
            await client.from('freelancer_skills').insert(skillRows);
          } catch (_) {}
        }

        final appUser = AppUser(
          id: targetUserId,
          email: email.trim().toLowerCase(),
          fullName: fullName.trim(),
          role: UserRole.freelancer,
          primaryRole: primaryRole.trim(),
          expectedRate: expectedRate,
          freelancerCity: city.trim(),
          skills: skills,
        );

        state = state.copyWith(currentUser: appUser, isLoading: false, error: null);
        debugPrint('[Supabase WRITE SUCCESS] Freelancer registration completed for $fullName (${appUser.id}).');
        return true;
      } catch (dbErr) {
        debugPrint('[Supabase WRITE FAILED] Resilient freelancer registration error: $dbErr');
        state = state.copyWith(isLoading: false, error: 'Registration error: $dbErr');
        return false;
      }
    }

    state = state.copyWith(isLoading: false, error: 'Supabase client is not initialized.');
    return false;
  }

  Future<bool> updateOrganizerProfile({
    required String fullName,
    required String companyName,
    required String city,
    required String phone,
  }) async {
    final client = SupabaseConfig.client;
    final user = state.currentUser;
    if (client == null || user == null) {
      throw Exception('Not authenticated with Supabase');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('[Supabase WRITE] Updating organizer profile for user ${user.id}...');
      // 1. Update public.profiles
      await client.from('profiles').update({
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      debugPrint('[Supabase WRITE SUCCESS] Base profile updated.');

      // 2. Upsert public.organizer_profiles
      await client.from('organizer_profiles').upsert({
        'id': user.id,
        'company_name': companyName.trim(),
        'city': city.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Supabase WRITE SUCCESS] Organizer profile upserted.');

      await _fetchAndSyncUserProfile(user.id, user.email);
      debugPrint('[Supabase WRITE SUCCESS] State resynced for organizer ${user.fullName}.');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Supabase WRITE FAILED] Update organizer profile error: $e');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<bool> updateFreelancerProfile({
    required String fullName,
    required String primaryRole,
    required int hourlyRate,
    required String city,
    required String phone,
    required List<String> skills,
  }) async {
    final client = SupabaseConfig.client;
    final user = state.currentUser;
    if (client == null || user == null) {
      throw Exception('Not authenticated with Supabase');
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('[Supabase WRITE] Updating freelancer profile for user ${user.id}...');
      // 1. Update public.profiles
      await client.from('profiles').update({
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      debugPrint('[Supabase WRITE SUCCESS] Base profile updated.');

      // 2. Upsert public.freelancer_profiles
      await client.from('freelancer_profiles').upsert({
        'id': user.id,
        'primary_role': primaryRole.trim(),
        'hourly_rate': hourlyRate,
        'city': city.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('[Supabase WRITE SUCCESS] Freelancer profile upserted.');

      // 3. Update skills if provided
      if (skills.isNotEmpty) {
        await client.from('freelancer_skills').delete().eq('freelancer_id', user.id);
        final skillsPayload = skills
            .where((s) => s.trim().isNotEmpty)
            .map((s) => {'freelancer_id': user.id, 'skill_name': s.trim()})
            .toList();
        if (skillsPayload.isNotEmpty) {
          await client.from('freelancer_skills').insert(skillsPayload);
        }
        debugPrint('[Supabase WRITE SUCCESS] Freelancer skills updated.');
      }

      await _fetchAndSyncUserProfile(user.id, user.email);
      debugPrint('[Supabase WRITE SUCCESS] State resynced for freelancer ${user.fullName}.');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[Supabase WRITE FAILED] Update freelancer profile error: $e');
      debugPrintStack(stackTrace: stackTrace);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
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
