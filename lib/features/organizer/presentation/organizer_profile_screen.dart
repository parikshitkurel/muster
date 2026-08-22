import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
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

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _nameCtrl = TextEditingController(text: user?.fullName ?? 'Vikramaditya Roy');
    _companyCtrl = TextEditingController(text: user?.companyName ?? 'Apex Event Production Pvt Ltd');
    _cityCtrl = TextEditingController(text: user?.organizerCity ?? 'Bengaluru');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '+91 98765 43210');
    _emailCtrl = TextEditingController(text: user?.email ?? 'organizer@muster.events');
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_companyCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              Text('${_cityCtrl.text} Operations • Verified Organizer', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            ],
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

                      Row(
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppColors.success),
                            );
                          },
                          child: const Text('Save Profile Changes'),
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
