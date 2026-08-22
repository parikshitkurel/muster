import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event.dart';
import '../../models/freelancer.dart';
import '../../models/crew.dart';
import '../../core/services/ai_matching_service.dart';
import '../../core/supabase/supabase_config.dart';

class MatchingState {
  final Map<String, List<OptimizationResult>> cachedRecommendations;
  final bool isSolving;

  MatchingState({
    this.cachedRecommendations = const {},
    this.isSolving = false,
  });

  MatchingState copyWith({
    Map<String, List<OptimizationResult>>? cachedRecommendations,
    bool? isSolving,
  }) {
    return MatchingState(
      cachedRecommendations: cachedRecommendations ?? this.cachedRecommendations,
      isSolving: isSolving ?? this.isSolving,
    );
  }
}

class MatchingNotifier extends StateNotifier<MatchingState> {
  MatchingNotifier() : super(MatchingState());

  Future<OptimizationResult> runOptimization(
    EventItem event,
    List<FreelancerCandidate> pool, {
    int permutationIndex = 0,
  }) async {
    state = state.copyWith(isSolving: true);

    final result = await AIMatchingService.generateRecommendationWithGemini(
      event,
      pool,
      permutationIndex: permutationIndex,
    );

    final currentList = List<OptimizationResult>.from(
      state.cachedRecommendations[event.id] ?? [],
    );
    if (!currentList.any((r) => r.optionTitle == result.optionTitle)) {
      currentList.add(result);
    }

    final newMap = Map<String, List<OptimizationResult>>.from(
      state.cachedRecommendations,
    );
    newMap[event.id] = currentList;

    state = state.copyWith(
      cachedRecommendations: newMap,
      isSolving: false,
    );

    _persistRecommendationToSupabase(event.id, result, permutationIndex);

    return result;
  }

  Future<void> _persistRecommendationToSupabase(
    String eventId,
    OptimizationResult result,
    int permutationIndex,
  ) async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final recRes = await client
          .from('match_recommendations')
          .insert({
            'event_id': eventId,
            'option_title': result.optionTitle,
            'option_strategy': result.optionStrategy,
            'overall_match_score': result.overallMatchScore,
            'total_cost': result.totalCost,
            'budget_remaining': result.budgetRemaining,
            'requirement_coverage': result.requirementCoverage,
            'is_valid_budget': result.isValidBudget,
            'permutation_index': permutationIndex,
          })
          .select('id')
          .single();

      if (recRes['id'] != null) {
        final recId = recRes['id'] as String;
        final membersPayload = result.recommendedCrew.map((m) {
          final validFreelancerId = (m.freelancerId.length == 36 && m.freelancerId.contains('-'))
              ? m.freelancerId
              : '00000000-0000-0000-0000-000000000002';

          return {
            'recommendation_id': recId,
            'freelancer_id': validFreelancerId,
            'role': m.role,
            'match_score': m.matchScore,
            'reliability_score': m.reliabilityScore,
            'allocated_cost': m.allocatedCost,
            'rationale': m.rationale,
          };
        }).toList();

        await client.from('recommendation_members').insert(membersPayload);
        debugPrint('[Supabase WRITE SUCCESS] Persisted Recommendation #$permutationIndex ($recId) with ${membersPayload.length} members.');
      }
    } catch (e, stackTrace) {
      debugPrint('[Supabase WRITE NOTICE] Recommendation persistence error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

final matchingProvider =
    StateNotifierProvider<MatchingNotifier, MatchingState>((ref) {
  return MatchingNotifier();
});
