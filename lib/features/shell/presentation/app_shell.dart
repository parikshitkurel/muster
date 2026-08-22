import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final notifState = ref.watch(notificationProvider);
    final user = authState.currentUser;
    final isOrganizer = user?.isOrganizer ?? true;

    if (user == null) {
      return child;
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (isDesktop) _buildSidebar(context, ref, user, isOrganizer, notifState.unreadCount),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(context, ref, user, isOrganizer, notifState.unreadCount),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : SafeArea(
              top: false,
              child: _buildMobileNavBar(context, isOrganizer, notifState.unreadCount),
            ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    bool isOrganizer,
    int unreadCount,
  ) {
    final String currentLoc = GoRouterState.of(context).uri.toString();

    final List<NavItem> navItems = isOrganizer
        ? [
            NavItem(title: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/organizer/dashboard'),
            NavItem(title: 'My Events', icon: LucideIcons.calendarDays, route: '/organizer/my-events'),
            NavItem(title: 'Create Event', icon: LucideIcons.calendarPlus, route: '/organizer/create-event'),
            NavItem(title: 'Applicants', icon: LucideIcons.users, route: '/organizer/applicants/evt_001'),
            NavItem(title: 'Crew', icon: LucideIcons.shieldCheck, route: '/organizer/final-crew/evt_001'),
            NavItem(title: 'Notifications', icon: LucideIcons.bell, route: '/notifications', badgeCount: unreadCount),
            NavItem(title: 'Profile', icon: LucideIcons.user, route: '/organizer/profile'),
            NavItem(title: 'Settings', icon: LucideIcons.settings, route: '/organizer/settings'),
          ]
        : [
            NavItem(title: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/freelancer/dashboard'),
            NavItem(title: 'Browse Events', icon: LucideIcons.compass, route: '/freelancer/browse-events'),
            NavItem(title: 'My Applications', icon: LucideIcons.fileCheck2, route: '/freelancer/applications'),
            NavItem(title: 'Notifications', icon: LucideIcons.bell, route: '/notifications', badgeCount: unreadCount),
            NavItem(title: 'Profile', icon: LucideIcons.user, route: '/freelancer/profile'),
            NavItem(title: 'Settings', icon: LucideIcons.settings, route: '/freelancer/settings'),
          ];

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/muster_logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MUSTER',
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'CREW OPTIMIZER',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: navItems.map((item) {
                final isSelected = currentLoc.startsWith(item.route);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => context.go(item.route),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.bgContainer : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected
                            ? Border.all(color: AppColors.border, width: 1)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 18,
                            color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.textMain : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          if (item.badgeCount != null && item.badgeCount! > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${item.badgeCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                final targetRole = isOrganizer ? UserRole.freelancer : UserRole.organizer;
                if (targetRole == UserRole.organizer) {
                  context.go('/organizer/dashboard');
                } else {
                  context.go('/freelancer/dashboard');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgSurfaceSubtle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOrganizer ? LucideIcons.wrench : LucideIcons.briefcase,
                      size: 16,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOrganizer ? 'Switch to Freelancer' : 'Switch to Organizer',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    bool isOrganizer,
    int unreadCount,
  ) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOrganizer ? AppColors.primaryDark : AppColors.successBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isOrganizer ? 'ORGANIZER WORKSPACE' : 'FREELANCER PORTAL',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => context.go('/notifications'),
                icon: Stack(
                  children: [
                    const Icon(LucideIcons.bell, size: 20, color: AppColors.textSecondary),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                color: AppColors.bgSurface,
                offset: const Offset(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (ResponsiveLayout.isDesktop(context)) ...[
                      const SizedBox(width: 8),
                      Text(
                        user.fullName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textMuted),
                  ],
                ),
                onSelected: (val) {
                  if (val == 'profile') {
                    context.go(isOrganizer ? '/organizer/profile' : '/freelancer/profile');
                  } else if (val == 'logout') {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(LucideIcons.user, size: 16),
                        SizedBox(width: 8),
                        Text('Profile', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(LucideIcons.logOut, size: 16, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Log Out', style: TextStyle(fontSize: 13, color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNavBar(BuildContext context, bool isOrganizer, int unreadCount) {
    final String currentLoc = GoRouterState.of(context).uri.toString();

    final List<NavItem> items = isOrganizer
        ? [
            NavItem(title: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/organizer/dashboard'),
            NavItem(title: 'Events', icon: LucideIcons.calendarDays, route: '/organizer/my-events'),
            NavItem(title: 'Create', icon: LucideIcons.calendarPlus, route: '/organizer/create-event'),
            NavItem(title: 'Alerts', icon: LucideIcons.bell, route: '/notifications', badgeCount: unreadCount),
            NavItem(title: 'Profile', icon: LucideIcons.user, route: '/organizer/profile'),
          ]
        : [
            NavItem(title: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/freelancer/dashboard'),
            NavItem(title: 'Browse', icon: LucideIcons.compass, route: '/freelancer/browse-events'),
            NavItem(title: 'Status', icon: LucideIcons.fileCheck2, route: '/freelancer/applications'),
            NavItem(title: 'Alerts', icon: LucideIcons.bell, route: '/notifications', badgeCount: unreadCount),
            NavItem(title: 'Profile', icon: LucideIcons.user, route: '/freelancer/profile'),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        currentIndex: items.indexWhere((it) => currentLoc.startsWith(it.route)).clamp(0, items.length - 1),
        onTap: (idx) => context.go(items[idx].route),
        items: items
            .map(
              (it) => BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(it.icon, size: 20),
                    if (it.badgeCount != null && it.badgeCount! > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${it.badgeCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
                label: it.title,
              ),
            )
            .toList(),
      ),
    );
  }
}

class NavItem {
  final String title;
  final IconData icon;
  final String route;
  final int? badgeCount;

  NavItem({
    required this.title,
    required this.icon,
    required this.route,
    this.badgeCount,
  });
}
