import '../../models/user.dart';
import '../../models/event.dart';
import '../../models/freelancer.dart';
import '../../models/application.dart';
import '../../models/notification.dart';

class MockData {
  static final AppUser organizerUser = AppUser(
    id: 'org_001',
    email: 'organizer@muster.events',
    fullName: 'Vikramaditya Roy',
    role: UserRole.organizer,
    companyName: 'Apex Event Production Pvt Ltd',
    organizerCity: 'Bengaluru',
  );

  static final AppUser freelancerUser = AppUser(
    id: 'free_001',
    email: 'rohan.mehta@muster.events',
    fullName: 'Rohan Mehta',
    role: UserRole.freelancer,
    primaryRole: 'Sound Engineer',
    expectedRate: 1800,
    experienceYears: 5,
    reliabilityScore: 98,
    freelancerCity: 'Bengaluru',
    skills: const ['Digital Mixing Consoles', 'Dante Audio Protocol', 'Line Array Rigging', 'FOH Management'],
  );

  static List<EventItem> get initialEvents => [
        EventItem(
          id: 'evt_001',
          organizerId: 'org_001',
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
        EventItem(
          id: 'evt_002',
          organizerId: 'org_001',
          name: 'Sunburn Arena Bangalore',
          type: 'Concert',
          date: '2026-10-02',
          venue: 'Manpho Convention Centre',
          city: 'Bengaluru',
          budget: 280000,
          proximityKm: 30,
          status: EventStatus.published,
          applicantCount: 24,
          description:
              'Massive electronic music festival tour stop. Requires heavy audio engineers, lasers technicians, and safety crew.',
          requirements: [
            EventRequirement(
              role: 'Sound Engineer',
              quantity: 3,
              maxRatePerHour: 2500,
              minExperienceYears: 4,
              requiredSkills: ['Line Array Rigging', 'Subwoofer Array Tuning'],
            ),
            EventRequirement(
              role: 'Lighting Specialist',
              quantity: 3,
              maxRatePerHour: 2400,
              minExperienceYears: 4,
              requiredSkills: ['Laser Safety Certification', 'Avolites Titan'],
            ),
          ],
        ),
        EventItem(
          id: 'evt_003',
          organizerId: 'org_001',
          name: 'Global Fintech Summit 2026',
          type: 'Corporate Summit',
          date: '2026-11-10',
          venue: 'Jio World Convention Centre, Mumbai',
          city: 'Mumbai',
          budget: 350000,
          proximityKm: 20,
          status: EventStatus.draft,
          applicantCount: 0,
          description:
              'High-level corporate fintech summit hosting global central bankers and founders.',
          requirements: [
            EventRequirement(
              role: 'Live Stream Operator',
              quantity: 2,
              maxRatePerHour: 2000,
              minExperienceYears: 3,
              requiredSkills: ['vMix Multi-cam', 'NDI Protocol'],
            ),
          ],
        ),
      ];

  static List<FreelancerCandidate> get allCandidates => [
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
        FreelancerCandidate(
          id: 'free_004',
          name: 'Pooja Hegde',
          role: 'Stage Coordinator',
          expectedRate: 1150,
          matchScore: 92,
          reliabilityScore: 94,
          distanceKm: 8.1,
          experienceYears: 3,
          skills: ['Speaker Management', 'Backstage Protocol', 'Run of Show Scheduling'],
        ),
        FreelancerCandidate(
          id: 'free_005',
          name: 'Arjun Deshmukh',
          role: 'Sound Engineer',
          expectedRate: 1900,
          matchScore: 93,
          reliabilityScore: 95,
          distanceKm: 5.0,
          experienceYears: 4,
          skills: ['Digital Mixing Consoles', 'Dante Audio Protocol', 'IEM Wireless Systems'],
        ),
        FreelancerCandidate(
          id: 'free_006',
          name: 'Aditi Nair',
          role: 'Lighting Specialist',
          expectedRate: 1750,
          matchScore: 91,
          reliabilityScore: 93,
          distanceKm: 9.4,
          experienceYears: 4,
          skills: ['DMX Programming', 'GrandMA3 Console', 'Stage Wash Alignment'],
        ),
        FreelancerCandidate(
          id: 'free_007',
          name: 'Siddharth Pillai',
          role: 'Stage Coordinator',
          expectedRate: 1050,
          matchScore: 89,
          reliabilityScore: 91,
          distanceKm: 12.0,
          experienceYears: 2,
          skills: ['Speaker Management', 'Timecue Cueing'],
        ),
      ];

  static List<FreelancerApplication> get initialApplications => [
        FreelancerApplication(
          id: 'app_001',
          eventId: 'evt_001',
          eventName: 'TechSparks 2026',
          freelancerId: 'free_001',
          appliedRole: 'Sound Engineer',
          proposedRate: 1800,
          status: ApplicationStatus.selected,
          appliedDate: '2026-08-18',
          feedback: 'Optimal algorithmic fit selected for FOH main stage audio dispatch.',
        ),
      ];

  static List<AppNotification> get initialNotifications => [
        AppNotification(
          id: 'notif_001',
          userId: 'org_001',
          title: 'Optimization Engine Completed',
          message: 'AI crew solver generated 3 Pareto-optimal allocations for TechSparks 2026.',
          timestamp: '10 mins ago',
          type: NotificationType.aiMatchReady,
          relatedEventId: 'evt_001',
        ),
        AppNotification(
          id: 'notif_002',
          userId: 'free_001',
          title: 'Crew Selection Confirmed',
          message: 'Congratulations! You have been selected for TechSparks 2026 as Lead Sound Engineer.',
          timestamp: '15 mins ago',
          type: NotificationType.applicationUpdate,
          relatedEventId: 'evt_001',
        ),
      ];
}
