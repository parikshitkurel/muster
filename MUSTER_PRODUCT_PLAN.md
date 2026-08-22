# MUSTER — Master Product Architecture & Implementation Plan
**Phase 2: Connecting Organizer & Freelancer Workflows via Joint Multi-Constraint Optimization**
**MIT INDIA HACKATHON 2026 • PSE15 — AI-POWERED CREW ASSEMBLY FOR EVENT STAFFING**

> **Tagline:** Build the right team. Run the better event.  
> **Core Engineering Insight:** *"We don't optimize candidates. We optimize the crew."*

---

## SECTION 1 — CURRENT PRODUCT AUDIT

### 1.1 Existing Flow Audit
- **Flow 1 (Freelancer Registration):** Freelancers register, select skills, set location/hourly rates, upload verification credentials, and complete a profile.
- **Flow 2 (Event Organizer Setup):** Organizers create events, specify budget ceilings, list headcount requirements per department, run optimization, and view assigned primary crew + ranked backups.

### 1.2 Identified Gaps & Disconnections
1. **Disconnected Data Loop:** Freelancers who register do not automatically populate the active organizer candidate pool unless linked via a unified Supabase schema.
2. **Opportunity Visibility:** Freelancers cannot currently view incoming assignment requests, accept/decline shift invitations, or set live calendar availability.
3. **No-Show Detection & Real-Time Event Day:** The gap between initial crew confirmation and event-day check-in is unmonitored; last-minute dropouts require manual organizer initiation rather than automatic system detection.
4. **Static Reliability Scores:** Reliability is hardcoded in mock profiles rather than dynamically derived from verified event completion histories.

### 1.3 Dependency & Data Flow Map

```
FREELANCER PROFILE                ORGANIZER EVENT                 OPTIMIZATION ENGINE
• Skill Tags                 • Headcount Quotas             • Hard Constraints
• Hourly Rate          ──>   • Budget Ceiling         ──>   • Soft Objectives
• Distance Radius            • Shift Schedule               • CP-SAT Solver Pass
• Reliability Score          • Skill Requirements                     │
                                                                       ▼
EVENT-DAY MONITOR                ASSIGNMENT MATRIX               OUTPUT ASSEMBLY
• Geofenced Check-in   <──   • Primary Assigned Crew   <──   • Optimal Crew (Score)
• Backup Promotion           • Ranked Backups (k=3)         • Natural Language Notes
```

---

## SECTION 2 — PRODUCT ARCHITECTURE

### 2.1 System Functional Domains

| Domain | Description | Phase Classification |
| :--- | :--- | :--- |
| **1. Authentication** | Multi-tenant auth for Organizers & Freelancers via Supabase Auth & JWT. | **CORE MVP** |
| **2. Organizer Hub** | Multi-event management dashboard, budget tracking, workspace configuration. | **CORE MVP** |
| **3. Freelancer Hub** | Profile management, skill tagging, rate setting, shift calendar. | **CORE MVP** |
| **4. Events Engine** | Event parameters (Date, Duration, Location, Budget, Attendance). | **CORE MVP** |
| **5. Crew Profiles** | Standardized candidate data structure, verified experience, ratings. | **CORE MVP** |
| **6. Requirements** | Headcount, mandatory skill matrices, maximum hourly rate, shift hours. | **CORE MVP** |
| **7. Optimization** | Google OR-Tools CP-SAT multi-constraint solver engine. | **CORE MVP** |
| **8. Matching Engine** | Candidate-role compatibility scoring matrix. | **CORE MVP** |
| **9. Assignments** | Confirmed primary crew matrix, status tracking, contract lock. | **CORE MVP** |
| **10. Backup System** | Pre-calculated $k=3$ ranked backup fallbacks per role with 1-click promotion. | **CORE MVP** |
| **11. Event-Day Ops** | Real-time staffing health monitor, check-in tracking, gap alerts. | **CORE MVP** |
| **12. Communication** | Automated shift confirmation notifications (In-app / SMS / WhatsApp). | **SECONDARY** |
| **13. Notifications** | Instant assignment push alerts & backup standby notifications. | **SECONDARY** |
| **14. Payments** | Escrow budget allocation & shift payout verification. | **STRETCH / FUTURE** |
| **15. Reviews** | Two-sided rating system (Organizer $\leftrightarrow$ Freelancer). | **SECONDARY** |
| **16. Reliability** | System-generated historical reliability index calculation engine. | **CORE MVP** |
| **17. Analytics** | Post-event budget efficiency, skill utilization, crew satisfaction. | **SECONDARY** |
| **18. History** | Historical event collaboration graph feeding future optimization passes. | **CORE MVP** |

