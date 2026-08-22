import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_config.dart';

import 'features/shell/presentation/app_shell.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/role_selection_screen.dart';
import 'features/auth/presentation/organizer_registration_screen.dart';
import 'features/auth/presentation/freelancer_registration_screen.dart';

import 'features/organizer/presentation/organizer_dashboard_screen.dart';
import 'features/organizer/presentation/my_events_screen.dart';
import 'features/organizer/presentation/create_event_screen.dart';
import 'features/organizer/presentation/applicant_pool_screen.dart';
import 'features/organizer/presentation/ai_crew_recommendation_screen.dart';
import 'features/organizer/presentation/final_crew_screen.dart';
import 'features/organizer/presentation/organizer_profile_screen.dart';
import 'features/organizer/presentation/organizer_settings_screen.dart';

import 'features/freelancer/presentation/freelancer_dashboard_screen.dart';
import 'features/freelancer/presentation/browse_events_screen.dart';
import 'features/freelancer/presentation/freelancer_event_details_screen.dart';
import 'features/freelancer/presentation/application_status_screen.dart';
import 'features/freelancer/presentation/freelancer_profile_screen.dart';
import 'features/freelancer/presentation/freelancer_settings_screen.dart';

import 'features/notifications/presentation/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const ProviderScope(child: MusterApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/register/organizer',
      builder: (context, state) => const OrganizerRegistrationScreen(),
    ),
    GoRoute(
      path: '/register/freelancer',
      builder: (context, state) => const FreelancerRegistrationScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // Organizer Core Routes
        GoRoute(
          path: '/organizer/dashboard',
          builder: (context, state) => const OrganizerDashboardScreen(),
        ),
        GoRoute(
          path: '/organizer/my-events',
          builder: (context, state) => const MyEventsScreen(),
        ),
        GoRoute(
          path: '/organizer/create-event',
          builder: (context, state) => const CreateEventScreen(),
        ),
        GoRoute(
          path: '/organizer/applicants/:id',
          builder: (context, state) => ApplicantPoolScreen(
            eventId: state.pathParameters['id'] ?? 'evt_001',
          ),
        ),
        GoRoute(
          path: '/organizer/recommendation/:id',
          builder: (context, state) => AICrewRecommendationScreen(
            eventId: state.pathParameters['id'] ?? 'evt_001',
          ),
        ),
        GoRoute(
          path: '/organizer/final-crew/:id',
          builder: (context, state) => FinalCrewScreen(
            eventId: state.pathParameters['id'] ?? 'evt_001',
          ),
        ),
        GoRoute(
          path: '/organizer/profile',
          builder: (context, state) => const OrganizerProfileScreen(),
        ),
        GoRoute(
          path: '/organizer/settings',
          builder: (context, state) => const OrganizerSettingsScreen(),
        ),

        // Freelancer Core Routes
        GoRoute(
          path: '/freelancer/dashboard',
          builder: (context, state) => const FreelancerDashboardScreen(),
        ),
        GoRoute(
          path: '/freelancer/browse-events',
          builder: (context, state) => const BrowseEventsScreen(),
        ),
        GoRoute(
          path: '/freelancer/event/:id',
          builder: (context, state) => FreelancerEventDetailsScreen(
            eventId: state.pathParameters['id'] ?? 'evt_001',
          ),
        ),
        GoRoute(
          path: '/freelancer/applications',
          builder: (context, state) => const ApplicationStatusScreen(),
        ),
        GoRoute(
          path: '/freelancer/profile',
          builder: (context, state) => const FreelancerProfileScreen(),
        ),
        GoRoute(
          path: '/freelancer/settings',
          builder: (context, state) => const FreelancerSettingsScreen(),
        ),

        // Notifications
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    ),
  ],
);

class MusterApp extends StatelessWidget {
  const MusterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MUSTER — AI Crew Assembly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
