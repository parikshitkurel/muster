import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gemini_service.dart';
import '../../models/event.dart';
import '../../models/crew.dart';

abstract class MusterAIRepository {
  Future<GeminiExplainResult> explainCrewAllocation(
    EventItem event,
    List<CrewMember> crew,
    Map<String, dynamic> candidateMetadata,
    String strategy,
  );

  Future<String> explainTradeoffs(
    EventItem event,
    OptimizationResult option,
  );

  Future<Map<String, dynamic>?> parseNaturalLanguageRequirements(String prompt);
}

class MusterAIRepositoryImpl implements MusterAIRepository {
  @override
  Future<GeminiExplainResult> explainCrewAllocation(
    EventItem event,
    List<CrewMember> crew,
    Map<String, dynamic> candidateMetadata,
    String strategy,
  ) {
    return GeminiService.explainRoster(
      eventName: event.name,
      eventType: event.type,
      budget: event.budget,
      strategy: strategy,
      selectedCrew: crew,
      candidateMetadata: candidateMetadata,
    );
  }

  @override
  Future<String> explainTradeoffs(
    EventItem event,
    OptimizationResult option,
  ) {
    return GeminiService.explainTradeoffs(
      eventName: event.name,
      optionTitle: option.optionTitle,
      strategy: option.optionStrategy,
      totalCost: option.totalCost,
      matchScore: option.overallMatchScore,
    );
  }

  @override
  Future<Map<String, dynamic>?> parseNaturalLanguageRequirements(String prompt) {
    return GeminiService.parseRequirements(prompt);
  }
}

final musterAIRepositoryProvider = Provider<MusterAIRepository>((ref) {
  return MusterAIRepositoryImpl();
});
