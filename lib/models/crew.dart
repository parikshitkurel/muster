class CrewMember {
  final String freelancerId;
  final String fullName;
  final String role;
  final int matchScore;
  final int reliabilityScore;
  final int allocatedCost;
  final String rationale;
  final String phone;
  final String email;

  CrewMember({
    required this.freelancerId,
    required this.fullName,
    required this.role,
    required this.matchScore,
    required this.reliabilityScore,
    required this.allocatedCost,
    required this.rationale,
    this.phone = '+91 98765 43210',
    this.email = 'talent@muster.events',
  });

  CrewMember copyWith({
    String? freelancerId,
    String? fullName,
    String? role,
    int? matchScore,
    int? reliabilityScore,
    int? allocatedCost,
    String? rationale,
    String? phone,
    String? email,
  }) {
    return CrewMember(
      freelancerId: freelancerId ?? this.freelancerId,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      matchScore: matchScore ?? this.matchScore,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      allocatedCost: allocatedCost ?? this.allocatedCost,
      rationale: rationale ?? this.rationale,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  factory CrewMember.fromSupabase(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    return CrewMember(
      freelancerId: map['freelancer_id'] as String,
      fullName: profile['full_name'] as String? ?? 'Crew Member',
      role: map['role'] as String? ?? 'Specialist',
      matchScore: (map['match_score'] as num?)?.toInt() ?? 90,
      reliabilityScore: (map['reliability_score'] as num?)?.toInt() ?? 95,
      allocatedCost: (map['allocated_cost'] as num?)?.toInt() ?? 12000,
      rationale: map['rationale'] as String? ?? 'Selected by Optimization Engine',
      phone: profile['phone'] as String? ?? '+91 98765 43210',
      email: profile['email'] as String? ?? 'talent@muster.events',
    );
  }
}

class OptimizationResult {
  final String optionTitle;
  final String optionStrategy;
  final int overallMatchScore;
  final int totalCost;
  final int budgetRemaining;
  final double requirementCoverage;
  final bool isValidBudget;
  final List<CrewMember> recommendedCrew;

  OptimizationResult({
    required this.optionTitle,
    required this.optionStrategy,
    required this.overallMatchScore,
    required this.totalCost,
    required this.budgetRemaining,
    required this.requirementCoverage,
    required this.isValidBudget,
    required this.recommendedCrew,
  });

  OptimizationResult copyWith({
    String? optionTitle,
    String? optionStrategy,
    int? overallMatchScore,
    int? totalCost,
    int? budgetRemaining,
    double? requirementCoverage,
    bool? isValidBudget,
    List<CrewMember>? recommendedCrew,
  }) {
    return OptimizationResult(
      optionTitle: optionTitle ?? this.optionTitle,
      optionStrategy: optionStrategy ?? this.optionStrategy,
      overallMatchScore: overallMatchScore ?? this.overallMatchScore,
      totalCost: totalCost ?? this.totalCost,
      budgetRemaining: budgetRemaining ?? this.budgetRemaining,
      requirementCoverage: requirementCoverage ?? this.requirementCoverage,
      isValidBudget: isValidBudget ?? this.isValidBudget,
      recommendedCrew: recommendedCrew ?? this.recommendedCrew,
    );
  }
}

class CrewAllocation {
  final String id;
  final String eventId;
  final String eventName;
  final String crewType;
  final int totalMembers;
  final List<CrewMember> members;
  final int totalCost;
  final String confirmedDate;

  CrewAllocation({
    required this.id,
    required this.eventId,
    required this.eventName,
    this.crewType = 'Production Crew',
    required this.totalMembers,
    required this.members,
    required this.totalCost,
    required this.confirmedDate,
  });

  factory CrewAllocation.fromSupabase(Map<String, dynamic> map, {required String eventName, List<CrewMember>? membersList}) {
    return CrewAllocation(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      eventName: eventName,
      crewType: map['crew_type'] as String? ?? 'Production Crew',
      totalMembers: (map['total_members'] as num?)?.toInt() ?? (membersList?.length ?? 1),
      members: membersList ?? const [],
      totalCost: (map['total_cost'] as num?)?.toInt() ?? 0,
      confirmedDate: map['confirmed_date'] != null
          ? (map['confirmed_date'] as String).substring(0, 10)
          : DateTime.now().toString().substring(0, 10),
    );
  }
}
