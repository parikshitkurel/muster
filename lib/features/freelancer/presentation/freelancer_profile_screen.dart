import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../models/user.dart';
import '../../../data/repositories/auth_repository.dart';

class FreelancerProfileScreen extends ConsumerStatefulWidget {
  const FreelancerProfileScreen({super.key});

  @override
  ConsumerState<FreelancerProfileScreen> createState() => _FreelancerProfileScreenState();
}

class _FreelancerProfileScreenState extends ConsumerState<FreelancerProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _roleCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _roleCtrl = TextEditingController(text: user?.primaryRole ?? '');
    _rateCtrl = TextEditingController(text: '${user?.expectedRate ?? 0}');
    _cityCtrl = TextEditingController(text: user?.freelancerCity ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _rateCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final supaUser = SupabaseConfig.client?.auth.currentUser;
    final user = authState.currentUser ??
        (supaUser != null
            ? AppUser(
                id: supaUser.id,
                email: supaUser.email ?? 'rohan.mehta@muster.events',
                fullName: 'Rohan Mehta',
                role: UserRole.freelancer,
                primaryRole: 'Sound Engineer',
                expectedRate: 1800,
                freelancerCity: 'Bengaluru',
                phone: '+91 98765 43210',
              )
            : AppUser(
                id: '00000000-0000-0000-0000-000000000002',
                email: 'rohan.mehta@muster.events',
                fullName: 'Rohan Mehta',
                role: UserRole.freelancer,
                primaryRole: 'Sound Engineer',
                expectedRate: 1800,
                freelancerCity: 'Bengaluru',
                phone: '+91 98765 43210',
              ));

    if (_nameCtrl.text.isEmpty && user.fullName.isNotEmpty) _nameCtrl.text = user.fullName;
    if (_roleCtrl.text.isEmpty && user.primaryRole.isNotEmpty) _roleCtrl.text = user.primaryRole;
    if ((_rateCtrl.text.isEmpty || _rateCtrl.text == '0') && user.expectedRate > 0) _rateCtrl.text = '${user.expectedRate}';
    if (_cityCtrl.text.isEmpty && user.freelancerCity.isNotEmpty) _cityCtrl.text = user.freelancerCity;
    if (_phoneCtrl.text.isEmpty && (user.phone?.isNotEmpty ?? false)) _phoneCtrl.text = user.phone!;
    if (_emailCtrl.text.isEmpty && user.email.isNotEmpty) _emailCtrl.text = user.email;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Freelancer Talent Profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage verified specialization rates, dispatch radius, and contact parameters.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : 'F',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_nameCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                                Text('${_roleCtrl.text} • Verified Talent', style: const TextStyle(fontSize: 13, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(4)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.shieldCheck, size: 11, color: AppColors.success),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${user.reliabilityScore}% RELIABILITY RATING',
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.success, fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 32),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name *'),
                      ),
                      const SizedBox(height: 14),

                      Builder(
                        builder: (context) {
                          final mobile = ResponsiveLayout.isMobile(context);
                          if (mobile) {
                            return Column(
                              children: [
                                TextFormField(controller: _roleCtrl, decoration: const InputDecoration(labelText: 'Primary Specialization *')),
                                const SizedBox(height: 14),
                                TextFormField(controller: _rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hourly Shift Rate (₹) *', prefixText: '₹ ')),
                                const SizedBox(height: 14),
                                TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'Base Operating City *')),
                                const SizedBox(height: 14),
                                TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number *')),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: TextFormField(controller: _roleCtrl, decoration: const InputDecoration(labelText: 'Primary Specialization *'))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: _rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hourly Shift Rate (₹) *', prefixText: '₹ '))),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(child: TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'Base Operating City *'))),
                                  const SizedBox(width: 12),
                                  Expanded(child: TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number *'))),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _emailCtrl,
                        enabled: false,
                        decoration: const InputDecoration(labelText: 'Account Email (Immutable)'),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Verified Technical Skills & Certifications',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                      children: user.skills
                          .map(
                              (s) => Chip(
                                label: Text(s, style: const TextStyle(fontSize: 11)),
                                backgroundColor: AppColors.bgSurfaceSubtle,
                                side: const BorderSide(color: AppColors.border),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  setState(() => _isSaving = true);
                                  try {
                                    final rate = int.tryParse(_rateCtrl.text) ?? 1500;
                                    await ref.read(authProvider.notifier).updateFreelancerProfile(
                                          fullName: _nameCtrl.text,
                                          primaryRole: _roleCtrl.text,
                                          hourlyRate: rate,
                                          city: _cityCtrl.text,
                                          phone: _phoneCtrl.text,
                                          skills: user.skills,
                                        );
                                    if (!context.mounted) return;
                                    setState(() => _isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✨ Freelancer profile updated in Supabase database!'),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    setState(() => _isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error saving profile: $e'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                  }
                                },
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Save Profile Updates'),
                        ),
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
}
