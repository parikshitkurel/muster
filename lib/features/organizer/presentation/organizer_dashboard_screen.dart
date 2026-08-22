import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../models/event.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/event_repository.dart';

class OrganizerDashboardScreen extends ConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final eventState = ref.watch(eventsProvider);
    final user = authState.currentUser;
    final allEvents = eventState.events;
    final isMobile = ResponsiveLayout.isMobile(context);

    final events = user != null
        ? allEvents.where((e) {
            return e.organizerId == user.id ||
                (user.id == '00000000-0000-0000-0000-000000000000' && (e.organizerId.isEmpty || e.organizerId == '00000000-0000-0000-0000-000000000000'));
          }).toList()
        : allEvents;

    // Loading state
    if (eventState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Error state
    if (eventState.error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                const SizedBox(height: 16),
                const Text('Unable to load your events.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Please try again.', style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(eventsProvider.notifier).fetchEventsFromSupabase(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    int totalBudget = events.fold(0, (sum, e) => sum + e.budget);
    int activePositions = events.fold(0, (sum, e) => sum + e.totalCrewNeeded);
    int totalApplicants = events.fold(0, (sum, e) => sum + e.applicantCount);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header — responsive
            if (isMobile) ...[
              Text(
                'Welcome back, ${user?.fullName ?? 'Organizer'}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                '${user?.companyName ?? ''} ${user?.organizerCity != null ? '• ${user!.organizerCity} Operations' : ''}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/organizer/create-event'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create New Event →'),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user?.fullName ?? 'Organizer'}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user?.companyName ?? ''} ${user?.organizerCity != null ? '• ${user!.organizerCity} Operations' : ''}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/organizer/create-event'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create New Event →'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Top Metric Cards — responsive grid
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = isMobile
                    ? (constraints.maxWidth - 12) / 2
                    : (constraints.maxWidth - 48) / 4;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: isMobile ? cardWidth : null,
                      child: isMobile
                          ? _MetricCard(title: 'ACTIVE EVENTS', value: '${events.length}', subtext: '${events.where((e) => e.status == EventStatus.published).length} Published', color: AppColors.primary, icon: Icons.event)
                          : Expanded(child: _MetricCard(title: 'ACTIVE EVENTS', value: '${events.length}', subtext: '${events.where((e) => e.status == EventStatus.published).length} Published', color: AppColors.primary, icon: Icons.event)),
                    ),
                    SizedBox(
                      width: isMobile ? cardWidth : null,
                      child: isMobile
                          ? _MetricCard(title: 'TOTAL APPLICANTS', value: '$totalApplicants', subtext: 'Across all events', color: AppColors.success, icon: Icons.group_outlined)
                          : Expanded(child: _MetricCard(title: 'TOTAL APPLICANTS', value: '$totalApplicants', subtext: 'Across all events', color: AppColors.success, icon: Icons.group_outlined)),
                    ),
                    SizedBox(
                      width: isMobile ? cardWidth : null,
                      child: isMobile
                          ? _MetricCard(title: 'CREW QUOTAS', value: '$activePositions', subtext: 'Roles open', color: AppColors.warning, icon: Icons.assignment_ind_outlined)
                          : Expanded(child: _MetricCard(title: 'CREW QUOTAS', value: '$activePositions', subtext: 'Roles open', color: AppColors.warning, icon: Icons.assignment_ind_outlined)),
                    ),
                    SizedBox(
                      width: isMobile ? cardWidth : null,
                      child: isMobile
                          ? _MetricCard(title: 'BUDGET', value: CurrencyFormatter.format(totalBudget), subtext: 'Total capital', color: AppColors.info, icon: Icons.account_balance_wallet_outlined)
                          : Expanded(child: _MetricCard(title: 'BUDGET', value: CurrencyFormatter.format(totalBudget), subtext: 'Total capital', color: AppColors.info, icon: Icons.account_balance_wallet_outlined)),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // Active Events Section
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Active Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.go('/organizer/my-events'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: const Text('View All Events →'),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Active Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  TextButton(onPressed: () => context.go('/organizer/my-events'), child: const Text('View All Events →')),
                ],
              ),
            const SizedBox(height: 12),

            events.isEmpty
                ? Card(
                    child: Padding(
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
                              child: const Center(child: Icon(Icons.event_busy_outlined, size: 28, color: AppColors.textMuted)),
                            ),
                            const SizedBox(height: 16),
                            const Text('No Events Created Yet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 6),
                            const Text(
                              'Create your first event to start receiving applications from freelancers.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/organizer/create-event'),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Create Event Now →'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final evt = events[index];
                      return _EventCard(evt: evt, isMobile: isMobile);
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

/// Responsive event card
class _EventCard extends StatelessWidget {
  final EventItem evt;
  final bool isMobile;

  const _EventCard({required this.evt, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Flexible(
                    child: Text(evt.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  _StatusBadge(status: evt.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${evt.date} • ${evt.venue} • ${evt.city}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Crew: ${evt.totalCrewNeeded} positions • ${evt.requirements.length} roles',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(evt.budget),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'monospace', color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/organizer/applicants/${evt.id}'),
                      child: Text('Applicants (${evt.applicantCount})', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/organizer/recommendation/${evt.id}'),
                      child: const Text('AI Optimizer →', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Desktop layout
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(child: Icon(Icons.event_seat_outlined, size: 22, color: AppColors.primaryLight)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(evt.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      _StatusBadge(status: evt.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${evt.date} • ${evt.venue} • ${evt.city}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crew Quota: ${evt.totalCrewNeeded} positions across ${evt.requirements.length} roles',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(evt.budget),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'monospace', color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => context.go('/organizer/applicants/${evt.id}'),
                      child: Text('View Applicants (${evt.applicantCount})'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.go('/organizer/recommendation/${evt.id}'),
                      child: const Text('AI Optimizer →'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted, fontFamily: 'monospace', letterSpacing: 0.8),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 4),
            Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final EventStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case EventStatus.draft:
        bg = AppColors.bgContainer;
        fg = AppColors.textMuted;
        label = 'DRAFT';
      case EventStatus.published:
        bg = AppColors.successBg;
        fg = AppColors.success;
        label = 'PUBLISHED';
      case EventStatus.optimized:
        bg = AppColors.primaryDark;
        fg = Colors.white;
        label = 'OPTIMIZED';
      case EventStatus.crewConfirmed:
        bg = AppColors.info;
        fg = Colors.white;
        label = 'CREW CONFIRMED';
      case EventStatus.inProgress:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        label = 'LIVE IN PROGRESS';
      case EventStatus.completed:
        bg = AppColors.bgContainer;
        fg = AppColors.textSecondary;
        label = 'COMPLETED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 9, fontWeight: FontWeight.w800, fontFamily: 'monospace', letterSpacing: 0.5)),
    );
  }
}
