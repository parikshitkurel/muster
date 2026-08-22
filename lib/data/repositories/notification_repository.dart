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

  Future<void> fetchNotificationsFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) {
      state = state.copyWith(notifications: const [], isLoading: false);
      return;
    }

    try {
      final notifsRes = await client
          .from('notifications')
          .select()
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

  void markAsRead(String id) {
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        client.from('notifications').update({'is_read': true}).eq('id', id);
      } catch (_) {}
    }
  }

  void markAllAsRead() {
    final updated = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    state = state.copyWith(notifications: updated);

    final client = SupabaseConfig.client;
    if (client != null) {
      try {
        client.from('notifications').update({'is_read': true}).neq('is_read', true);
      } catch (_) {}
    }
  }

  void addNotification(AppNotification notif) {
    state = state.copyWith(notifications: [notif, ...state.notifications]);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
