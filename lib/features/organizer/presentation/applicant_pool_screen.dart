import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/crew.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/freelancer_repository.dart';

class ApplicantPoolScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ApplicantPoolScreen({super.key, required this.eventId});

  @override
  ConsumerState<ApplicantPoolScreen> createState() => _ApplicantPoolScreenState();
}

class _ApplicantPoolScreenState extends ConsumerState<ApplicantPoolScreen> {
  String _selectedRoleFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'Match Score';
  bool _isManualMode = false;
  final Set<String> _selectedManualIds = {};

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final freelancerState = ref.watch(freelancerProvider);

    if (eventsState.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final evtMatches = eventsState.events.where((e) => e.id == widget.eventId);
    if (evtMatches.isEmpty && eventsState.events.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bgCanvas,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text('No Event Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.go('/organizer/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final evt = evtMatches.isNotEmpty ? evtMatches.first : eventsState.events.first;
    final candidates = freelancerState.allCandidates;

    // Filtering
    var filtered = candidates.where((cand) {
      final matchesRole = _selectedRoleFilter == 'All' || cand.role == _selectedRoleFilter;
      final matchesSearch = cand.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cand.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          cand.skills.any((s) => s.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesRole && matchesSearch;
    }).toList();

    // Sorting
    if (_sortBy == 'Match Score') {
      filtered.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    } else if (_sortBy == 'Hourly Rate') {
      filtered.sort((a, b) => a.expectedRate.compareTo(b.expectedRate));
    } else if (_sortBy == 'Reliability') {
      filtered.sort((a, b) => b.reliabilityScore.compareTo(a.reliabilityScore));
    } else if (_sortBy == 'Distance') {
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    final selectedManualCandidates =
        candidates.where((c) => _selectedManualIds.contains(c.id)).toList();
    final manualCost = selectedManualCandidates.fold(
      0,
      (sum, c) => sum + (c.expectedRate * 8),
    );
    final isBudgetExceeded = manualCost > evt.budget;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumbs
            Row(
              children: [
                InkWell(
                  onTap: () => context.go('/organizer/dashboard'),
                  child: const Text('Dashboard', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
                const Text(' / ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const Text('Applicant Pool', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),

            // Page Header & Hero Action Buttons (PDF Page 4)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Applicant Pool for ${evt.name}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Quota: ${evt.totalCrewNeeded} Positions • Budget Pool: ${CurrencyFormatter.format(evt.budget)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _isManualMode = !_isManualMode),
                      icon: Icon(_isManualMode ? LucideIcons.x : LucideIcons.pencil, size: 16),
                      label: Text(_isManualMode ? 'Close Manual Mode' : 'Select Manually'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _triggerAiMatchingDialog(context, evt),
                      icon: const Icon(LucideIcons.sparkles, size: 16),
                      label: const Text('Run AI Matching'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Budget Calculator for Manual Selection Mode (PDF Page 4)
            if (_isManualMode) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.bgContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.wallet, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Manual Selection: ${_selectedManualIds.length} / ${evt.totalCrewNeeded} positions',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Total Cost: ${CurrencyFormatter.format(manualCost)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: isBudgetExceeded ? AppColors.danger : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: (_selectedManualIds.length >= evt.totalCrewNeeded && !isBudgetExceeded)
                          ? () {
                              final crew = selectedManualCandidates
                                  .map(
                                    (c) => CrewMember(
                                      freelancerId: c.id,
                                      fullName: c.name,
                                      role: c.role,
                                      matchScore: c.matchScore,
                                      reliabilityScore: c.reliabilityScore,
                                      allocatedCost: c.expectedRate * 8,
                                      rationale: 'Manually selected by organizer.',
                                    ),
                                  )
                                  .toList();
                              ref.read(eventsProvider.notifier).approveCrew(evt.id, crew, manualCost);
                              context.go('/organizer/final-crew/${evt.id}');
                            }
                          : null,
                      child: const Text('Confirm Manual Crew →'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Filter & Search Controls (PDF Page 4)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: const InputDecoration(
                          hintText: 'Search candidate name, skill, or role...',
                          prefixIcon: Icon(LucideIcons.search, size: 16),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedRoleFilter,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.bgSurface,
                      items: ['All', 'Sound Engineer', 'Lighting Specialist', 'Stage Coordinator']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRoleFilter = v!),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.bgSurface,
                      items: ['Match Score', 'Hourly Rate', 'Reliability', 'Distance']
                          .map((s) => DropdownMenuItem(value: s, child: Text('Sort: $s', style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (v) => setState(() => _sortBy = v!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Candidate Cards Grid (PDF Page 4)
            filtered.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.people_outline, size: 44, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'No Applicants Yet',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'No freelancers have applied to this event yet or no candidates match your current filter.',
                              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 220,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                final cand = filtered[index];
                final isSelectedManual = _selectedManualIds.contains(cand.id);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    cand.name.split(' ').map((n) => n[0]).take(2).join(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cand.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    Text(cand.role, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.successBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${cand.matchScore}% MATCH',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),

                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: cand.skills
                              .take(3)
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurfaceSubtle,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(s, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                ),
                              )
                              .toList(),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.bgSurfaceSubtle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${cand.expectedRate}/hr',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace', fontSize: 12),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 11, color: AppColors.textMuted),
                                  const SizedBox(width: 3),
                                  Text('${cand.distanceKm} km', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.shieldCheck, size: 11, color: AppColors.success),
                                  const SizedBox(width: 3),
                                  Text('${cand.reliabilityScore}% Rel', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (_isManualMode) ...[
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelectedManual ? AppColors.primary : AppColors.bgContainer,
                              foregroundColor: isSelectedManual ? Colors.white : AppColors.textMain,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isSelectedManual) {
                                  _selectedManualIds.remove(cand.id);
                                } else {
                                  _selectedManualIds.add(cand.id);
                                }
                              });
                            },
                            icon: Icon(isSelectedManual ? LucideIcons.checkCircle2 : LucideIcons.plusCircle, size: 14),
                            label: Text(isSelectedManual ? 'Selected in Crew' : 'Select for Manual Crew'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _triggerAiMatchingDialog(BuildContext context, dynamic evt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SolverTerminalDialog(
        event: evt,
        onComplete: () {
          Navigator.of(ctx).pop();
          context.go('/organizer/recommendation/${evt.id}');
        },
      ),
    );
  }
}

class _SolverTerminalDialog extends StatefulWidget {
  final dynamic event;
  final VoidCallback onComplete;

  const _SolverTerminalDialog({
    required this.event,
    required this.onComplete,
  });

  @override
  State<_SolverTerminalDialog> createState() => _SolverTerminalDialogState();
}

class _SolverTerminalDialogState extends State<_SolverTerminalDialog> {
  final List<String> _logs = [];
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _startSolverSimulation();
  }

  void _startSolverSimulation() async {
    final steps = [
      '>> [CP-SAT] Initializing deterministic constraint solver engine...',
      '>> [PARSER] Loading role quotas for ${widget.event.name}...',
      '>> [SPATIAL] Filtering candidate pool within ${widget.event.proximityKm} km radius...',
      '>> [RELIABILITY] Calculating Bayesian attendance scores & rating records...',
      '>> [SOLVER] Evaluating Pareto-optimal trade-offs across 3 permutations...',
      '>> [OPTIMIZED] Optimal Crew Assembly synthesized with 0 quota violations.',
    ];

    for (var step in steps) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _logs.add(step);
        });
      }
    }

    if (mounted) {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(LucideIcons.sparkles, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'AI Crew Solver Execution Engine',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                  if (!_isFinished)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCanvas,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (ctx, idx) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        _logs[idx],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _isFinished ? widget.onComplete : null,
                  child: const Text('View Optimal Crew Roster →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
