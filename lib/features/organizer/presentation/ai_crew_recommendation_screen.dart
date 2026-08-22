import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/services/ai_matching_service.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/repositories/freelancer_repository.dart';
import '../../../data/repositories/matching_repository.dart';

class AICrewRecommendationScreen extends ConsumerStatefulWidget {
  final String eventId;
  final int permutation;

  const AICrewRecommendationScreen({
    super.key,
    required this.eventId,
    this.permutation = 0,
  });

  @override
  ConsumerState<AICrewRecommendationScreen> createState() =>
      _AICrewRecommendationScreenState();
}

class _AICrewRecommendationScreenState
    extends ConsumerState<AICrewRecommendationScreen> {
  late int _currentPermutation;

  @override
  void initState() {
    super.initState();
    _currentPermutation = widget.permutation;
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final freelancerState = ref.watch(freelancerProvider);
    final matchingState = ref.watch(matchingProvider);

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

    final cachedList = matchingState.cachedRecommendations[evt.id];
    final result = (cachedList != null && cachedList.length > _currentPermutation)
        ? cachedList[_currentPermutation]
        : AIMatchingService.generateRecommendation(
            evt,
            freelancerState.allCandidates,
            permutationIndex: _currentPermutation,
          );

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
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
                  InkWell(
                    onTap: () => context.go('/organizer/applicants/${evt.id}'),
                    child: const Text('Applicant Pool', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ),
                  const Text(' / ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const Text('AI Crew Recommendation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.sparkles, size: 12, color: AppColors.primaryDark),
                            SizedBox(width: 4),
                            Text(
                              'GEMINI 1.5 + CP-SAT SOLVER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        result.optionTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.optionStrategy} • ${evt.name}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go('/organizer/applicants/${evt.id}'),
                        icon: const Icon(LucideIcons.pencil, size: 14),
                        label: const Text('Choose Manually'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentPermutation = (_currentPermutation + 1) % 3;
                          });
                        },
                        icon: const Icon(LucideIcons.refreshCw, size: 14),
                        label: const Text('Find Another Crew'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                        onPressed: result.isValidBudget
                            ? () {
                                ref.read(eventsProvider.notifier).approveCrew(
                                      evt.id,
                                      result.recommendedCrew,
                                      result.totalCost,
                                    );
                                context.go('/organizer/final-crew/${evt.id}');
                              }
                            : null,
                        icon: const Icon(LucideIcons.checkCircle, size: 16),
                        label: const Text('Approve Crew Roster →'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!result.isValidBudget) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, color: AppColors.danger, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No suitable crew found within current budget. Adjust budget ceiling or select candidates manually.',
                          style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _ScoreMetricCard(
                      label: 'OVERALL MATCH SCORE',
                      value: '${result.overallMatchScore}%',
                      subtext: 'Joint multi-objective fit',
                      color: AppColors.primary,
                      icon: LucideIcons.sparkles,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScoreMetricCard(
                      label: 'TOTAL CREW COST',
                      value: CurrencyFormatter.format(result.totalCost),
                      subtext: '₹${(result.totalCost / 8).round()}/hr avg shift rate',
                      color: AppColors.info,
                      icon: LucideIcons.wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScoreMetricCard(
                      label: 'BUDGET REMAINING',
                      value: CurrencyFormatter.format(result.budgetRemaining),
                      subtext: '${((result.budgetRemaining / evt.budget) * 100).round()}% safety buffer',
                      color: AppColors.success,
                      icon: LucideIcons.piggyBank,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScoreMetricCard(
                      label: 'REQUIREMENT COVERAGE',
                      value: '${result.recommendedCrew.length} / ${evt.totalCrewNeeded}',
                      subtext: '${(result.requirementCoverage * 100).round()}% quota filled',
                      color: AppColors.textMain,
                      icon: LucideIcons.shieldCheck,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const Text(
                'Recommended Crew Allocations & Selection Explainability',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Transparent natural language rationale explaining why each freelancer was chosen by the CP-SAT solver.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: result.recommendedCrew.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = result.recommendedCrew[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                      member.fullName.split(' ').map((n) => n[0]).take(2).join(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                      ),
                                      Text(
                                        'Assigned Role: ${member.role}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${member.matchScore}% MATCH',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    CurrencyFormatter.format(member.allocatedCost),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurfaceSubtle,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.info, size: 15, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Why selected: ${member.rationale}',
                                    style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMain),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;
  final Color color;
  final IconData icon;

  const _ScoreMetricCard({
    required this.label,
    required this.value,
    required this.subtext,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
