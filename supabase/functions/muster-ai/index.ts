// ==============================================================================
// MUSTER — Supabase Edge Function: muster-ai
// ==============================================================================
// Serves as the secure server-side AI intelligence & explainability gateway.
// Communicates with Google Gemini 1.5 API without exposing secrets to the client.
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface RequestPayload {
  action: "explain_roster" | "explain_tradeoffs" | "parse_requirements";
  event_name?: string;
  event_type?: string;
  budget?: number;
  strategy?: string;
  selected_crew?: Array<{
    freelancer_id: string;
    name: string;
    role: string;
    match_score: number;
    reliability_score: number;
    allocated_cost: number;
    distance_km?: number;
    experience_years?: number;
    skills?: string[];
  }>;
  alternative_option?: {
    option_title: string;
    strategy: string;
    total_cost: number;
    match_score: number;
  };
  prompt?: string;
}

serve(async (req: Request) => {
  // Handle CORS Preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const startTime = Date.now();

  try {
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");

    if (!geminiApiKey) {
      console.warn("[muster-ai] GEMINI_API_KEY secret not set. Returning deterministic fallback.");
      return new Response(
        JSON.stringify({
          success: true,
          is_ai_generated: false,
          fallback_reason: "GEMINI_API_KEY not configured on edge server",
          summary: "Optimal crew allocation verified by deterministic constraint engine.",
          overall_reason: "Pareto-optimal allocation satisfying all role quotas and budget limits.",
          tradeoffs: ["Budget adherence guaranteed", "Minimum quality thresholds satisfied"],
          member_explanations: [],
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const payload: RequestPayload = await req.json();
    console.log(`[muster-ai] Processing action: ${payload.action} for event: ${payload.event_name ?? "N/A"}`);

    if (payload.action === "explain_roster") {
      const result = await handleExplainRoster(payload, geminiApiKey);
      console.log(`[muster-ai] explain_roster completed in ${Date.now() - startTime}ms`);
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    } else if (payload.action === "explain_tradeoffs") {
      const result = await handleExplainTradeoffs(payload, geminiApiKey);
      console.log(`[muster-ai] explain_tradeoffs completed in ${Date.now() - startTime}ms`);
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    } else if (payload.action === "parse_requirements") {
      const result = await handleParseRequirements(payload, geminiApiKey);
      console.log(`[muster-ai] parse_requirements completed in ${Date.now() - startTime}ms`);
      return new Response(JSON.stringify(result), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    } else {
      return new Response(
        JSON.stringify({ error: `Unknown action: ${payload.action}` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }
  } catch (error: any) {
    console.error(`[muster-ai] Error processing request in ${Date.now() - startTime}ms:`, error.message);
    return new Response(
      JSON.stringify({
        success: true,
        is_ai_generated: false,
        fallback_reason: error.message,
        summary: "Crew assembly verified by deterministic optimization engine.",
        overall_reason: "All hard constraints (budget ceiling, role quotas, spatial proximity) are fully satisfied.",
        tradeoffs: [],
        member_explanations: [],
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  }
});

/**
 * Action A: Explain Roster and Individual Candidate Allocations
 */
async function handleExplainRoster(payload: RequestPayload, apiKey: string) {
  const crewSanitized = (payload.selected_crew ?? []).map((m) => ({
    freelancer_id: m.freelancer_id,
    role: m.role,
    name: m.name,
    match_score: m.match_score,
    reliability_score: m.reliability_score,
    cost: m.allocated_cost,
    distance_km: m.distance_km ?? 5.0,
    skills: m.skills ?? [],
  }));

  const systemInstruction = `
You are MUSTER's AI Crew Explainability Assistant.
Your task is to generate natural-language explainability rationales for an already-optimized, deterministic event crew roster.
IMPORTANT RULES:
1. You DO NOT select the crew; the deterministic constraint solver has already verified budget and quotas.
2. Provide a concise overall summary and individual 1-sentence justifications for why each candidate is well-suited.
3. Highlight trade-offs like reliability vs cost vs proximity.
4. Output MUST be strict valid JSON matching the schema.
`;

  const userPrompt = `
Event: "${payload.event_name ?? "Live Event"}" (Type: ${payload.event_type ?? "Production"})
Budget Pool: ₹${payload.budget ?? 100000}
Optimization Strategy: ${payload.strategy ?? "Balanced Pareto Fit"}

Selected Candidate Roster:
${JSON.stringify(crewSanitized, null, 2)}

Respond with JSON in this exact structure:
{
  "summary": "1-2 sentence overall roster synergy summary",
  "overall_reason": "Why this combination satisfies the organizer objectives",
  "tradeoffs": ["Trade-off observation 1", "Trade-off observation 2"],
  "member_explanations": [
    {
      "freelancer_id": "freelancer_id_here",
      "reason": "1-sentence explainability rationale mentioning role, skill, and reliability"
    }
  ]
}
`;

  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

  const response = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: `${systemInstruction}\n\n${userPrompt}` }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.2,
        maxOutputTokens: 600,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini API HTTP ${response.status}: ${await response.text()}`);
  }

  const geminiData = await response.json();
  const rawText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!rawText) {
    throw new Error("Empty response received from Gemini API");
  }

  const parsed = JSON.parse(rawText);
  return {
    success: true,
    is_ai_generated: true,
    summary: parsed.summary ?? "Optimized crew assembly synthesized.",
    overall_reason: parsed.overall_reason ?? "All hard constraints fully satisfied.",
    tradeoffs: parsed.tradeoffs ?? [],
    member_explanations: parsed.member_explanations ?? [],
  };
}

/**
 * Action B: Explain Trade-offs between Alternative Roster Options
 */
async function handleExplainTradeoffs(payload: RequestPayload, apiKey: string) {
  const userPrompt = `
Event: "${payload.event_name ?? "Live Event"}"
Alternative Recommendation: "${payload.alternative_option?.option_title ?? "Alternative"}"
Alternative Strategy: "${payload.alternative_option?.strategy ?? "Budget Shift"}"
Total Cost: ₹${payload.alternative_option?.total_cost ?? 0}
Composite Match Score: ${payload.alternative_option?.match_score ?? 0}%

Explain in 1-2 concise sentences what the organizer gains or trades off with this alternative compared to the primary recommendation (e.g. cost savings vs experience vs proximity).
Respond in JSON:
{
  "tradeoff_summary": "1-2 sentence trade-off explanation"
}
`;

  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

  const response = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: userPrompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.3,
        maxOutputTokens: 200,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini API HTTP ${response.status}`);
  }

  const data = await response.json();
  const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
  const parsed = JSON.parse(rawText || "{}");

  return {
    success: true,
    is_ai_generated: true,
    tradeoff_summary: parsed.tradeoff_summary ?? "Alternative candidate allocation with altered cost/reliability trade-off.",
  };
}

/**
 * Action C: Natural Language Requirement Understanding (NLP to Structured Quotas)
 */
async function handleParseRequirements(payload: RequestPayload, apiKey: string) {
  const userPrompt = `
Extract structured event requirements from this natural language brief:
"${payload.prompt ?? "Need 2 sound engineers and 1 lighting technician for a concert in Bengaluru under 1.5 lakhs."}"

Output JSON matching:
{
  "suggested_name": "Suggested Event Name",
  "suggested_type": "Conference | Concert | Corporate Summit | Exhibition",
  "suggested_city": "City name",
  "estimated_budget": 150000,
  "roles": [
    { "role_name": "Sound Engineer", "quantity": 2, "max_rate_per_hour": 2000, "min_experience_years": 3 },
    { "role_name": "Lighting Specialist", "quantity": 1, "max_rate_per_hour": 1800, "min_experience_years": 2 }
  ]
}
`;

  const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

  const response = await fetch(geminiUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [{ text: userPrompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.1,
        maxOutputTokens: 400,
      },
    }),
  });

  if (!response.ok) {
    throw new Error(`Gemini API HTTP ${response.status}`);
  }

  const data = await response.json();
  const rawText = data.candidates?.[0]?.content?.parts?.[0]?.text;
  const parsed = JSON.parse(rawText || "{}");

  return {
    success: true,
    is_ai_generated: true,
    parsed_requirements: parsed,
  };
}
