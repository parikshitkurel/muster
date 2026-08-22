import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/supabase/supabase_config.dart';
import '../../../models/user.dart';
import '../../../data/repositories/auth_repository.dart';

class OrganizerProfileScreen extends ConsumerStatefulWidget {
  const OrganizerProfileScreen({super.key});

  @override
  ConsumerState<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends ConsumerState<OrganizerProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _companyCtrl = TextEditingController(text: user?.companyName ?? '');
    _cityCtrl = TextEditingController(text: user?.organizerCity ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
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
                email: supaUser.email ?? 'organizer@muster.events',
                fullName: 'Vikramaditya Roy',
                role: UserRole.organizer,
                companyName: 'Apex Event Production Pvt Ltd',
                organizerCity: 'Bengaluru',
                phone: '+91 98765 43210',
              )
            : AppUser(
                id: '00000000-0000-0000-0000-000000000001',
                email: 'organizer@muster.events',
                fullName: 'Vikramaditya Roy',
                role: UserRole.organizer,
                companyName: 'Apex Event Production Pvt Ltd',
                organizerCity: 'Bengaluru',
                phone: '+91 98765 43210',
              ));

    if (_nameCtrl.text.isEmpty && user.fullName.isNotEmpty) _nameCtrl.text = user.fullName;
    if (_companyCtrl.text.isEmpty && user.companyName.isNotEmpty) _companyCtrl.text = user.companyName;
    if (_cityCtrl.text.isEmpty && user.organizerCity.isNotEmpty) _cityCtrl.text = user.organizerCity;
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
                'Organizer Organization Profile',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Update your company credentials, primary dispatch city, and contact details.',
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
                              _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0] : 'O',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_companyCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                                Text('${_cityCtrl.text} Operations • Verified Organizer', style: const TextStyle(fontSize: 13, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 32),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Organizer Contact Name *'),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _companyCtrl,
                        decoration: const InputDecoration(labelText: 'Production House / Company Name *'),
                      ),
                      const SizedBox(height: 14),

                      Builder(
                        builder: (context) {
                          if (ResponsiveLayout.isMobile(context)) {
                            return Column(
                              children: [
                                TextFormField(
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(labelText: 'Operating City *'),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(labelText: 'Contact Phone *'),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(labelText: 'Operating City *'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(labelText: 'Contact Phone *'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _emailCtrl,
                        enabled: false,
                        decoration: const InputDecoration(labelText: 'Registered Account Email (Immutable)'),
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
                                    await ref.read(authProvider.notifier).updateOrganizerProfile(
                                          fullName: _nameCtrl.text,
                                          companyName: _companyCtrl.text,
                                          city: _cityCtrl.text,
                                          phone: _phoneCtrl.text,
                                        );
                                    if (!context.mounted) return;
                                    setState(() => _isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✨ Profile updated in Supabase database!'),
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
                              : const Text('Save Profile Changes'),
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