---

## SECTION 3 — CORE OPTIMIZATION LOOP

```
                         CREW ASSEMBLY PIPELINE
                                   │
                           EVENT REQUIREMENTS
                                   │
                                   ▼
                            CREW POOL DATA
                                   │
                                   ▼
                           ELIGIBILITY FILTER
                (Skill Subsets, Availability, Geography)
                                   │
                                   ▼
                            HARD CONSTRAINTS
              (Headcount Equality, Budget Ceiling, Non-Overlap)
                                   │
                                   ▼
                           CANDIDATE SCORING
               (Skill Fit + Reliability + Proximity + Synergy)
                                   │
                                   ▼
                    OR-TOOLS CP-SAT JOINT SOLVER
                                   │
          ┌────────────────────────┴────────────────────────┐
          ▼                                                 ▼
    OPTIMAL CREW                                     RANKED BACKUPS
  (Primary Matrix)                                 (k=3 Fallback Pool)
          │                                                 │
          └────────────────────────┬────────────────────────┘
                                   ▼
                      NATURAL LANGUAGE EXPLANATION
```

### Stage-by-Stage Breakdown
1. **Event Requirements:** Organizer defines roles, quantities, mandatory skills, shifts, and budget ceiling.
2. **Crew Pool:** Query active, verified freelancers within geographic travel radius.
3. **Eligibility Filter:** Hard boolean filtering of candidates lacking required skills or marked unavailable.
4. **Hard Constraints:** Formulate mathematical equations in Google OR-Tools CP-SAT enforcing exact headcount, non-overlapping shift schedules, and strict budget caps.
5. **Candidate Scoring:** Calculate composite candidate-role score matrix ($S_{i,j}$) combining skill fit, historical reliability score, proximity distance, and past collaboration history.
6. **Joint Optimization:** CP-SAT solver optimizes the complete binary decision matrix $X_{i,j} \in \{0, 1\}$ simultaneously to maximize overall crew quality.
7. **Optimal Crew:** Returns the primary crew assignment satisfying 100% of hard constraints.
8. **Ranked Backups:** Generates $k=3$ standby candidate fallbacks per role by executing bounded sub-optimization passes.
9. **Explanations:** Generates human-readable text explaining why each candidate was selected.

---

## SECTION 4 — DATA MODEL

```sql
-- MUSTER Core Relational Schema
Organization (id, name, created_at)
User (id, auth_uid, org_id, email, role, full_name)
Event (id, org_id, name, event_date, location, budget_ceiling, status)
EventRequirement (id, event_id, role_name, headcount, max_hourly_rate, shift_name)
Skill (id, name, category)
RequirementSkill (requirement_id, skill_id)
CrewMember (id, user_id, org_id, full_name, primary_role, reliability_score, hourly_rate, location, is_available)
CrewSkill (crew_member_id, skill_id)
OptimizationRun (id, event_id, overall_crew_score, budget_used, solve_duration_ms, status)
Assignment (id, optimization_run_id, event_id, requirement_id, crew_member_id, status, composite_score, explanation)
BackupCandidate (id, assignment_id, crew_member_id, rank_order, composite_score, status)
EventHistory (id, event_id, crew_member_id, checked_in, on_time, completed, rating)
```

| Entity | Key Fields | Data Source | Optimization Impact |
| :--- | :--- | :--- | :--- |
| **Organization** | `id`, `name` | User-entered | Multi-tenant isolation boundary |
| **Event** | `budget_ceiling`, `location`, `event_date` | User-entered | Budget cap hard constraint ($B_{\text{event}}$) |
| **EventRequirement** | `role_name`, `headcount`, `shift_name` | User-entered | Headcount equality hard constraint ($\sum X_{i,j} = N_j$) |
| **CrewMember** | `reliability_score`, `hourly_rate`, `distance_km` | System / User | Cost matrix ($C_i$) & Soft objective weight |
| **Skill** | `name`, `category` | System Directory | Mandatory skill eligibility filter |
| **Assignment** | `composite_score`, `status`, `explanation` | System-generated | Final decision matrix output ($X_{i,j}=1$) |
| **BackupCandidate** | `rank_order`, `status` | System-generated | Standby fallback hierarchy ($k=3$) |
| **EventHistory** | `checked_in`, `on_time`, `completed` | System-generated | Updates candidate reliability score |

