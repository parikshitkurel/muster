import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/crew.dart';
import '../../../data/repositories/event_repository.dart';

class FinalCrewScreen extends ConsumerWidget {
  final String eventId;

  const FinalCrewScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventState = ref.watch(eventsProvider);

    if (eventState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final evtMatches = eventState.events.where((e) => e.id == eventId);
    if (evtMatches.isEmpty && eventState.events.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text('No Event Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/organizer/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final evt = evtMatches.isNotEmpty ? evtMatches.first : eventState.events.first;
    final crew = evt.confirmedCrew;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/organizer/dashboard'),
                    child: const Text('Dashboard', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const Text(' / ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(evt.name, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Text(' / ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Text('Final Confirmed Crew', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),

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
                        child: const Text(
                          'CONFIRMED EVENT ROSTER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Final Crew Management',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${evt.name} • Confirmed & locked into live shift dispatch',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAssignVolunteerDialog(context, ref, evt),
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: const Text('Assign Volunteer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
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
                        const Text('Total Confirmed Staff', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text('${crew.length} Crew Members', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Allocated Cost', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(evt.totalCostAllocated > 0 ? evt.totalCostAllocated : evt.budget),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: AppColors.primary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Remaining Budget Buffer', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(evt.budget - (evt.totalCostAllocated > 0 ? evt.totalCostAllocated : evt.budget)),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: AppColors.success),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Roster Directory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  OutlinedButton.icon(
                    onPressed: () => _showAssignVolunteerDialog(context, ref, evt),
                    icon: const Icon(LucideIcons.userPlus, size: 14),
                    label: const Text('+ Assign Volunteer'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              crew.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No crew members approved yet. Run AI matching or select manually from applicant pool.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: crew.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final member = crew[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        member.fullName.split(' ').map((n) => n[0]).take(2).join(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(member.fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text('${member.role} • ${member.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.successBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '★ ${member.reliabilityScore}% RELIABILITY',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      CurrencyFormatter.format(member.allocatedCost),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace', fontSize: 15, color: AppColors.primary),
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
      ),
    );
  }

  void _showAssignVolunteerDialog(BuildContext context, WidgetRef ref, dynamic evt) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Event Volunteer');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Row(
          children: [
            Icon(LucideIcons.userPlus, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text('Assign Event Volunteer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the volunteer details below to add them to the confirmed event roster.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Volunteer Full Name *',
                  hintText: 'e.g. Rahul Sharma',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter volunteer name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  hintText: '+91 98765 43210',
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Assigned Role / Task',
                  hintText: 'e.g. Hospitality Lead, Registration Desk',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final name = nameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final role = roleCtrl.text.trim().isEmpty ? 'Event Volunteer' : roleCtrl.text.trim();

                final newVolunteer = CrewMember(
                  freelancerId: 'vol_${DateTime.now().millisecondsSinceEpoch}',
                  fullName: name,
                  role: role,
                  matchScore: 100,
                  reliabilityScore: 100,
                  allocatedCost: 0,
                  rationale: 'Directly assigned as Event Volunteer by Organizer',
                  phone: phone,
                  email: 'volunteer@muster.events',
                );

                Navigator.of(ctx).pop();
                await ref.read(eventsProvider.notifier).assignVolunteer(evt.id as String, newVolunteer);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✨ Volunteer $name assigned to ${evt.name}!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Assign Volunteer'),
          ),
        ],
      ),
    );
  }
}
