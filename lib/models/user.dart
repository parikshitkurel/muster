enum UserRole { organizer, freelancer }

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String? phone;
  final String companyName;
  final String organizerCity;
  final String primaryRole;
  final int expectedRate;
  final int experienceYears;
  final int reliabilityScore;
  final String freelancerCity;
  final List<String> skills;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.phone,
    this.companyName = 'Acme Events Pvt Ltd',
    this.organizerCity = 'Bengaluru',
    this.primaryRole = 'Sound Engineer',
    this.expectedRate = 1800,
    this.experienceYears = 4,
    this.reliabilityScore = 96,
    this.freelancerCity = 'Bengaluru',
    this.skills = const ['Digital Mixing Consoles', 'Dante Audio Protocol', 'Line Array Rigging'],
  });

  bool get isOrganizer => role == UserRole.organizer;
  bool get isFreelancer => role == UserRole.freelancer;

  factory AppUser.fromSupabase(Map<String, dynamic> map, {Map<String, dynamic>? roleMap, List<String>? skillsList}) {
    final roleStr = map['role'] as String? ?? 'organizer';
    final role = roleStr == 'freelancer' ? UserRole.freelancer : UserRole.organizer;

    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      role: role,
      avatarUrl: map['avatar_url'] as String?,
      phone: map['phone'] as String?,
      companyName: roleMap?['company_name'] as String? ?? 'Acme Events Pvt Ltd',
      organizerCity: roleMap?['city'] as String? ?? 'Bengaluru',
      primaryRole: roleMap?['primary_role'] as String? ?? 'Sound Engineer',
      expectedRate: roleMap?['hourly_rate'] != null ? (roleMap!['hourly_rate'] as num).toInt() : 1800,
      experienceYears: roleMap?['experience_years'] != null ? (roleMap!['experience_years'] as num).toInt() : 4,
      reliabilityScore: roleMap?['reliability_score'] != null ? (roleMap!['reliability_score'] as num).toInt() : 96,
      freelancerCity: roleMap?['city'] as String? ?? 'Bengaluru',
      skills: skillsList ?? const ['Digital Mixing Consoles', 'Dante Audio Protocol', 'Line Array Rigging'],
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': isOrganizer ? 'organizer' : 'freelancer',
      'avatar_url': avatarUrl,
      'phone': phone,
    };
  }
}
