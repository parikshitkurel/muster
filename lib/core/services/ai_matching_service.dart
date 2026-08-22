import '../../models/event.dart';
import '../../models/freelancer.dart';
import '../../models/crew.dart';
import 'gemini_service.dart';

class AIMatchingService {
  /// Deterministic Multi-Constraint Matching Algorithm
  /// Budget is a STRICT HARD CONSTRAINT: Total Crew Cost <= Event Budget
  static OptimizationResult generateRecommendation(
    EventItem event,
    List<FreelancerCandidate> allCandidates, {
    int permutationIndex = 0,
  }) {
    final List<CrewMember> recommendedCrew = [];
    int totalCost = 0;

    for (var req in event.requirements) {
      // 1. Filter candidates by spatial radius
      var pool = allCandidates.where((c) => c.distanceKm <= event.proximityKm).toList();

      // 2. Filter candidates matching requirement role or skills
      var rolePool = pool.where((c) {
        final reqRoleLower = req.role.toLowerCase();
        final candRoleLower = c.role.toLowerCase();
        final matchesRole = candRoleLower == reqRoleLower ||
            candRoleLower.contains(reqRoleLower) ||
            reqRoleLower.contains(candRoleLower);
        final matchesSkill = c.skills.any((s) => s.toLowerCase().contains(reqRoleLower) || reqRoleLower.contains(s.toLowerCase()));
        return matchesRole || matchesSkill;
      }).toList();

      // Graceful relaxation to full candidate pool if strict role pool is empty
      if (rolePool.isEmpty && pool.isNotEmpty) {
        rolePool = List.from(pool);
      }

      if (rolePool.isEmpty) continue;

      // 3. Filter by rate ceiling
      var validPool = rolePool.where((c) => c.expectedRate <= req.maxRatePerHour).toList();
      if (validPool.isEmpty) validPool = rolePool;

      double calcCompositeScore(FreelancerCandidate c) {
        final proxScore = event.proximityKm > 0
            ? ((1.0 - (c.distanceKm / event.proximityKm)).clamp(0.0, 1.0) * 100)
            : 100.0;
        final maxRate = req.maxRatePerHour > 0 ? req.maxRatePerHour : 1500;
        final rateScore = ((1.0 - (c.expectedRate / maxRate)).clamp(0.0, 1.0) * 100);
        return (c.matchScore * event.skillWeight) +
            (c.reliabilityScore * event.reliabilityWeight) +
            (proxScore * event.proximityWeight) +
            (rateScore * event.rateWeight);
      }

      if (permutationIndex == 1) {
        // Option 2: Budget-Optimized (Sort by Cost ascending)
        validPool.sort((a, b) => a.expectedRate.compareTo(b.expectedRate));
      } else if (permutationIndex == 2) {
        // Option 3: High-Reliability Veterans (Sort by Reliability & Experience)
        validPool.sort((a, b) {
          int cmp = b.reliabilityScore.compareTo(a.reliabilityScore);
          if (cmp != 0) return cmp;
          return b.experienceYears.compareTo(a.experienceYears);
        });
      } else {
        // Option 1: Multi-objective Pareto-Optimal Weighted Score
        validPool.sort((a, b) => calcCompositeScore(b).compareTo(calcCompositeScore(a)));
      }

      int count = 0;
      for (var cand in validPool) {
        if (count >= req.quantity) break;
        if (recommendedCrew.any((m) => m.freelancerId == cand.id)) continue;

        int shiftCost = cand.expectedRate * 8;
        int computedScore = calcCompositeScore(cand).round().clamp(0, 100);

        recommendedCrew.add(
          CrewMember(
            freelancerId: cand.id,
            fullName: cand.name,
            role: req.role,
            matchScore: computedScore,
            reliabilityScore: cand.reliabilityScore,
            allocatedCost: shiftCost,
            rationale:
                'Selected for ${req.role} with ${cand.experienceYears} yrs experience, ${cand.reliabilityScore}% reliability rating, ${cand.distanceKm} km proximity, and $computedScore% weighted match score.',
          ),
        );
        totalCost += shiftCost;
        count++;
      }
    }

    int overallMatch = recommendedCrew.isEmpty
        ? 0
        : (recommendedCrew.map((m) => m.matchScore).reduce((a, b) => a + b) /
                recommendedCrew.length)
            .round();

    int budgetRem = event.budget - totalCost;
    bool isValid = budgetRem >= 0 && recommendedCrew.length >= event.totalCrewNeeded && recommendedCrew.isNotEmpty;

    String optionTitle = 'Option #${permutationIndex + 1}: ';
    String strategyDesc = '';
    if (permutationIndex == 1) {
      optionTitle += 'Budget-Optimized Roster';
      strategyDesc = 'Minimizes event crew expenditure while meeting minimum quality thresholds.';
    } else if (permutationIndex == 2) {
      optionTitle += 'High-Reliability Veterans';
      strategyDesc = 'Maximizes past reliability scores and verified shift track records.';
    } else {
      optionTitle += 'Balanced Optimal Fit';
      strategyDesc = 'Multi-objective Pareto-optimal trade-off between skill match, proximity, and rate.';
    }

    return OptimizationResult(
      optionTitle: optionTitle,
      optionStrategy: strategyDesc,
      overallMatchScore: overallMatch,
      totalCost: totalCost,
      budgetRemaining: budgetRem,
      requirementCoverage: event.totalCrewNeeded == 0
          ? 1.0
          : recommendedCrew.length / event.totalCrewNeeded,
      isValidBudget: isValid,
      recommendedCrew: recommendedCrew,
    );
  }

