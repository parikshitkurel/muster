import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
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
    final events = eventState.events;

    int totalBudget = events.fold(0, (sum, e) => sum + e.budget);
    int activePositions = events.fold(0, (sum, e) => sum + e.totalCrewNeeded);
    int totalApplicants = events.fold(0, (sum, e) => sum + e.applicantCount);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header (PDF Page 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user?.fullName ?? 'Organizer'}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user?.companyName ?? 'Acme Production'} • Bengaluru Operations',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/organizer/create-event'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create New Event →'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Metric Cards (PDF Page 2)
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'ACTIVE EVENTS',
                    value: '${events.length}',
                    subtext: '${events.where((e) => e.status == EventStatus.published).length} Published',
                    color: AppColors.primary,
                    icon: Icons.event,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'TOTAL APPLICANTS',
                    value: '$totalApplicants',
                    subtext: 'Across all active events',
                    color: AppColors.success,
                    icon: Icons.group_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'ACTIVE CREW QUOTAS',
                    value: '$activePositions',
                    subtext: 'Specialist roles open',
                    color: AppColors.warning,
                    icon: Icons.assignment_ind_outlined,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'COMBINED BUDGET',
                    value: CurrencyFormatter.format(totalBudget),
                    subtext: 'Total event capital',
                    color: AppColors.info,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Active Events Section (PDF Page 2)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Active Events',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                TextButton(
                  onPressed: () => context.go('/organizer/my-events'),
                  child: const Text('View All Events →'),
                ),
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
                              child: const Center(
                                child: Icon(Icons.event_busy_outlined, size: 28, color: AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Events Created Yet',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create your first event brief in Supabase or using the button below to start receiving applications.',
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
                                child: const Center(
                                  child: Icon(Icons.event_seat_outlined, size: 22, color: AppColors.primaryLight),
                                ),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          evt.name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                        ),
                                        const SizedBox(width: 8),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                      color: AppColors.primary,
                                    ),
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
                    },
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                    letterSpacing: 0.8,
                  ),
                ),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
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
        fg = Colors.black;
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
