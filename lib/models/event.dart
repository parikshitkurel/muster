import 'crew.dart';

enum EventStatus { draft, published, optimized, crewConfirmed, inProgress, completed }

class EventRequirement {
  final String role;
  final int quantity;
  final int maxRatePerHour;
  final int minExperienceYears;
  final List<String> requiredSkills;

  EventRequirement({
    required this.role,
    required this.quantity,
    required this.maxRatePerHour,
    required this.minExperienceYears,
    required this.requiredSkills,
  });

  factory EventRequirement.fromSupabase(Map<String, dynamic> map, {List<String>? skills}) {
    return EventRequirement(
      role: map['role_name'] as String,
      quantity: (map['quantity'] as num).toInt(),
      maxRatePerHour: (map['max_rate_per_hour'] as num).toInt(),
      minExperienceYears: (map['min_experience_years'] as num).toInt(),
      requiredSkills: skills ?? const [],
    );
  }

  Map<String, dynamic> toSupabase(String eventId) {
    return {
      'event_id': eventId,
      'role_name': role,
      'quantity': quantity,
      'max_rate_per_hour': maxRatePerHour,
      'min_experience_years': minExperienceYears,
    };
  }
}

class EventItem {
  final String id;
  final String organizerId;
  final String name;
  final String type;
  final String date;
  final String venue;
  final String city;
  final int budget;
  final int proximityKm;
  final EventStatus status;
  final List<EventRequirement> requirements;
  final String description;
  final int applicantCount;
  final List<CrewMember> confirmedCrew;
  final int totalCostAllocated;

  EventItem({
    required this.id,
    required this.organizerId,
    required this.name,
    required this.type,
    required this.date,
    required this.venue,
    required this.city,
    required this.budget,
    required this.proximityKm,
    required this.status,
    required this.requirements,
    required this.description,
    this.applicantCount = 0,
    this.confirmedCrew = const [],
    this.totalCostAllocated = 0,
  });

  int get totalCrewNeeded =>
      requirements.fold(0, (sum, req) => sum + req.quantity);

  EventItem copyWith({
    String? id,
    String? organizerId,
    String? name,
    String? type,
    String? date,
    String? venue,
    String? city,
    int? budget,
    int? proximityKm,
    EventStatus? status,
    List<EventRequirement>? requirements,
    String? description,
    int? applicantCount,
    List<CrewMember>? confirmedCrew,
    int? totalCostAllocated,
  }) {
    return EventItem(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      budget: budget ?? this.budget,
      proximityKm: proximityKm ?? this.proximityKm,
      status: status ?? this.status,
      requirements: requirements ?? this.requirements,
      description: description ?? this.description,
      applicantCount: applicantCount ?? this.applicantCount,
      confirmedCrew: confirmedCrew ?? this.confirmedCrew,
      totalCostAllocated: totalCostAllocated ?? this.totalCostAllocated,
    );
  }

  factory EventItem.fromSupabase(Map<String, dynamic> map, {List<EventRequirement>? reqs, List<CrewMember>? crew}) {
    final statusStr = map['status'] as String? ?? 'published';
    EventStatus status = EventStatus.published;
    if (statusStr == 'draft') status = EventStatus.draft;
    if (statusStr == 'optimized') status = EventStatus.optimized;
    if (statusStr == 'crew_confirmed') status = EventStatus.crewConfirmed;
    if (statusStr == 'in_progress') status = EventStatus.inProgress;
    if (statusStr == 'completed') status = EventStatus.completed;

    return EventItem(
      id: map['id'] as String,
      organizerId: map['organizer_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'Conference',
      date: map['date'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      city: map['city'] as String? ?? 'Bengaluru',
      budget: (map['budget'] as num?)?.toInt() ?? 50000,
      proximityKm: (map['proximity_km'] as num?)?.toInt() ?? 25,
      status: status,
      requirements: reqs ?? const [],
      description: map['description'] as String? ?? '',
      applicantCount: (map['applicant_count'] as num?)?.toInt() ?? 0,
      confirmedCrew: crew ?? const [],
      totalCostAllocated: (map['total_cost_allocated'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toSupabase() {
    String statusStr = 'published';
    if (status == EventStatus.draft) statusStr = 'draft';
    if (status == EventStatus.optimized) statusStr = 'optimized';
    if (status == EventStatus.crewConfirmed) statusStr = 'crew_confirmed';
    if (status == EventStatus.inProgress) statusStr = 'in_progress';
    if (status == EventStatus.completed) statusStr = 'completed';

    final payload = <String, dynamic>{
      'organizer_id': organizerId,
      'name': name,
      'type': type,
      'date': date,
      'venue': venue,
      'city': city,
      'budget': budget,
      'proximity_km': proximityKm,
      'status': statusStr,
      'description': description,
    };

    if (id.length == 36 && id.contains('-')) {
      payload['id'] = id;
    }

    return payload;
  }
}
