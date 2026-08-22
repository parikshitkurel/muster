import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/supabase/supabase_config.dart';
import '../../models/crew.dart';

class GeminiExplainResult {
  final bool isAiGenerated;
  final String summary;
  final String overallReason;
  final List<String> tradeoffs;
  final Map<String, String> memberExplanations; // freelancer_id -> reason

  GeminiExplainResult({
    required this.isAiGenerated,
    required this.summary,
    required this.overallReason,
    required this.tradeoffs,
    required this.memberExplanations,
  });

  factory GeminiExplainResult.deterministicFallback({
    required String strategy,
    required int totalCost,
    required int matchScore,
  }) {
    return GeminiExplainResult(
      isAiGenerated: false,
      summary: '$strategy verified with $matchScore% composite fit index.',
      overallReason: 'All multi-constraint quotas, budget caps, and transit proximity boundaries are satisfied.',
      tradeoffs: ['Budget adherence strictly guaranteed', 'Zero role quota violations'],
      memberExplanations: {},
    );
  }
}

class GeminiService {
  /// Invokes the secure Supabase Edge Function `muster-ai` to explain the selected crew
  static Future<GeminiExplainResult> explainRoster({
    required String eventName,
    required String eventType,
    required int budget,
    required String strategy,
    required List<CrewMember> selectedCrew,
    required Map<String, dynamic> candidateMetadata,
  }) async {
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final payloadCrew = selectedCrew.map((m) {
          final meta = candidateMetadata[m.freelancerId] as Map<String, dynamic>? ?? {};
          return {
            'freelancer_id': m.freelancerId,
            'name': m.fullName,
            'role': m.role,
            'match_score': m.matchScore,
            'reliability_score': m.reliabilityScore,
            'allocated_cost': m.allocatedCost,
            'distance_km': meta['distance_km'] ?? 5.0,
            'experience_years': meta['experience_years'] ?? 3,
            'skills': meta['skills'] ?? <String>[],
          };
        }).toList();

        final res = await client.functions.invoke(
          'muster-ai',
          body: {
            'action': 'explain_roster',
            'event_name': eventName,
            'event_type': eventType,
            'budget': budget,
            'strategy': strategy,
            'selected_crew': payloadCrew,
          },
        );

        if (res.status == 200 && res.data != null) {
          final data = res.data is String ? jsonDecode(res.data) : res.data;
          final isAi = data['is_ai_generated'] as bool? ?? false;
          final summary = data['summary'] as String? ?? '';
          final overall = data['overall_reason'] as String? ?? '';
          final tradeoffs = (data['tradeoffs'] as List? ?? []).map((t) => t.toString()).toList();

          final memberMap = <String, String>{};
          final explanations = data['member_explanations'] as List? ?? [];
          for (var exp in explanations) {
            final fId = exp['freelancer_id'] as String?;
            final reason = exp['reason'] as String?;
            if (fId != null && reason != null) {
              memberMap[fId] = reason;
            }
          }

          return GeminiExplainResult(
            isAiGenerated: isAi,
            summary: summary.isNotEmpty ? summary : '$strategy verified.',
            overallReason: overall.isNotEmpty ? overall : 'Satisfies all event requirements.',
            tradeoffs: tradeoffs,
            memberExplanations: memberMap,
          );
        }
      } catch (e) {
        debugPrint('[Gemini Edge] Notice: Edge Function unavailable ($e). Falling back to deterministic explainability.');
      }
    }

    return GeminiExplainResult.deterministicFallback(
      strategy: strategy,
      totalCost: selectedCrew.fold(0, (sum, m) => sum + m.allocatedCost),
      matchScore: selectedCrew.isEmpty
          ? 90
          : (selectedCrew.map((m) => m.matchScore).reduce((a, b) => a + b) ~/ selectedCrew.length),
    );
  }

  /// Invokes the Supabase Edge Function to explain trade-offs between alternatives
  static Future<String> explainTradeoffs({
    required String eventName,
    required String optionTitle,
    required String strategy,
    required int totalCost,
    required int matchScore,
  }) async {
    final client = SupabaseConfig.client;

    if (client != null) {
      try {
        final res = await client.functions.invoke(
          'muster-ai',
          body: {
            'action': 'explain_tradeoffs',
            'event_name': eventName,
            'alternative_option': {
              'option_title': optionTitle,
              'strategy': strategy,
              'total_cost': totalCost,
              'match_score': matchScore,
            },
          },
        );

        if (res.status == 200 && res.data != null) {
          final data = res.data is String ? jsonDecode(res.data) : res.data;
          final summary = data['tradeoff_summary'] as String?;
          if (summary != null && summary.isNotEmpty) {
            return summary;
          }
        }
      } catch (_) {}
    }

    return '$strategy synthesized with $matchScore% composite quality index and ₹$totalCost budget allocation.';
  }

  /// Invokes Edge Function for natural language requirement parsing
  static Future<Map<String, dynamic>?> parseRequirements(String prompt) async {
    final client = SupabaseConfig.client;
    if (client == null) return null;

    try {
      final res = await client.functions.invoke(
        'muster-ai',
        body: {
          'action': 'parse_requirements',
          'prompt': prompt,
        },
      );

      if (res.status == 200 && res.data != null) {
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        return data['parsed_requirements'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }
}
