enum ApplicationStatus { pending, shortlisted, selected, rejected }

extension ApplicationStatusExtension on ApplicationStatus {
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Under Review';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.selected:
        return 'Selected & Confirmed';
      case ApplicationStatus.rejected:
        return 'Not Selected';
    }
  }
}

class FreelancerApplication {
  final String id;
  final String eventId;
  final String eventName;
  final String freelancerId;
  final String appliedRole;
  final int proposedRate;
  final ApplicationStatus status;
  final String appliedDate;
  final String? feedback;

  FreelancerApplication({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.freelancerId,
    required this.appliedRole,
    required this.proposedRate,
    required this.status,
    required this.appliedDate,
    this.feedback,
  });

  factory FreelancerApplication.fromSupabase(Map<String, dynamic> map) {
    final statusStr = map['status'] as String? ?? 'pending';
    ApplicationStatus status = ApplicationStatus.pending;
    if (statusStr == 'shortlisted') status = ApplicationStatus.shortlisted;
    if (statusStr == 'selected') status = ApplicationStatus.selected;
    if (statusStr == 'rejected') status = ApplicationStatus.rejected;

    final event = map['events'] as Map<String, dynamic>? ?? {};

    return FreelancerApplication(
      id: map['id'] as String,
      eventId: map['event_id'] as String,
      eventName: event['name'] as String? ?? 'Event',
      freelancerId: map['freelancer_id'] as String,
      appliedRole: map['applied_role'] as String? ?? 'Event Crew',
      proposedRate: (map['proposed_rate'] as num?)?.toInt() ?? 1500,
      status: status,
      appliedDate: map['created_at'] != null
          ? (map['created_at'] as String).substring(0, 10)
          : '2026-08-20',
      feedback: map['feedback'] as String?,
    );
  }
}
