import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? 'Rohan Mehta');
    _roleCtrl = TextEditingController(text: user?.primaryRole ?? 'Sound Engineer');
    _rateCtrl = TextEditingController(text: '${user?.expectedRate ?? 1800}');
    _cityCtrl = TextEditingController(text: user?.freelancerCity ?? 'Bengaluru');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '+91 98765 43210');
    _emailCtrl = TextEditingController(text: user?.email ?? 'rohan.mehta@muster.events');
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
    final user = ref.watch(authProvider).currentUser;

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_nameCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              Text('${_roleCtrl.text} • Verified Talent', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.shieldCheck, size: 11, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      '96% RELIABILITY RATING',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 32),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name *'),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _roleCtrl,
                              decoration: const InputDecoration(labelText: 'Primary Specialization *'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _rateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Hourly Shift Rate (₹) *',
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(labelText: 'Base Operating City *'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(labelText: 'Phone Number *'),
                            ),
                          ),
                        ],
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
                        children: (user?.skills ?? ['Digital Audio', 'Rigging'])
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile saved successfully!'), backgroundColor: AppColors.success),
                            );
                          },
                          child: const Text('Save Profile Updates'),
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
