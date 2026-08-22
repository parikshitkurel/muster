import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/application.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/freelancer_repository.dart';

class ApplicationStatusScreen extends ConsumerWidget {
  const ApplicationStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final freelancerState = ref.watch(freelancerProvider);

    final user = authState.currentUser;
    final apps = freelancerState.myApplications;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final confirmedApps = apps.where((a) => a.status == ApplicationStatus.selected).toList();

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Event Applications',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Track optimization review, shortlist outcomes, and confirmed shift dispatch passes.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              if (confirmedApps.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CONFIRMED DISPATCH PASS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Congratulations! You\'ve been selected for this event.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${confirmedApps.first.eventName} • Lead ${confirmedApps.first.appliedRole}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const Divider(color: Colors.white24, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shift Rate: ₹${confirmedApps.first.proposedRate}/hr (8 Hours Escrow Locked)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.successBg,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Shift Access QR Token downloaded to wallet.')),
                              );
                            },
                            icon: const Icon(LucideIcons.qrCode, size: 14),
                            label: const Text('View Dispatch QR Token'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('All Submitted Applications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),

              apps.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No applications submitted yet.')))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: apps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final app = apps[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(app.eventName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                        const SizedBox(height: 2),
                                        Text('Applied Role: ${app.appliedRole} • Submitted: ${app.appliedDate}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                      ],
                                    ),
                                    _StatusBadge(status: app.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurfaceSubtle,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Rate Proposal: ₹${app.proposedRate}/hr',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace', fontSize: 12),
                                      ),
                                      Text(
                                        app.feedback ?? 'Under algorithmic evaluation by organizer CP-SAT solver.',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ApplicationStatus status;

  const _StatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
