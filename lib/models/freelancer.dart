class FreelancerCandidate {
  final String id;
  final String name;
  final String role;
  final int expectedRate; // hourly INR
  final int matchScore; // percentage
  final int reliabilityScore; // percentage
  final double distanceKm;
  final int experienceYears;
  final List<String> skills;
  final String status;
  final String phone;
  final String email;

  FreelancerCandidate({
    required this.id,
    required this.name,
    required this.role,
    required this.expectedRate,
    required this.matchScore,
    required this.reliabilityScore,
    required this.distanceKm,
    required this.experienceYears,
    required this.skills,
    this.status = 'Applied',
    this.phone = '+91 98765 43210',
    this.email = 'talent@muster.events',
  });

  factory FreelancerCandidate.fromSupabase(Map<String, dynamic> map, {List<String>? skillsList}) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    return FreelancerCandidate(
      id: map['id'] as String,
      name: profile['full_name'] as String? ?? 'Freelancer',
      role: map['primary_role'] as String? ?? 'Event Crew',
      expectedRate: (map['hourly_rate'] as num?)?.toInt() ?? 1500,
      matchScore: (map['match_score'] as num?)?.toInt() ?? 88,
      reliabilityScore: (map['reliability_score'] as num?)?.toInt() ?? 92,
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 5.0,
      experienceYears: (map['experience_years'] as num?)?.toInt() ?? 3,
      skills: skillsList ?? const ['Event Operations', 'Rigging'],
      phone: profile['phone'] as String? ?? '+91 98765 43210',
      email: profile['email'] as String? ?? 'talent@muster.events',
    );
  }
}