---

## SECTION 5 — OPTIMIZATION MODEL (OR-TOOLS CP-SAT)

### 5.1 Hard Constraints (Mathematical Equations)

1. **Headcount Equality Constraint:**
   $$\sum_{i=1}^{M} X_{i,j} = N_j \quad \forall j \in \{1, \dots, R\}$$
   *Every role requirement $j$ must receive exactly $N_j$ primary assigned crew members.*

2. **Single Role Assignment Constraint:**
   $$\sum_{j=1}^{R} X_{i,j} \le 1 \quad \forall i \in \{1, \dots, M\}$$
   *No candidate $i$ can be assigned to more than one role in the same shift window.*

3. **Mandatory Skill Subset Constraint:**
   $$X_{i,j} = 0 \quad \text{if } \mathcal{S}_{\text{req}, j} \not\subseteq \mathcal{S}_{\text{cand}, i}$$
   *Candidate $i$ must possess 100% of mandatory required skills for role $j$.*

4. **Budget Ceiling Constraint:**
   $$\sum_{i=1}^{M} \sum_{j=1}^{R} (C_i \cdot X_{i,j}) \le B_{\text{event}}$$
   *Total crew cost cannot exceed the organizer's specified budget ceiling.*

### 5.2 Soft Multi-Objective Optimization
$$\text{Maximize } \mathcal{Z} = \sum_{i=1}^{M} \sum_{j=1}^{R} \left( w_1 \cdot \text{SkillFit}_{i,j} + w_2 \cdot \text{Reliability}_i + w_3 \cdot \text{Proximity}_i + w_4 \cdot \text{Synergy}_{i} \right) \cdot X_{i,j}$$
*Weights: $w_1 = 0.40$, $w_2 = 0.30$, $w_3 = 0.20$, $w_4 = 0.10$.*

### 5.3 Role of LLM vs CP-SAT
- **Google OR-Tools CP-SAT:** Responsible 100% for mathematical constraint solving, crew selection, budget capping, and backup ranking.
- **LLM API (Optional Assistant):** Responsible solely for natural language parsing of event briefs and generating human-readable explainability summaries (*"Why Selected?"*).

---

## SECTION 6 — MATCHING VS OPTIMIZATION

```
NAIVE MATCHING (Filtering Candidates)
[Candidate Database] ──> [Filter Skills] ──> [Sort by Individual Rating] ──> [Pick Top Candidates One-by-One]
❌ FAILURE MODE: Early top picks exhaust 80% of budget; lower roles fail; schedule overlaps ignored!

MUSTER CREW OPTIMIZATION (Joint CP-SAT Matrix Solution)
[Requirements + Pool] ──> [Hard Constraints + Cost Bounds] ──> [OR-Tools CP-SAT Solver] ──> [Global Optimal Matrix]
✅ SUCCESS MODE: Optimizes total crew quality, guarantees 100% budget compliance, generates ranked backups!
```

---

## SECTION 7 — OPTIMIZATION RESULT EXPERIENCE

When the organizer clicks **"BUILD MY CREW"**:
1. **Processing Screen:** Animated solver progress indicator displaying live constraint evaluation.
2. **Executive Metrics Banner:**
   - **Overall Crew Score:** e.g., **93 / 100**
   - **Budget Utilization:** ₹88,500 / ₹1,00,000 (11.5% Under Budget)
   - **Skill Match Coverage:** 100%
   - **Reliability Index:** 92%
3. **Crew Assignment Cards:**
   - Member Name & Assigned Role
   - Individual Match Score (e.g., 95%)
   - Skill Match Breakdown & Rate
   - **Explainability Note:** *"Selected for Technical Lead due to 98% AV routing fit, verified 96% reliability score, and 4 km proximity within budget ceiling."*

