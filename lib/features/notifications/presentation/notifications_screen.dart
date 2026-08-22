import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifState = ref.watch(notificationProvider);
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final allNotifs = notifState.notifications;

    final notifs = user != null
        ? allNotifs.where((n) => n.userId == user.id || n.userId.isEmpty).toList()
        : allNotifs;

    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                const Text('REAL-TIME AUDIT STREAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Text('Notifications', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Real-time alerts, AI matching outputs, and hiring updates', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(notificationProvider.notifier).markAllAsRead();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read.')));
                    },
                    icon: const Icon(LucideIcons.checkCheck, size: 14),
                    label: const Text('Mark All as Read'),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REAL-TIME AUDIT STREAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'monospace')),
                        const SizedBox(height: 4),
                        Text('Notifications', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        const Text('Real-time alerts, AI matching outputs, and hiring updates', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(notificationProvider.notifier).markAllAsRead();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All notifications marked as read.')));
                      },
                      icon: const Icon(LucideIcons.checkCheck, size: 14),
                      label: const Text('Mark All as Read'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              Card(
                child: notifs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Center(child: Icon(LucideIcons.bellOff, size: 28, color: AppColors.textMuted)),
                              ),
                              const SizedBox(height: 16),
                              const Text('No notifications yet.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text(
                                'New applications, crew updates\nand important event activity\nwill appear here.',
                                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: notifs.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.border),
                        itemBuilder: (context, index) {
                          final notif = notifs[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: notif.isRead ? AppColors.bgContainer : AppColors.primary,
                              child: Icon(
                                notif.isRead ? LucideIcons.bell : LucideIcons.sparkles,
                                size: 16,
                                color: notif.isRead ? AppColors.textMuted : Colors.white,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Text(
                                  notif.timestamp,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                notif.message,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                            onTap: () {
                              ref.read(notificationProvider.notifier).markAsRead(notif.id);
                              if (notif.relatedEventId != null) {
                                if (user?.role == UserRole.organizer) {
                                  context.go('/organizer/recommendation/${notif.relatedEventId}');
                                } else {
                                  context.go('/freelancer/applications');
                                }
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
