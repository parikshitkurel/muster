import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class FreelancerSettingsScreen extends StatefulWidget {
  const FreelancerSettingsScreen({super.key});

  @override
  State<FreelancerSettingsScreen> createState() => _FreelancerSettingsScreenState();
}

class _FreelancerSettingsScreenState extends State<FreelancerSettingsScreen> {
  bool _proximityAlerts = true;

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
                'Freelancer Preferences',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Configure job matching notifications and dispatch alert preferences.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dispatch Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const Divider(color: AppColors.border, height: 24),
                      SwitchListTile(
                        title: const Text('Proximity Event Alerts', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Push alerts when new events within 25km are published', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        value: _proximityAlerts,
                        activeThumbColor: AppColors.primary,
                        onChanged: (v) => setState(() => _proximityAlerts = v),
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