---

## SECTION 8 — RANKED BACKUP SYSTEM & DYNAMIC REPLACEMENT

### 8.1 Standby Backup Hierarchy per Role
```
PRIMARY ASSIGNMENT: Candidate A (Score: 95) [CONFIRMED]
  ├── RANKED BACKUP #1: Candidate B (Score: 92) [STANDBY READY - 1-Click Promote]
  ├── RANKED BACKUP #2: Candidate C (Score: 88) [STANDBY READY]
  └── RANKED BACKUP #3: Candidate D (Score: 84) [STANDBY READY]
```

### 8.2 Dynamic Replacement Workflow
1. Candidate A cancels or is marked no-show on event day.
2. MUSTER flags staffing gap immediately.
3. System fetches pre-calculated Backup #1 (Candidate B), verifying zero constraint violations.
4. Organizer sees: Candidate B details, match score (92%), distance (8 km), reliability (92%), and rate.
5. Organizer clicks **"ACTIVATE BACKUP"** $\rightarrow$ Candidate B promoted instantly to primary assignment.

---

## SECTION 9 — FREELANCER SIDE EXPERIENCE

1. **Freelancer Dashboard:** Upcoming confirmed shifts, invitation requests, total earnings, reliability score badge.
2. **Opportunities Feed:** Relevant event staffing requests matching freelancer role & location.
3. **Shift Acceptance:** Freelancer views event date, location, rate, duration, and role details $\rightarrow$ Clicks **"ACCEPT SHIFT"** or **"DECLINE"**.
4. **Shift Brief & Check-in:** Event day navigation map, shift timing countdown, 1-tap geofenced check-in button.

---

## SECTION 10 — ORGANIZER EVENT MANAGEMENT

| Capability | Scope Level | Operational Description |
| :--- | :--- | :--- |
| **Event Dashboard** | **MVP (P0)** | Real-time staffing fill rate, budget meter, role status. |
| **Shift Assignment List** | **MVP (P0)** | Primary crew roster, shift times, contact cards. |
| **1-Click Replacement** | **MVP (P0)** | Instant backup promotion when candidate drops out. |
| **Real-Time Check-In** | **MVP (P0)** | Attendance monitoring (Checked in / Pending / No-show). |
| **Shift Payout Escrow** | **FUTURE (P2)** | Automated payment release upon shift completion. |

---

## SECTION 11 — EVENT-DAY OPERATIONS MONITOR

```
+-----------------------------------------------------------------------------------+
| TECHNOVA CONFERENCE 2026 — LIVE EVENT OPERATIONS CENTER                           |
+-----------------------------------------------------------------------------------+
| STAFFING STATUS: 23/23 Filled  | CHECKED IN: 21  | RUNNING LATE: 1  | NO-SHOW: 1    |
+-----------------------------------------------------------------------------------+
| [ALERT] Security Role Gap: Candidate X marked No-Show!                            |
| RECOMMENDED BACKUP: Candidate Y (Score 91 | 6 km away | Standby Ready)            |
| ACTION: [ACTIVATE BACKUP #1 NOW]                                                  |
+-----------------------------------------------------------------------------------+
```

---

## SECTION 12 — RELIABILITY SYSTEM

### System-Generated Reliability Formula
$$\text{Reliability Index} = 0.40(\text{Attendance Rate}) + 0.30(\text{Punctuality Score}) + 0.20(\text{Completion Rate}) + 0.10(\text{Organizer Rating})$$

- **Rules:** Freelancers **cannot** manually edit their reliability score.
- Scores start at a baseline of **85%** for verified new profiles and update automatically after every completed event.

---

## SECTION 13 — THE LEARNING LOOP

```
EVENT ASSIGNMENT ──> SHIFT COMPLETION ──> ORGANIZER REVIEW ──> RELIABILITY UPDATE ──> FUTURE SOLVER PASS
```
1. Completed shifts update candidate attendance & rating records.
2. Successful past team collaborations increase team synergy bonus scores in future CP-SAT runs.

---

## SECTION 14 — COMPLETE SCREEN INVENTORY

