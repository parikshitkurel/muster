import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'organizer@muster.events');
  final _passwordCtrl = TextEditingController(text: 'password123');
  UserRole _selectedRole = UserRole.organizer;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _selectedRole,
          );

      if (!mounted) return;

      if (success) {
        if (_selectedRole == UserRole.organizer) {
          context.go('/organizer/dashboard');
        } else {
          context.go('/freelancer/dashboard');
        }
      } else {
        final err = ref.read(authProvider).error ?? 'Sign in failed. Please check credentials.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: AppColors.danger,
          ),
        );
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
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/muster_logo.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'M',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Center(
                        child: Text(
                          AppConstants.appTagline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Role Selector Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() {
                                  _selectedRole = UserRole.organizer;
                                  _emailCtrl.text = 'organizer@muster.events';
                                }),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == UserRole.organizer
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.briefcase,
                                        size: 14,
                                        color: _selectedRole == UserRole.organizer
                                            ? Colors.white
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Event Organizer',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedRole == UserRole.organizer
                                                ? Colors.white
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() {
                                  _selectedRole = UserRole.freelancer;
                                  _emailCtrl.text = 'rohan.mehta@muster.events';
                                }),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == UserRole.freelancer
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.wrench,
                                        size: 14,
                                        color: _selectedRole == UserRole.freelancer
                                            ? Colors.white
                                            : AppColors.textMuted,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Freelancer',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedRole == UserRole.freelancer
                                                ? Colors.white
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      const Text(
                        'Email Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          hintText: 'name@company.com',
                          prefixIcon: Icon(LucideIcons.mail, size: 16, color: AppColors.textMuted),
                        ),
                        validator: (val) =>
                            (val == null || !val.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      const Text(
                        'Password',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(LucideIcons.lock, size: 16, color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () =>
                                setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (val) =>
                            (val == null || val.length < 6) ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _handleLogin,
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Sign In →'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quick Demo Bypass Buttons
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurfaceSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HACKATHON TEST ACCOUNTS (PSE15)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                labelText: 'Select Test Account',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'org01', child: Text('Organizer 01: Arjun Mehta (Indore)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'org02', child: Text('Organizer 02: Riya Kapoor (Bhopal)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'free01', child: Text('Freelancer 01: Aarav Sharma (Sr Ops, Indore)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'free02', child: Text('Freelancer 02: Ishita Verma (Hospitality, Indore)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'free03', child: Text('Freelancer 03: Kabir Patel (Sr AV, Ujjain)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'free04', child: Text('Freelancer 04: Ananya Joshi (Stage Coord, Bhopal)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'free05', child: Text('Freelancer 05: Rohan Singh (Sr Security, Dewas)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                                DropdownMenuItem(value: 'free06', child: Text('Freelancer 06: Meera Shah (Jr Reg, Indore)', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11))),
                              ],
                              onChanged: (val) {
                                if (val == 'org01') {
                                  setState(() {
                                    _selectedRole = UserRole.organizer;
                                    _emailCtrl.text = 'organizer01@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                } else if (val == 'org02') {
                                  setState(() {
                                    _selectedRole = UserRole.organizer;
                                    _emailCtrl.text = 'organizer02@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                } else if (val == 'free01') {
                                  setState(() {
                                    _selectedRole = UserRole.freelancer;
                                    _emailCtrl.text = 'freelancer01@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                } else if (val == 'free02') {
                                  setState(() {
                                    _selectedRole = UserRole.freelancer;
                                    _emailCtrl.text = 'freelancer02@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                } else if (val == 'free03') {
                                  setState(() {
                                    _selectedRole = UserRole.freelancer;
                                    _emailCtrl.text = 'freelancer03@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                } else if (val == 'free04') {
                                  setState(() {
                                    _selectedRole = UserRole.freelancer;
                                    _emailCtrl.text = 'freelancer04@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                } else if (val == 'free05') {
                                  setState(() {
                                    _selectedRole = UserRole.freelancer;
                                    _emailCtrl.text = 'freelancer05@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                } else if (val == 'free06') {
                                  setState(() {
                                    _selectedRole = UserRole.freelancer;
                                    _emailCtrl.text = 'freelancer06@muster.test';
                                    _passwordCtrl.text = 'MusterTest@2026';
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign Up Links
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            InkWell(
                              onTap: () => context.go('/role-selection'),
                              child: const Text(
                                'Register Now',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
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
