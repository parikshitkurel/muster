import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class OrganizerSettingsScreen extends StatefulWidget {
  const OrganizerSettingsScreen({super.key});

  @override
  State<OrganizerSettingsScreen> createState() => _OrganizerSettingsScreenState();
}

class _OrganizerSettingsScreenState extends State<OrganizerSettingsScreen> {
  bool _emailAlerts = true;

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
                'Settings & Preferences',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure notifications, CP-SAT solver automation, and account security.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const Divider(color: AppColors.border, height: 24),
                      SwitchListTile(
                        title: const Text('Email Alerts on New Applications', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Receive digest emails when verified specialists apply', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        value: _emailAlerts,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _emailAlerts = v),
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
