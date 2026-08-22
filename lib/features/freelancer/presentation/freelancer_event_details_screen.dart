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

class FreelancerEventDetailsScreen extends ConsumerWidget {
  final String eventId;

  const FreelancerEventDetailsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final eventState = ref.watch(eventsProvider);
    final freelancerState = ref.watch(freelancerProvider);

    final user = authState.currentUser;
    final evt = eventState.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => eventState.events.first,
    );

    if (user == null) return const SizedBox.shrink();

    final myApp = freelancerState.myApplications.where((a) => a.eventId == evt.id).firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/freelancer/browse-events'),
                    child: const Text('Browse Events', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const Text(' / ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(evt.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.bgContainer, borderRadius: BorderRadius.circular(4)),
                          child: Text(evt.type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          evt.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${evt.venue}, ${evt.city}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),

                  if (myApp != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.bgContainer, foregroundColor: AppColors.textMuted),
                      onPressed: null,
                      icon: const Icon(LucideIcons.check, size: 14),
                      label: Text('Applied (${myApp.status.displayName})'),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () => _showApplyDialog(context, ref, evt, user),
                      icon: const Icon(LucideIcons.send, size: 16),
                      label: const Text('Apply to Event Now'),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _DetailStatCard(
                      label: 'Dates & Shift Timing',
                      value: evt.date,
                      subtext: '8-Hour Core Shift',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailStatCard(
                      label: 'Total Event Budget Pool',
                      value: CurrencyFormatter.format(evt.budget),
                      subtext: 'Verified Escrow Locked',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailStatCard(
                      label: 'Distance from Profile City',
                      value: '${evt.proximityKm} km',
                      subtext: 'Within Transit Radius',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Event Overview & Brief', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        evt.description,
                        style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                      ),
                      const Divider(color: AppColors.border, height: 32),

                      const Text('Role Quotas & Technical Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: evt.requirements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final req = evt.requirements[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceSubtle,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(req.role, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quota: ${req.quantity} positions • Min Experience: ${req.minExperienceYears} yrs',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Max Rate: ₹${req.maxRatePerHour}/hr',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace', fontSize: 13, color: AppColors.primary),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showApplyDialog(BuildContext context, WidgetRef ref, dynamic evt, dynamic user) {
    final rateCtrl = TextEditingController(text: '${user.expectedRate}');
    String selectedRole = evt.requirements.isNotEmpty ? evt.requirements.first.role : 'Sound Engineer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: Text('Apply to ${evt.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Role to Apply For:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: selectedRole,
              items: (evt.requirements as List)
                  .map((r) => DropdownMenuItem(value: r.role as String, child: Text(r.role as String)))
                  .toList(),
              onChanged: (v) => selectedRole = v!,
            ),
            const SizedBox(height: 14),
            const Text('Proposed Hourly Rate (₹):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rate = int.tryParse(rateCtrl.text) ?? user.expectedRate;
              ref.read(freelancerProvider.notifier).applyToEvent(
                    evt.id,
                    evt.name,
                    user.id,
                    selectedRole,
                    rate,
                  );
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Successfully applied to ${evt.name}!'), backgroundColor: AppColors.success),
              );
            },
            child: const Text('Confirm & Submit Application'),
          ),
        ],
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;

  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.subtext,
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
                Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                Icon(icon, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(subtext, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