| Screen Name | User | Purpose | Priority |
| :--- | :--- | :--- | :--- |
| `SCR-01 Login / Auth` | Both | Email/password & social auth | **P0 (MVP)** |
| `SCR-02 Organizer Dashboard` | Organizer | Workspace metrics, upcoming events, crew status | **P0 (MVP)** |
| `SCR-03 Create Event` | Organizer | Set event parameters, date, location, budget ceiling | **P0 (MVP)** |
| `SCR-04 Staffing Requirements` | Organizer | Define roles, headcounts, skill tags, shift times | **P0 (MVP)** |
| `SCR-05 Crew Pool Directory` | Both | Searchable candidate database with profiles & skills | **P0 (MVP)** |
| `SCR-06 Optimization Control` | Organizer | Set constraints & trigger OR-Tools CP-SAT solver | **P0 (MVP)** |
| `SCR-07 Optimal Crew Results` | Organizer | Display assigned crew, score 93/100, explainability | **P0 (MVP)** |
| `SCR-08 Ranked Backups Board` | Organizer | Display Primary vs Backup #1 / #2 hierarchy | **P0 (MVP)** |
| `SCR-09 Assignment Management` | Organizer | Operational roster with 1-click dynamic replacement | **P0 (MVP)** |
| `SCR-10 Event-Day Ops Center` | Organizer | Live check-in tracker & no-show alert replacement | **P0 (MVP)** |
| `SCR-11 Freelancer Dashboard` | Freelancer | Shift invitations, upcoming schedules, reliability | **P0 (MVP)** |
| `SCR-12 Opportunity Detail` | Freelancer | Review shift details, rate, role & accept/decline | **P0 (MVP)** |
| `SCR-13 Event Analytics` | Organizer | Post-event budget & crew performance report | **P1 (Secondary)** |

---

## SECTION 15 — FIGMA / STITCH DESIGN PLAN

### Recommended Next Screen Design Sequence
1. **Screen 06 — Optimization Control Center & Live Processing**
2. **Screen 07 — Optimal Crew Results & Explainability Cards**
3. **Screen 08 — Ranked Backups Hierarchy Matrix**
4. **Screen 09 — Assignment Board & 1-Click Replace Modal**
5. **Screen 11 — Freelancer Dashboard & Shift Acceptance View**
6. **Screen 10 — Event-Day Operations Center**

---

## SECTION 16 — TECHNICAL IMPLEMENTATION & STACK MAPPING

```
FRONTEND: Flutter (Dart) + Riverpod + GoRouter + Material 3
BACKEND: Python 3.11 + FastAPI Async REST Services
DATABASE: Supabase PostgreSQL + Auth + Row Level Security (RLS)
OPTIMIZER: Google OR-Tools CP-SAT Multi-Constraint Solver
```

| Component | Hackathon Implementation Strategy |
| :--- | :--- |
| **OR-Tools CP-SAT** | **REAL**: Execute genuine Python CP-SAT solver for 30+ candidate matrix. |
| **FastAPI REST API** | **REAL**: Functional REST endpoints (`/api/optimization/run`, `/api/assignments/replace`). |
| **Supabase PostgreSQL** | **REAL / HYBRID**: Seeded PostgreSQL schema + in-memory fallback repository. |
| **Flutter Web Shell** | **REAL**: Material 3 web app with anti-ai editorial design system. |
| **scikit-learn / Maps** | **STRETCH**: Mocked distance matrix & predictive no-show models for hackathon MVP. |

---

## SECTION 17 — MVP DEFINITION FOR PSE15 EVALUATION