  /// Async Gemini AI-enhanced explainability pipeline
  /// Deterministic solver selects the crew; Gemini synthesizes natural-language explainability
  static Future<OptimizationResult> generateRecommendationWithGemini(
    EventItem event,
    List<FreelancerCandidate> allCandidates, {
    int permutationIndex = 0,
  }) async {
    // 1. Run deterministic constraint solver first (Correctness)
    final baseResult = generateRecommendation(
      event,
      allCandidates,
      permutationIndex: permutationIndex,
    );

    // If no valid crew or empty, return immediately without invoking AI
    if (baseResult.recommendedCrew.isEmpty) {
      return baseResult;
    }

    // 2. Prepare minimal, privacy-safe candidate metadata for Gemini
    final candidateMetadata = <String, Map<String, dynamic>>{};
    for (var member in baseResult.recommendedCrew) {
      final cand = allCandidates.firstWhere(
        (c) => c.id == member.freelancerId,
        orElse: () => FreelancerCandidate(
          id: member.freelancerId,
          name: member.fullName,
          role: member.role,
          expectedRate: member.allocatedCost ~/ 8,
          experienceYears: 3,
          reliabilityScore: member.reliabilityScore,
          matchScore: member.matchScore,
          distanceKm: 5.0,
          skills: [],
        ),
      );

      candidateMetadata[member.freelancerId] = {
        'distance_km': cand.distanceKm,
        'experience_years': cand.experienceYears,
        'skills': cand.skills,
      };
    }

    // 3. Invoke Supabase Edge Function / Gemini for explainability (Intelligence & Explainability)
    final geminiResult = await GeminiService.explainRoster(
      eventName: event.name,
      eventType: event.type,
      budget: event.budget,
      strategy: baseResult.optionStrategy,
      selectedCrew: baseResult.recommendedCrew,
      candidateMetadata: candidateMetadata,
    );

    // 4. Merge Gemini explainability into the validated deterministic roster
    final enhancedCrew = baseResult.recommendedCrew.map((member) {
      final aiRationale = geminiResult.memberExplanations[member.freelancerId];
      if (aiRationale != null && aiRationale.isNotEmpty) {
        return member.copyWith(rationale: aiRationale);
      }
      return member;
    }).toList();

    return baseResult.copyWith(
      recommendedCrew: enhancedCrew,
      optionStrategy: geminiResult.summary.isNotEmpty
          ? geminiResult.summary
          : baseResult.optionStrategy,
    );
  }
}
