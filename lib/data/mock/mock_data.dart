import '../../models/user.dart';
import '../../models/event.dart';
import '../../models/freelancer.dart';
import '../../models/application.dart';
import '../../models/notification.dart';

class MockData {
  // Demo Accounts
  static final AppUser organizerUser = AppUser(
    id: 'a0000000-0000-0000-0000-000000000001',
    email: 'organizer01@muster.test',
    fullName: 'Arjun Mehta',
    role: UserRole.organizer,
    companyName: 'TechNova Events',
    organizerCity: 'Indore, Madhya Pradesh',
  );

  static final AppUser organizer02User = AppUser(
    id: 'a0000000-0000-0000-0000-000000000002',
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

  static List<EventItem> get initialEvents => [
        // Event A: Owned by Organizer 01 (Arjun Mehta - Indore)
        EventItem(
          id: 'e0000000-0000-0000-0000-000000000001',
          organizerId: 'a0000000-0000-0000-0000-000000000001',
          name: 'Indore Tech Leaders Summit 2026',
          type: 'Conference',
          date: '2026-10-15',
          venue: 'Brilliant Convention Centre, Indore',
          city: 'Indore, Madhya Pradesh',
          budget: 120000,
          proximityKm: 60,
          status: EventStatus.published,
          applicantCount: 6,
          description:
              'Premier tech leadership conclave in MP. Requiring technical AV leads, registration staff, hospitality and crowd management.',
          requirements: [
            EventRequirement(
              role: 'AV & Technical Specialist',
              quantity: 1,
              maxRatePerHour: 2200,
              minExperienceYears: 3,
              requiredSkills: ['Technical Support', 'AV', 'Event Technology'],
            ),
            EventRequirement(
              role: 'Event Operations',
              quantity: 1,
              maxRatePerHour: 1800,
              minExperienceYears: 3,
              requiredSkills: ['Event Management', 'Crowd Management'],
            ),
            EventRequirement(
              role: 'Registration Coordinator',
              quantity: 1,
              maxRatePerHour: 1200,
              minExperienceYears: 1,
              requiredSkills: ['Registration', 'Guest Management'],
            ),
          ],
        ),

        // Event B: Owned by Organizer 02 (Riya Kapoor - Bhopal)
        EventItem(
          id: 'e0000000-0000-0000-0000-000000000002',
          organizerId: 'a0000000-0000-0000-0000-000000000002',
          name: 'Bhopal Media & Design Conclave',
          type: 'Exhibition',
          date: '2026-11-20',
          venue: 'Minto Hall Convention Centre, Bhopal',
          city: 'Bhopal, Madhya Pradesh',
          budget: 95000,
          proximityKm: 40,
          status: EventStatus.published,
          applicantCount: 2,
          description:
              'Design and media exhibition showcasing central Indian creative technology and media production.',
          requirements: [
            EventRequirement(
              role: 'Stage Coordinator',
              quantity: 1,
              maxRatePerHour: 1500,
              minExperienceYears: 2,
              requiredSkills: ['Stage Coordination', 'Speaker Management'],
            ),
          ],
        ),

        EventItem(
          id: 'evt_001',
          organizerId: 'a0000000-0000-0000-0000-000000000001',
          name: 'TechSparks 2026',
          type: 'Conference',
          date: '2026-09-15',
          venue: 'KTPO Whitefield, Bengaluru',
          city: 'Bengaluru',
          budget: 150000,
          proximityKm: 25,
          status: EventStatus.published,
          applicantCount: 18,
          description:
              'Flagship annual tech keynote conference. Requiring sound engineers, lighting designers, stage managers, and registration coordinators for multi-track auditoriums.',
          requirements: [
            EventRequirement(
              role: 'Sound Engineer',
              quantity: 2,
              maxRatePerHour: 2200,
              minExperienceYears: 3,
              requiredSkills: ['Dante Audio Protocol', 'Digital Mixing Consoles'],
            ),
            EventRequirement(
              role: 'Lighting Specialist',
              quantity: 2,
              maxRatePerHour: 2000,
              minExperienceYears: 3,
              requiredSkills: ['DMX Programming', 'GrandMA3 Console'],
            ),
            EventRequirement(
              role: 'Stage Coordinator',
              quantity: 3,
              maxRatePerHour: 1200,
              minExperienceYears: 2,
              requiredSkills: ['Speaker Management', 'Run of Show Scheduling'],
            ),
          ],
        ),
      ];

  static List<FreelancerCandidate> get allCandidates => [
        // 6 MP Test Freelancers (With Calibrated Multi-Constraint Variations)
        FreelancerCandidate(
          id: 'f0000000-0000-0000-0000-000000000001',
          name: 'Aarav Sharma',
          role: 'Event Operations',
          expectedRate: 1500, // ₹12,000 / shift
          matchScore: 94,
          reliabilityScore: 96,
          distanceKm: 4.5,
          experienceYears: 5,
          skills: ['Event Management', 'Registration', 'Crowd Management'],
          phone: '+91 98765 11111',
          email: 'freelancer01@muster.test',
        ),
        FreelancerCandidate(
          id: 'f0000000-0000-0000-0000-000000000002',
          name: 'Ishita Verma',
          role: 'Registration Coordinator',
          expectedRate: 1125, // ₹9,000 / shift
          matchScore: 90,
          reliabilityScore: 92,
          distanceKm: 6.0,
          experienceYears: 3,
          skills: ['Hospitality', 'Guest Management', 'Registration'],
          phone: '+91 98765 22222',
          email: 'freelancer02@muster.test',
        ),
        FreelancerCandidate(
          id: 'f0000000-0000-0000-0000-000000000003',
          name: 'Kabir Patel',
          role: 'AV & Technical Specialist',
          expectedRate: 1875, // ₹15,000 / shift
          matchScore: 96,
          reliabilityScore: 98,
          distanceKm: 55.0, // Ujjain
          experienceYears: 6,
          skills: ['Technical Support', 'AV', 'Event Technology'],
          phone: '+91 98765 33333',
          email: 'freelancer03@muster.test',
        ),
        FreelancerCandidate(
          id: 'f0000000-0000-0000-0000-000000000004',
          name: 'Ananya Joshi',
          role: 'Event Operations',
          expectedRate: 1250, // ₹10,000 / shift
          matchScore: 88,
          reliabilityScore: 91,
          distanceKm: 190.0, // Bhopal
          experienceYears: 4,
          skills: ['Hospitality', 'Coordination', 'Guest Management'],
          phone: '+91 98765 44444',
          email: 'freelancer04@muster.test',
        ),
        FreelancerCandidate(
          id: 'f0000000-0000-0000-0000-000000000005',
          name: 'Rohan Singh',
          role: 'Event Operations',
          expectedRate: 1750, // ₹14,000 / shift
          matchScore: 93,
          reliabilityScore: 99,
          distanceKm: 38.0, // Dewas
          experienceYears: 7,
          skills: ['Security', 'Crowd Management', 'Event Operations'],
          phone: '+91 98765 55555',
          email: 'freelancer05@muster.test',
        ),
        FreelancerCandidate(
          id: 'f0000000-0000-0000-0000-000000000006',
          name: 'Meera Shah',
          role: 'Registration Coordinator',
          expectedRate: 875, // ₹7,000 / shift (Cheapest & Closest)
          matchScore: 86,
          reliabilityScore: 85,
          distanceKm: 3.0,
          experienceYears: 2,
          skills: ['Registration', 'Social Media', 'Event Coordination'],
          phone: '+91 98765 66666',
          email: 'freelancer06@muster.test',
        ),
        // Previous Bengaluru Pool
        FreelancerCandidate(
          id: 'free_001',
          name: 'Rohan Mehta',
          role: 'Sound Engineer',
          expectedRate: 1800,
          matchScore: 98,
          reliabilityScore: 98,
          distanceKm: 4.2,
          experienceYears: 5,
          skills: ['Digital Mixing Consoles', 'Dante Audio Protocol', 'Line Array Rigging', 'FOH Management'],
        ),
        FreelancerCandidate(
          id: 'free_002',
          name: 'Ananya Sharma',
          role: 'Lighting Specialist',
          expectedRate: 1650,
          matchScore: 95,
          reliabilityScore: 96,
          distanceKm: 6.8,
          experienceYears: 4,
          skills: ['DMX Programming', 'GrandMA3 Console', 'Moving Head Fixtures', 'Avolites Titan'],
        ),
        FreelancerCandidate(
          id: 'free_003',
          name: 'Karthik Raman',
          role: 'Stage Coordinator',
          expectedRate: 1100,
          matchScore: 94,
          reliabilityScore: 99,
          distanceKm: 3.5,
          experienceYears: 3,
          skills: ['Speaker Management', 'Run of Show Scheduling', 'Hospitality Logistics'],
        ),
      ];

  static List<FreelancerApplication> get initialApplications => [
        FreelancerApplication(
          id: 'app_001',
          eventId: 'e0000000-0000-0000-0000-000000000001',
          eventName: 'Indore Tech Leaders Summit 2026',
          freelancerId: 'f0000000-0000-0000-0000-000000000001',
          appliedRole: 'Event Operations',
          proposedRate: 1500,
          status: ApplicationStatus.pending,
          appliedDate: '2026-08-20',
          feedback: 'Senior MP event operations specialist available for full shift.',
        ),
        FreelancerApplication(
          id: 'app_002',
          eventId: 'e0000000-0000-0000-0000-000000000001',
          eventName: 'Indore Tech Leaders Summit 2026',
          freelancerId: 'f0000000-0000-0000-0000-000000000002',
          appliedRole: 'Registration Coordinator',
          proposedRate: 1125,
          status: ApplicationStatus.pending,
          appliedDate: '2026-08-20',
          feedback: 'Hospitality & registration desk lead with 3 years conference experience.',
        ),
        FreelancerApplication(
          id: 'app_003',
          eventId: 'e0000000-0000-0000-0000-000000000001',
          eventName: 'Indore Tech Leaders Summit 2026',
          freelancerId: 'f0000000-0000-0000-0000-000000000003',
          appliedRole: 'AV & Technical Specialist',
          proposedRate: 1875,
          status: ApplicationStatus.pending,
          appliedDate: '2026-08-20',
          feedback: 'High-reliability audio console and visual stream specialist.',
        ),
        FreelancerApplication(
          id: 'app_004',
          eventId: 'e0000000-0000-0000-0000-000000000001',
          eventName: 'Indore Tech Leaders Summit 2026',
          freelancerId: 'f0000000-0000-0000-0000-000000000004',
          appliedRole: 'Event Operations',
          proposedRate: 1250,
          status: ApplicationStatus.pending,
          appliedDate: '2026-08-20',
          feedback: 'Stage and speaker coordinator travelling from Bhopal.',
        ),
        FreelancerApplication(
          id: 'app_005',
          eventId: 'e0000000-0000-0000-0000-000000000001',
          eventName: 'Indore Tech Leaders Summit 2026',
          freelancerId: 'f0000000-0000-0000-0000-000000000005',
          appliedRole: 'Event Operations',
          proposedRate: 1750,
          status: ApplicationStatus.pending,
          appliedDate: '2026-08-20',
          feedback: 'Top-tier 99% reliability score crowd and operations veteran from Dewas.',
        ),
        FreelancerApplication(
          id: 'app_006',
          eventId: 'e0000000-0000-0000-0000-000000000001',
          eventName: 'Indore Tech Leaders Summit 2026',
          freelancerId: 'f0000000-0000-0000-0000-000000000006',
          appliedRole: 'Registration Coordinator',
          proposedRate: 875,
          status: ApplicationStatus.pending,
          appliedDate: '2026-08-20',
          feedback: 'Closest proximity in Indore (3 km) offering budget-friendly registration support.',
        ),
      ];

  static List<AppNotification> get initialNotifications => [
        AppNotification(
          id: 'notif_001',
          userId: 'a0000000-0000-0000-0000-000000000001',
          title: 'New Shift Applications',
          message: '6 freelance specialists have applied for Indore Tech Leaders Summit 2026.',
          timestamp: 'Just now',
          type: NotificationType.candidateApplied,
          relatedEventId: 'e0000000-0000-0000-0000-000000000001',
        ),
        AppNotification(
          id: 'notif_002',
          userId: 'f0000000-0000-0000-0000-000000000001',
          title: 'Application Submitted',
          message: 'Your application for Indore Tech Leaders Summit 2026 is under review.',
          timestamp: '5 mins ago',
          type: NotificationType.applicationUpdate,
          relatedEventId: 'e0000000-0000-0000-0000-000000000001',
        ),
      ];
}
