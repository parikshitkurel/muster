import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/gemini_service.dart';
import '../../../models/event.dart';
import '../../../data/repositories/event_repository.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  int _currentStep = 1;

  final _nameCtrl = TextEditingController(text: 'MIT India Hackathon Showcase 2026');
  final _venueCtrl = TextEditingController(text: 'Convention Centre, Bengaluru');
  final _dateCtrl = TextEditingController(text: '2026-09-25');
  final _cityCtrl = TextEditingController(text: 'Bengaluru');
  final _descCtrl = TextEditingController(
    text: 'Grand finale demo event requiring multi-stage AV audio engineers and stage crew.',
  );
  String _eventType = 'Conference';

  final List<EventRequirement> _requirements = [
    EventRequirement(
      role: 'Sound Engineer',
      quantity: 2,
      maxRatePerHour: 2000,
      minExperienceYears: 3,
      requiredSkills: ['Dante Audio Protocol', 'Digital Mixing Consoles'],
    ),
    EventRequirement(
      role: 'Lighting Specialist',
      quantity: 1,
      maxRatePerHour: 1800,
      minExperienceYears: 2,
      requiredSkills: ['DMX Programming', 'GrandMA3 Console'],
    ),
    EventRequirement(
      role: 'Stage Coordinator',
      quantity: 2,
      maxRatePerHour: 1100,
      minExperienceYears: 2,
      requiredSkills: ['Speaker Management', 'Run of Show Scheduling'],
    ),
  ];

  final _budgetCtrl = TextEditingController(text: '120000');
  int _proximityKm = 25;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _venueCtrl.dispose();
    _dateCtrl.dispose();
    _cityCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _publishEvent() {
    final budget = int.tryParse(_budgetCtrl.text) ?? 100000;
    final newEvent = EventItem(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      organizerId: 'org_001',
      name: _nameCtrl.text.trim(),
      type: _eventType,
      date: _dateCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      budget: budget,
      proximityKm: _proximityKm,
      status: EventStatus.published,
      applicantCount: 12,
      requirements: _requirements,
      description: _descCtrl.text.trim(),
    );

    ref.read(eventsProvider.notifier).addEvent(newEvent);
    context.go('/organizer/applicants/${newEvent.id}');
  }

  void _showNlpPromptDialog() {
    final promptCtrl = TextEditingController(
      text: 'Need 2 Sound Engineers and 1 Lighting Specialist for a 2-day conference in Bengaluru with a budget of ₹1,40,000.',
    );
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgSurface,
          title: const Row(
            children: [
              Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Gemini NLP Event Brief Assistant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter natural language description of your event requirements. Gemini will extract structured quotas, rate caps, and budget limits.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: promptCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. Need 2 audio technicians and 1 stage manager in Mumbai under 2 lakhs...',
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Gemini parsing structured requirements...', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setDlgState(() => isLoading = true);
                      final parsed = await GeminiService.parseRequirements(promptCtrl.text);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (!mounted) return;
                      if (parsed != null) {
                        setState(() {
                          if (parsed['suggested_name'] != null) _nameCtrl.text = parsed['suggested_name'];
                          if (parsed['suggested_city'] != null) _cityCtrl.text = parsed['suggested_city'];
                          if (parsed['estimated_budget'] != null) {
                            _budgetCtrl.text = parsed['estimated_budget'].toString();
                          }
                          final roles = parsed['roles'] as List?;
                          if (roles != null && roles.isNotEmpty) {
                            _requirements.clear();
                            for (var r in roles) {
                              _requirements.add(
                                EventRequirement(
                                  role: r['role_name'] ?? 'Event Crew',
                                  quantity: r['quantity'] ?? 1,
                                  maxRatePerHour: r['max_rate_per_hour'] ?? 1500,
                                  minExperienceYears: r['min_experience_years'] ?? 2,
                                  requiredSkills: ['Event Operations'],
                                ),
                              );
                            }
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✨ Requirements extracted by Gemini AI!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Notice: Using default structured parameters.')),
                        );
                      }
                    },
              child: const Text('Extract & Fill'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
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
                  const Text('Create Event Wizard', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Create New Event',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Define event requirements, role quotas, rate ceilings, and optimization constraints.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              _buildStepIndicator(),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildCurrentStepContent(),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 1)
                    OutlinedButton(
                      onPressed: () => setState(() => _currentStep--),
                      child: const Text('← Previous Step'),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_currentStep < 5)
                    ElevatedButton(
                      onPressed: () => setState(() => _currentStep++),
                      child: const Text('Next Step →'),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: _publishEvent,
                      icon: const Icon(LucideIcons.send, size: 16),
                      label: const Text('Publish Event & Open Candidate Pool'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      'Basic Details',
      'Role Requirements',
      'Budget & Radius',
      'Matching Weights',
      'Review & Publish',
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final stepNum = index + 1;
        final isPassed = stepNum < _currentStep;
        final isCurrent = stepNum == _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: isCurrent
                              ? AppColors.primary
                              : (isPassed ? AppColors.success : AppColors.bgContainer),
                          child: Text(
                            '$stepNum',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: (isCurrent || isPassed) ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            steps[index],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                              color: isCurrent ? AppColors.textMain : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 2,
                      color: isPassed
                          ? AppColors.success
                          : (isCurrent ? AppColors.primary : AppColors.border),
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1BasicDetails();
      case 2:
        return _buildStep2Requirements();
      case 3:
        return _buildStep3Budget();
      case 4:
        return _buildStep4MatchingPreferences();
      case 5:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primaryLight),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Gemini NLP Assist: Type natural requirements or brief to auto-extract role quotas and budget parameters.',
                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () => _showNlpPromptDialog(),
                child: const Text('Use AI Brief Assist', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Event Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Event Name *'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _eventType,
                decoration: const InputDecoration(labelText: 'Event Category *'),
                items: ['Conference', 'Concert', 'Corporate Summit', 'Exhibition', 'Wedding']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dateCtrl,
                decoration: const InputDecoration(labelText: 'Event Date (YYYY-MM-DD) *'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _venueCtrl,
                decoration: const InputDecoration(labelText: 'Venue / Facility *'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'City *'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Event Description & Special Brief *'),
        ),
      ],
    );
  }

  Widget _buildStep2Requirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Crew Roles & Quotas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _requirements.add(
                    EventRequirement(
                      role: 'Production Crew',
                      quantity: 1,
                      maxRatePerHour: 1500,
                      minExperienceYears: 2,
                      requiredSkills: ['Event Ops'],
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Role Quota'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _requirements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final req = _requirements[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(req.role, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                  Expanded(
                    child: Text('Qty: ${req.quantity}', style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    child: Text('Cap: ₹${req.maxRatePerHour}/hr', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                    onPressed: () {
                      setState(() {
                        _requirements.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep3Budget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Budget Ceiling & Geospatial Constraints', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Total Event Crew Budget (₹) *',
            prefixText: '₹ ',
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Maximum Candidate Proximity Radius:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$_proximityKm km', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: _proximityKm.toDouble(),
          min: 5,
          max: 100,
          divisions: 19,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _proximityKm = v.round()),
        ),
      ],
    );
  }

  Widget _buildStep4MatchingPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Optimization Objective Priorities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Tune the CP-SAT solver cost function weights for candidate selection.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        _buildWeightSlider('Skill & Experience Match Weight', 0.40),
        const SizedBox(height: 14),
        _buildWeightSlider('Reliability Score & Past Attendance', 0.35),
        const SizedBox(height: 14),
        _buildWeightSlider('Proximity & Travel Distance', 0.15),
        const SizedBox(height: 14),
        _buildWeightSlider('Hourly Rate Budget Efficiency', 0.10),
      ],
    );
  }

  Widget _buildWeightSlider(String label, double defaultVal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${(defaultVal * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: defaultVal,
          min: 0,
          max: 1,
          activeColor: AppColors.primary,
          onChanged: (_) {},
        ),
      ],
    );
  }

  Widget _buildStep5Review() {
    final budget = int.tryParse(_budgetCtrl.text) ?? 120000;
    final totalCrew = _requirements.fold(0, (sum, r) => sum + r.quantity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Event Assembly Blueprint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.bgSurfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_nameCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${_dateCtrl.text} • ${_venueCtrl.text}, ${_cityCtrl.text}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Budget: ${CurrencyFormatter.format(budget)}', style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                  Text('Crew Quota: $totalCrew positions', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
