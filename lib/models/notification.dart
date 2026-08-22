enum NotificationType { aiMatchReady, applicationUpdate, candidateApplied, systemAlert }

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String timestamp;
  final bool isRead;
  final NotificationType type;
  final String? relatedEventId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.relatedEventId,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      relatedEventId: relatedEventId,
    );
  }

  factory AppNotification.fromSupabase(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'system_alert';
    NotificationType type = NotificationType.systemAlert;
    if (typeStr == 'ai_match_ready') type = NotificationType.aiMatchReady;
    if (typeStr == 'application_update') type = NotificationType.applicationUpdate;
    if (typeStr == 'candidate_applied') type = NotificationType.candidateApplied;

    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: map['created_at'] != null ? (map['created_at'] as String).substring(11, 16) : 'Just now',
      isRead: map['is_read'] as bool? ?? false,
      type: type,
      relatedEventId: map['related_event_id'] as String?,
    );
  }
}