The MUSTER Hackathon MVP is 100% complete when a judge can:
1. Log in as an Organizer.
2. Select **TechNova Conference 2026** (₹1,00,000 Budget, 23 Crew Required).
3. View the 30-candidate Crew Pool.
4. Click **"RUN OPTIMIZATION ENGINE"** and observe the OR-Tools CP-SAT solver execute in **< 200ms**.
5. Inspect the **93/100 Overall Crew Quality Score** & explainability notes.
6. Inspect the **Ranked Backup Hierarchy (Backup #1 & #2)**.
7. Click **"Replace Candidate"** on an assignment and watch Backup #1 dynamically promote to primary status in real time.

---

## SECTION 18 — 3-MINUTE HACKATHON PITCH & DEMO NARRATIVE

- **0:00 - 0:30 (The Problem):** *"Event staffing is an NP-hard multi-constraint puzzle. Picking individual candidates leads to budget collapse and no-shows."*
- **0:30 - 1:15 (The Core Insight):** *"We don't optimize candidates. We optimize the crew. Presenting MUSTER."*
- **1:15 - 2:15 (Live Optimization Demo):** Show TechNova Conference 2026 setup $\rightarrow$ Click **"RUN OPTIMIZATION"** $\rightarrow$ Highlight OR-Tools CP-SAT solving 23 roles across 30 candidates in **142ms** with a **93/100 Quality Score** under ₹1,00,000 budget cap.
- **2:15 - 2:45 (No-Show Resilience Demo):** Demonstrate a candidate dropping out $\rightarrow$ Click **"Replace Candidate"** $\rightarrow$ Show 1-click dynamic backup promotion.
- **2:45 - 3:00 (Closing):** *"MUSTER — Build the right team. Run the better event."*

---

## SECTION 19 — DEVELOPMENT ROADMAP

```
PHASE A: Foundation (Supabase DB, RLS, Flutter Shell) ────────> COMPLETED
PHASE B: Organizer Workflow (Event Setup, Requirements) ──────> COMPLETED
PHASE C: Optimization Core (OR-Tools CP-SAT Solver) ───────────> COMPLETED
PHASE D: Two-Sided Integration (Freelancer Sync & Accept) ────> CURRENT NEXT
PHASE E: Event-Day Ops (Check-in Tracker & Replacement) ──────> NEXT
PHASE F: Polish & Pitch Validation ───────────────────────────> FINAL SPRINT
```

---

## SECTION 20 — TEAM PARALLELIZATION & OWNERSHIP MATRIX

```
PARIKSHIT KUREL (Product & Tech Lead)
├── CP-SAT Solver Formulation & OR-Tools Optimization
└── System Architecture & Presentation Strategy

NAMAN PATEL (Backend & Data Engineer)
├── FastAPI REST Services & Async Endpoints
└── Supabase PostgreSQL Schema & RLS Security Policies

VAISHNAVI SOLANKI (Frontend & UX Engineer)
├── Flutter Web Operations Shell & Material 3 UI
└── Interactive Assignment Board & Backup Replace Modals

AYUSH SHARMA (AI/ML & QA Engineer)
├── Data Pipeline Indexing & Solver Test Bench
└── Reliability Scoring Model & Demo Dataset Verification
```

---

## SECTION 21 — RISK ASSESSMENT & MITIGATION

| Risk Factor | Severity | Impact | Mitigation Strategy |
| :--- | :---: | :---: | :--- |
| **CP-SAT Solver Timeout** | High | Solver hangs on large candidate pools | Set strict `max_time_in_seconds = 2.0` parameter in OR-Tools. |
| **Infeasible Hard Constraints** | High | Budget cap too low for required headcount | Return clear `INFEASIBLE` status with budget adjustment suggestions. |
| **Network Disconnection** | Med | API failure during pitch demo | Include local in-memory fallback DB repository in FastAPI server. |
| **Data Leakage Between Orgs** | High | Workspace data crossover | Enforce PostgreSQL Row Level Security (RLS) policies on `org_id`. |

---

## SECTION 22 — FINAL ARCHITECTURAL RECOMMENDATIONS

### 1. What to Build NEXT (Immediate Priority)
- Connect the **Freelancer Opportunity Acceptance View** to the active Supabase assignments table so freelancers can accept shift invitations in real time.
- Implement the **Real-Time Check-In Monitor** on the Event-Day Operations Center screen.

### 2. What NOT to Build Yet (Avoid Feature Creep)
- Do **NOT** build custom payment gateway integrations or real money escrow services.
- Do **NOT** attempt custom LLM fine-tuning or deep neural network training.

### 3. Immediate Database Schema Migrations
- Execute `schema.sql` on Supabase PostgreSQL to create `organizations`, `users`, `events`, `crew_members`, `assignments`, and `backup_candidates` with Row Level Security.

### 4. Core Pitch Message
> **"WE DON'T OPTIMIZE CANDIDATES. WE OPTIMIZE THE CREW."**  
> **MUSTER — Build the right team. Run the better event.**
