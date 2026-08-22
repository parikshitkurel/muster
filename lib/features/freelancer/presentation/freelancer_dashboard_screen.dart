import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/application.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/freelancer_repository.dart';

class FreelancerDashboardScreen extends ConsumerWidget {
  const FreelancerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final eventState = ref.watch(eventsProvider);
    final freelancerState = ref.watch(freelancerProvider);

    final user = authState.currentUser;
    final events = eventState.events;
    final applications = freelancerState.myApplications;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header (PDF Page 6)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.shieldCheck, size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            '${user.reliabilityScore}% RELIABILITY RATING',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.success,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back, ${user.fullName}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Specialization: ${user.primaryRole} • Verified Rate: ₹${user.expectedRate}/hr',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  onPressed: () => context.go('/freelancer/browse-events'),
                  icon: const Icon(LucideIcons.compass, size: 18),
                  label: const Text('Browse Available Events →'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Available Events Section (PDF Page 6)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Events in Your Radius',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        TextButton(
                          onPressed: () => context.go('/freelancer/browse-events'),
                          child: const Text('View All Matching Events →'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    events.isEmpty
                        ? const Center(child: Text('No active events in your area.'))
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: events.take(3).length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final evt = events[index];
                              final alreadyApplied =
                                  applications.any((a) => a.eventId == evt.id);

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.bgContainer,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(evt.type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(LucideIcons.mapPin, size: 11, color: AppColors.success),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${evt.proximityKm} km',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      evt.name,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${evt.date} • ${evt.venue}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Budget: ${CurrencyFormatter.format(evt.budget)}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'monospace', color: AppColors.primary),
                                        ),
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: () => context.go('/freelancer/event/${evt.id}'),
                                              child: const Text('Details'),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: alreadyApplied ? AppColors.bgContainer : AppColors.success,
                                                foregroundColor: alreadyApplied ? AppColors.textMuted : Colors.white,
                                              ),
                                              onPressed: alreadyApplied
                                                  ? null
                                                  : () {
                                                      final res = ref.read(freelancerProvider.notifier).applyToEvent(
                                                            evt.id,
                                                            evt.name,
                                                            user.id,
                                                            user.primaryRole,
                                                            user.expectedRate,
                                                          );
                                                      if (res) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Successfully applied to ${evt.name}!'),
                                                            backgroundColor: AppColors.success,
                                                          ),
                                                        );
                                                      }
                                                    },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (alreadyApplied) ...[
                                                    const Icon(LucideIcons.check, size: 14),
                                                    const SizedBox(width: 4),
                                                    const Text('Applied'),
                                                  ] else
                                                    const Text('Apply Now'),
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
                            },
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // My Applications Status Section (PDF Page 6 & 7)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Event Applications',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        TextButton(
                          onPressed: () => context.go('/freelancer/applications'),
                          child: const Text('View All Applications →'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    applications.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('You have not applied to any events yet.', style: TextStyle(color: AppColors.textMuted)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: applications.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final app = applications[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSurfaceSubtle,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(app.eventName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text('Role: ${app.appliedRole} • Submitted: ${app.appliedDate}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    _ApplicationStatusBadge(status: app.status),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationStatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const _ApplicationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case ApplicationStatus.pending:
        bg = AppColors.bgContainer;
        fg = AppColors.textMuted;
      case ApplicationStatus.shortlisted:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
      case ApplicationStatus.selected:
        bg = AppColors.successBg;
        fg = AppColors.success;
      case ApplicationStatus.rejected:
        bg = AppColors.dangerBg;
        fg = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
