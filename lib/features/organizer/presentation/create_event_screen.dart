import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/services/gemini_service.dart';
import '../../../models/event.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/event_repository.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  int _currentStep = 1;

  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _eventType = 'Conference';

  final List<EventRequirement> _requirements = [];

  final _budgetCtrl = TextEditingController();
  int _proximityKm = 25;

  static const List<String> _commonRoles = [
    'Sound Engineer',
    'Lighting Specialist',
    'Stage Coordinator',
    'Camera Operator',
    'Rigging Tech',
    'Production Crew',
    'Event Operations',
    'Registration Desk',
    'Video Director',
    'Custom...',
  ];

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

  bool _isPublishing = false;

  Future<void> _publishEvent() async {
    if (_isPublishing) return;
    setState(() => _isPublishing = true);

    final name = _nameCtrl.text.trim().isEmpty ? 'Untitled Event' : _nameCtrl.text.trim();
    final budget = int.tryParse(_budgetCtrl.text) ?? 50000;
    final user = ref.read(authProvider).currentUser;

    if (user == null) {
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before publishing an event.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final newEvent = EventItem(
      id: '', // Empty ID will let Supabase automatically generate a valid UUID v4
      organizerId: user.id,
      name: name,
      type: _eventType,
      date: _dateCtrl.text.trim().isEmpty ? DateTime.now().toString().substring(0, 10) : _dateCtrl.text.trim(),
      venue: _venueCtrl.text.trim().isEmpty ? 'TBD' : _venueCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? user.organizerCity : _cityCtrl.text.trim(),
      budget: budget,
      proximityKm: _proximityKm,
      status: EventStatus.published,
      applicantCount: 0,
      requirements: _requirements,
      description: _descCtrl.text.trim(),
    );

    try {
      await ref.read(eventsProvider.notifier).addEvent(newEvent);
      if (!mounted) return;
      setState(() => _isPublishing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Event and roles successfully created in Supabase database!'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/organizer/my-events');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database Error creating event: $e'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _showAddRoleDialog({EventRequirement? existing, int? editIndex}) {
    String selectedRole = existing?.role ?? _commonRoles.first;
    bool isCustom = !_commonRoles.contains(selectedRole) || selectedRole == 'Custom...';
    final customRoleCtrl = TextEditingController(text: isCustom ? (existing?.role ?? '') : '');
    final qtyCtrl = TextEditingController(text: '${existing?.quantity ?? 1}');
    final rateCtrl = TextEditingController(text: '${existing?.maxRatePerHour ?? 1500}');
    final expCtrl = TextEditingController(text: '${existing?.minExperienceYears ?? 2}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(LucideIcons.users, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                editIndex != null ? 'Edit Role Quota' : 'Add Crew Role Quota',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: isCustom ? 'Custom...' : selectedRole,
                  decoration: const InputDecoration(labelText: 'Specialist Role *'),
                  items: _commonRoles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setDlgState(() {
                      selectedRole = val;
                      isCustom = val == 'Custom...';
                    });
                  },
                ),
                if (isCustom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customRoleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Custom Role Title *',
                      hintText: 'e.g. Drone Videographer',
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity *',
                          hintText: '1',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rateCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Rate Cap (₹/hr) *',
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: expCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min. Experience (Years) *',
                    hintText: '2',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final roleName = isCustom
                    ? customRoleCtrl.text.trim()
                    : selectedRole;
                if (roleName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please specify a role name.')),
                  );
                  return;
                }

                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final rate = int.tryParse(rateCtrl.text) ?? 1500;
                final exp = int.tryParse(expCtrl.text) ?? 2;

                final newReq = EventRequirement(
                  role: roleName,
                  quantity: qty > 0 ? qty : 1,
                  maxRatePerHour: rate > 0 ? rate : 1500,
                  minExperienceYears: exp >= 0 ? exp : 0,
                  requiredSkills: [roleName, 'Event Operations'],
                );

                setState(() {
                  if (editIndex != null) {
                    _requirements[editIndex] = newReq;
                  } else {
                    final existingIdx = _requirements.indexWhere(
                      (r) => r.role.toLowerCase() == roleName.toLowerCase(),
                    );
                    if (existingIdx != -1) {
                      _requirements[existingIdx] = newReq;
                    } else {
                      _requirements.add(newReq);
                    }
                  }
                });

                Navigator.pop(ctx);
              },
              child: Text(editIndex != null ? 'Update Role' : 'Add Role'),
            ),
          ],
        ),
      ),
    );
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
    final isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                      onPressed: _isPublishing ? null : _publishEvent,
                      icon: _isPublishing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.send, size: 16),
                      label: Text(_isPublishing ? 'Publishing to Database...' : 'Publish Event & Open Candidate Pool'),
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

    if (ResponsiveLayout.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STEP $_currentStep OF 5: ${steps[_currentStep - 1].toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  fontFamily: 'monospace',
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${(_currentStep / 5 * 100).round()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _currentStep / 5,
              minHeight: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      );
    }

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
        return _buildStep4Weights();
      case 5:
        return _buildStep5Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicDetails() {
    final isMobile = ResponsiveLayout.isMobile(context);

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
          decoration: const InputDecoration(labelText: 'Event Name *', hintText: 'e.g. Annual Tech Symposium 2026'),
        ),
        const SizedBox(height: 14),
        if (isMobile) ...[
          DropdownButtonFormField<String>(
            initialValue: _eventType,
            decoration: const InputDecoration(labelText: 'Event Category *'),
            items: ['Conference', 'Concert', 'Corporate Summit', 'Exhibition', 'Wedding']
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _eventType = v!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _dateCtrl,
            decoration: const InputDecoration(labelText: 'Event Date (YYYY-MM-DD) *', hintText: '2026-10-15'),
          ),
        ] else
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
                  decoration: const InputDecoration(labelText: 'Event Date (YYYY-MM-DD) *', hintText: '2026-10-15'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        if (isMobile) ...[
          TextFormField(
            controller: _venueCtrl,
            decoration: const InputDecoration(labelText: 'Venue / Facility *', hintText: 'e.g. Palace Grounds'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cityCtrl,
            decoration: const InputDecoration(labelText: 'City *', hintText: 'e.g. Bengaluru'),
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _venueCtrl,
                  decoration: const InputDecoration(labelText: 'Venue / Facility *', hintText: 'e.g. Palace Grounds'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(labelText: 'City *', hintText: 'e.g. Bengaluru'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Event Description & Special Brief *', hintText: 'Brief summary of event production requirements...'),
        ),
      ],
    );
  }

  Widget _buildStep2Requirements() {
    final isMobile = ResponsiveLayout.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Crew Roles & Quotas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            OutlinedButton.icon(
              onPressed: () => _showAddRoleDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Role Quota'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_requirements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.people_outline, size: 24, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No crew roles added yet.',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add the roles you need for this event.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddRoleDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add First Role →'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _requirements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final req = _requirements[index];
              if (isMobile) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.role, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showAddRoleDialog(existing: req, editIndex: index),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _requirements.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Qty: ${req.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Cap: ₹${req.maxRatePerHour}/hr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                          ),
                          const SizedBox(width: 8),
                          Text('${req.minExperienceYears}+ yrs exp', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                );
              }

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
                      child: Text('Qty: ${req.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Expanded(
                      child: Text('Cap: ₹${req.maxRatePerHour}/hr', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
                    ),
                    Expanded(
                      child: Text('Min. ${req.minExperienceYears} yrs exp', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                      onPressed: () => _showAddRoleDialog(existing: req, editIndex: index),
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
            hintText: 'e.g. 100000',
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

  double _skillWeight = 0.40;
  double _reliabilityWeight = 0.35;
  double _proximityWeight = 0.15;
  double _rateWeight = 0.10;

  Widget _buildStep4Weights() {
    final totalSum = (_skillWeight + _reliabilityWeight + _proximityWeight + _rateWeight) * 100;
    final totalPercentage = totalSum.round();
    final isValidSum = totalPercentage == 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Optimization Objective Weights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Chip(
              label: Text('Total Weight: $totalPercentage%', style: TextStyle(color: isValidSum ? Colors.white : Colors.amber.shade900, fontWeight: FontWeight.w800, fontSize: 11)),
              backgroundColor: isValidSum ? AppColors.success : AppColors.bgSurfaceSubtle,
              side: BorderSide(color: isValidSum ? AppColors.success : AppColors.border),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Tune the CP-SAT solver cost function weights for candidate selection.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        _buildWeightSlider('Skill & Experience Match Weight', _skillWeight, (v) => setState(() => _skillWeight = v)),
        const SizedBox(height: 14),
        _buildWeightSlider('Reliability Score & Past Attendance', _reliabilityWeight, (v) => setState(() => _reliabilityWeight = v)),
        const SizedBox(height: 14),
        _buildWeightSlider('Proximity & Travel Distance', _proximityWeight, (v) => setState(() => _proximityWeight = v)),
        const SizedBox(height: 14),
        _buildWeightSlider('Hourly Rate Budget Efficiency', _rateWeight, (v) => setState(() => _rateWeight = v)),
      ],
    );
  }

  Widget _buildWeightSlider(String label, double currentVal, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${(currentVal * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: currentVal.clamp(0.0, 1.0),
          min: 0.0,
          max: 1.0,
          divisions: 100,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStep5Review() {
    final budget = int.tryParse(_budgetCtrl.text) ?? 0;
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
              Text(_nameCtrl.text.isEmpty ? 'Untitled Event' : _nameCtrl.text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                '${_dateCtrl.text.isEmpty ? 'Date TBD' : _dateCtrl.text} • ${_venueCtrl.text.isEmpty ? 'Venue TBD' : _venueCtrl.text}, ${_cityCtrl.text.isEmpty ? 'City TBD' : _cityCtrl.text}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Budget: ${CurrencyFormatter.format(budget)}', style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                  Text('Crew Quota: $totalCrew positions', style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              if (_requirements.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Role Breakdown:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _requirements.map((r) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('${r.role} × ${r.quantity} (Cap: ₹${r.maxRatePerHour}/hr)', style: const TextStyle(fontSize: 11)),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
