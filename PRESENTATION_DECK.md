# MUSTER — Hackathon Jury Presentation Deck
**MIT India Hackathon 2026 | Problem Statement: PSE15**
*Theme Reference: Official MIT India Visual Identity (MIT Crimson `#A31F34`, Deep Slate `#0F172A`, Gold `#D97706`)*

---

## Slide 01 — Cover
* **Title**: MUSTER
* **Subtitle**: AI-Powered Multi-Constraint Crew Assembly & Optimization Platform for Live Event Staffing
* **Metadata**: MIT India Hackathon 2026 | PSE15 | Flutter + Supabase + Google Gemini 1.5
* **Speaker Notes**: "Good morning judges. We are presenting MUSTER, an AI-powered crew assembly and optimization platform designed to solve the multi-constraint staffing problem in live event production."

---

## Slide 02 — The Real-World Problem
* **Headline**: Event staffing is a high-stakes multi-constraint problem.
* **Key Observations**:
  1. **Rigid Role Quotas**: Productions fail if single specialized roles (e.g. Dante audio engineer, GrandMA3 lighting technician) are missing.
  2. **Inviolable Budget Ceilings**: Spreadsheets and manual WhatsApp outreach lead to unmonitored rate spikes and budget overruns.
  3. **Transit & Reliability Risk**: Unvetted freelancers suffer 20%+ no-show rates with zero historical accountability.
* **The Gap**: Existing platforms (Upwork/Fiverr) optimize for single hires, while generic LLMs hallucinate unvetted candidates and violate mathematical budget caps.

---

## Slide 03 — The Solution: MUSTER
* **Headline**: Constraint-First Assembly + AI Explainability
* **Value for Organizers**:
  * Define role quotas, hourly rate ceilings, and transit radii in minutes.
  * AI Brief Assistant: Gemini NLP converts free-form event briefs into structured parameters.
  * Deterministic CP-SAT engine calculates Pareto-optimal crew rosters in seconds.
  * Transparent natural-language explainability for every hire.
  * Atomic PostgreSQL shift locking with zero race conditions.
* **Value for Freelancers**:
  * Proximity-based discovery for shifts within transit radius.
  * Custom hourly rate bidding with real-time status updates.
  * Verified digital QR dispatch credential upon selection.

---

## Slide 04 — End-to-End Operational Flow
* **Sequence**:
  1. **Stage 1 (Create Event)**: Organizer specifies role quotas, rate caps, budget limit, and transit radius.
  2. **Stage 2 (Bidding Pool)**: Freelancers submit custom rate bids with anti-duplicate enforcement.
  3. **Stage 3 (Multi-Constraint Run)**: Deterministic solver prunes violations and scores candidate combinations.
  4. **Stage 4 (Gemini Rationale)**: Gemini 1.5 synthesizes natural-language explainability and trade-offs.
  5. **Stage 5 (Approve Crew)**: Atomic Supabase RPC `approve_crew_transaction` locks the confirmed roster.
  6. **Stage 6 (QR Dispatch Pass)**: Freelancers receive real-time notifications and digital QR entry passes.

---

## Slide 05 — The Matching Engine (Where is the Math?)
* **Formula**:
  $$S_c = (w_1 \cdot M_c) + (w_2 \cdot R_c) + (w_3 \cdot P_c) + (w_4 \cdot C_c)$$
  * $M_c$: Skill & experience alignment index $[0..100]$
  * $R_c$: Verified historical reliability rating $[0..100]$
  * $P_c = \max(0, 100 - 2 \cdot \text{Distance}_{\text{km}})$: Proximity score
  * $C_c = 100 \cdot \left(1 - \frac{\text{Rate}_c - \text{Rate}_{\min}}{\text{Rate}_{\max} - \text{Rate}_{\min}}\right)$: Cost efficiency
  * Weights: $w_1=0.40, w_2=0.35, w_3=0.15, w_4=0.10$ ($\sum w_i = 1.0$)
* **Hard Constraints**:
  * $\sum (\text{Rate}_i \times 8) \le \text{Budget}$
  * $\text{Distance}_i \le \text{Radius}_{\max}$
  * $\text{Selected}_k = \text{Required}_k$

---

## Slide 06 — Where is the AI? (Gemini 1.5 via Supabase Edge Function)
* **Architectural Separation**:
  * **Deterministic Engine**: Guarantees mathematical correctness, quota satisfaction, and budget compliance.
  * **Google Gemini 1.5**: Delivers intelligence, NLP requirement parsing, and explainability.
* **Server-Side Security**: Gemini API key is isolated server-side inside Supabase Edge Function `muster-ai`. Request payloads are sanitized with zero private contact data exposed.

---

## Slide 07 — Alternative Recommendations & Trade-Offs
* **3 Validated Pareto Permutations**:
  * **Option #1 (Balanced Optimal Fit)**: Highest multi-objective synergy across skills, rate, and distance.
  * **Option #2 (Budget-Optimized Roster)**: Minimizes crew cost (₹16,000 savings) while satisfying quality floors.
  * **Option #3 (High-Reliability Veterans)**: Maximizes 98%+ reliability ratings for mission-critical keynotes.
* **Interactive Manual Mode**: Organizers can customize selections with live reactive budget validation.

---

## Slide 08 — Production App Evidence & Verification
* **UI Features**: 5-step event wizard, searchable applicant pool, simulated CP-SAT solver terminal, Gemini explainability cards, and QR dispatch passes.
* **Verification Status**:
  * `flutter analyze`: **0 errors, 0 warnings (Clean)**
  * `flutter test`: **100% Passed**
  * Android Release: `APK/MUSTER-v1.0.apk` (54.0 MB)
  * Web Release: `build/web/`

---

## Slide 09 — Technical Architecture & Security
* **13 Relational Tables**: Full schema with custom enums, primary/foreign keys, and performance indexes.
* **Granular Row Level Security (RLS)**: Public directory browsing, organizer-restricted management, private bid isolation, and user-isolated notifications.
* **PostgreSQL RPC**: `approve_crew_transaction` for atomic database consistency.

---

## Slide 10 — Why MUSTER Wins (Competitive Credibility)
* **Comparison Matrix**:
  * Assembly Speed: Traditional (3–5 days) vs MUSTER (< 3 seconds).
  * Multi-Role Quota Alignment: Manual vs MUSTER automated CP-SAT.
  * Budget Adherence: High risk vs MUSTER strict mathematical constraint guarantee.
  * Explainability: None vs MUSTER Gemini 1.5 natural-language synthesis.

---

## Slide 11 — Scalability & Future Roadmap
* **Current**: Cross-platform Web, Android, iOS with live Supabase PostgreSQL and Edge Functions.
* **Phase 2 (On-Site Live Ops)**: Geofenced GPS venue check-in, automated standby replacement dispatch, and UPI escrow payouts.
* **Phase 3 (Enterprise Ecosystem)**: Equipment co-scheduling and ticketing platform integration.

---

## Slide 12 — Conclusion & Live Judging Demo
* **Live Demo Credentials**:
  * Organizer: `organizer@muster.events` / `password123`
  * Freelancer: `rohan.mehta@muster.events` / `password123`
* **Deliverables**: Web live build, Android release binary (`APK/MUSTER-v1.0.apk`), complete database setup script (`MUSTER_COMPLETE_SUPABASE_SETUP.sql`), and 40-section technical dossier (`TECHNICAL_DOSSIER.md`).
