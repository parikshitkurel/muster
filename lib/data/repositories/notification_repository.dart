import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification.dart';
import '../../core/supabase/supabase_config.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  RealtimeChannel? _realtimeChannel;

  NotificationNotifier()
      : super(NotificationState(notifications: const [], isLoading: true)) {
    fetchNotificationsFromSupabase();
    _subscribeToNotifications();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToNotifications() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      _realtimeChannel = client
          .channel('public:notifications')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              fetchNotificationsFromSupabase();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('[Realtime] Notifications subscription notice: $e');
    }
  }

  Future<void> fetchNotificationsFromSupabase({String? userId}) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      state = state.copyWith(notifications: const [], isLoading: false);
      return;
    }

    final targetUserId = userId ?? client.auth.currentUser?.id;
    if (targetUserId == null || targetUserId.isEmpty) {
      state = state.copyWith(notifications: const [], isLoading: false);
      return;
    }

    try {
      final notifsRes = await client
          .from('notifications')
          .select()
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);

      final list = (notifsRes as List)
          .map((n) => AppNotification.fromSupabase(n))
          .toList();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      debugPrint('[Supabase] Notifications fetch error: $e');
      state = state.copyWith(notifications: const [], isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        debugPrint('[Supabase WRITE] Marking notification $id as read...');
        await client.from('notifications').update({'is_read': true}).eq('id', id);
        debugPrint('[Supabase WRITE SUCCESS] Notification marked as read in database.');
      } catch (e) {
        debugPrint('[Supabase WRITE FAILED] Notification update error: $e');
      }
    }

    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  Future<void> markAllAsRead() async {
    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        debugPrint('[Supabase WRITE] Marking all notifications as read...');
        await client.from('notifications').update({'is_read': true}).neq('is_read', true);
        debugPrint('[Supabase WRITE SUCCESS] All notifications marked as read in database.');
      } catch (e) {
        debugPrint('[Supabase WRITE FAILED] Mark all notifications error: $e');
      }
    }

    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);
  }

  void addNotification(AppNotification notif) {
    state = state.copyWith(notifications: [notif, ...state.notifications]);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
