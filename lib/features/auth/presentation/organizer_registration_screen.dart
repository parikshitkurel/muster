import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/auth_repository.dart';

class OrganizerRegistrationScreen extends ConsumerStatefulWidget {
  const OrganizerRegistrationScreen({super.key});

  @override
  ConsumerState<OrganizerRegistrationScreen> createState() =>
      _OrganizerRegistrationScreenState();
}

class _OrganizerRegistrationScreenState
    extends ConsumerState<OrganizerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Vikramaditya Roy');
  final _companyCtrl = TextEditingController(text: 'Apex Event Production Pvt Ltd');
  final _emailCtrl = TextEditingController(text: 'organizer@muster.events');
  final _phoneCtrl = TextEditingController(text: '+91 98765 43210');
  final _cityCtrl = TextEditingController(text: 'Bengaluru');
  final _passwordCtrl = TextEditingController(text: 'password123');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).signUpOrganizer(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _nameCtrl.text.trim(),
            companyName: _companyCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
          );

      if (success && mounted) {
        context.go('/organizer/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Organizer Registration',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Set up your event production organization and hiring preferences.',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name *'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _companyCtrl,
                        decoration: const InputDecoration(labelText: 'Organization / Agency Name *'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Work Email *'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              decoration: const InputDecoration(labelText: 'Phone Number *'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(labelText: 'Primary City *'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password *'),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                      ),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleRegister,
                          child: authState.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Complete Registration & Enter Dashboard →'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
