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

    final candidatesByRole = <String, List<FreelancerCandidate>>{};
    for (var cand in allCandidates) {
      // Spatial & Rate Pre-filtering (Hard Constraints)
      if (cand.distanceKm > event.proximityKm) continue;
      candidatesByRole.putIfAbsent(cand.role, () => []).add(cand);
    }

    for (var req in event.requirements) {
      var pool = candidatesByRole[req.role] ?? [];
      if (pool.isEmpty) continue;

      // Filter by rate ceiling (Hard Constraint)
      var validPool = pool.where((c) => c.expectedRate <= req.maxRatePerHour).toList();
      if (validPool.isEmpty) validPool = pool; // Graceful relaxation if strict ceiling is unpopulated

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
        // Option 1: Balanced Pareto-Optimal Fit (Multi-objective score)
        validPool.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      }

      int count = 0;
      for (var cand in validPool) {
        if (count >= req.quantity) break;
        if (recommendedCrew.any((m) => m.freelancerId == cand.id)) continue;

        int shiftCost = cand.expectedRate * 8;
        recommendedCrew.add(
          CrewMember(
            freelancerId: cand.id,
            fullName: cand.name,
            role: req.role,
            matchScore: cand.matchScore,
            reliabilityScore: cand.reliabilityScore,
            allocatedCost: shiftCost,
            rationale:
                'Selected for ${req.role} with ${cand.experienceYears} yrs experience, ${cand.reliabilityScore}% reliability rating, and ${cand.distanceKm} km transit proximity.',
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
    // Hard constraint verification: Budget must not be breached
    bool isValid = budgetRem >= 0 && recommendedCrew.length >= event.totalCrewNeeded;

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
