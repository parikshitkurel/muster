import '../../models/user.dart';
import '../../models/event.dart';
import '../../models/freelancer.dart';
import '../../models/application.dart';
import '../../models/notification.dart';

/// Clean definitions - Supabase is the single source of truth for all application data.
class MockData {
  static final AppUser organizerUser = AppUser(
    id: '00000000-0000-0000-0000-000000000001',
    email: 'organizer01@muster.test',
    fullName: 'Arjun Mehta',
    role: UserRole.organizer,
    companyName: 'TechNova Events',
    organizerCity: 'Indore, Madhya Pradesh',
  );

  static final AppUser organizer02User = AppUser(
    id: '00000000-0000-0000-0000-000000000002',
    email: 'organizer02@muster.test',
    fullName: 'Riya Kapoor',
    role: UserRole.organizer,
    companyName: 'NextWave Productions',
    organizerCity: 'Bhopal, Madhya Pradesh',
  );

  static final AppUser freelancerUser = AppUser(
    id: 'f0000000-0000-0000-0000-000000000001',
    email: 'freelancer01@muster.test',
    fullName: 'Aarav Sharma',
    role: UserRole.freelancer,
    primaryRole: 'Event Operations',
    expectedRate: 1500,
    experienceYears: 5,
    reliabilityScore: 96,
    freelancerCity: 'Indore, Madhya Pradesh',
    skills: const ['Event Management', 'Registration', 'Crowd Management'],
  );

  static List<EventItem> get initialEvents => const [];
  static List<FreelancerCandidate> get allCandidates => const [];
  static List<FreelancerApplication> get initialApplications => const [];
  static List<AppNotification> get initialNotifications => const [];
}
