# MUSTER — Hackathon Jury Presentation Deck
**MIT India Hackathon 2026 • Problem Statement: PSE15**
*Visual Identity: MIT India Hackathon 2026 (MIT Crimson `#A31F34`, Warm Slate `#0F172A`, Amber Gold `#D97706`, Clean Canvas `#F8FAFC`)*

---

## Slide 01 — Cover

# MUSTER
### AI-Powered Crew Assembly for Event Staffing

**MIT India Hackathon 2026 · Problem Statement: PSE15**

> *Speaker note: "Good morning judges. We built MUSTER — an AI-powered platform that helps event organizers assemble the right on-ground crew within real-world constraints."*

---

## Slide 02 — The Problem

# Finding a crew is harder than it looks.

```text
Skills
Budget
Availability
Location
Experience
      │
      ▼
   One Crew
```

**Organizers have to balance all of these at once.**

* Every live event has strict role requirements (sound engineers, stage coordinators, registration leads).
* A single missing person or budget overrun puts the entire event at risk.

---

## Slide 03 — Why Current Methods Are Slow

```text
WhatsApp Chats
      +
Spreadsheets
      +
Phone Calls
      +
Manual Comparison
```

# Too much manual work.

* When organizers hire manually across fragmented chats, it takes days.
* It is difficult to track who is available, compare rates fairly, and stay under budget.

---

## Slide 04 — Our Solution

# Meet MUSTER.

> **MUSTER helps organizers find and assemble the right crew for an event.**

* **For Organizers:** Post an event brief, receive applicant bids, find the best crew options in seconds, and review plain-English AI explanations.
* **For Freelancers:** Discover nearby events within transit radius, submit custom hourly rates, and receive verified digital entry passes.

---

## Slide 05 — How It Works

```text
Create Event
     │
     ▼
Freelancers Apply
     │
     ▼
Compare Applicants
     │
     ▼
Find Best Crew
     │
     ▼
Organizer Approves
```

**A clear step-by-step path from an open brief to confirmed on-site staff.**

---

## Slide 06 — What MUSTER Looks At

# The cheapest person isn't always the best fit.

```text
• Skills & Roles
• Total Budget
• Calendar Availability
• Proximity & Travel Distance
• Historical Reliability Score
• Role Compatibility
• Priority Quotas
```

**MUSTER balances these factors together.**

* The engine weighs skills (40%), verified reliability (35%), travel distance (15%), and rate efficiency (10%).

---

## Slide 07 — Where AI Fits

# AI helps. The system checks.

```text
Applicants
    │
    ▼
Matching Engine ──► Validates hard rules (Budget, Quota, Distance)
    │
    ▼
Valid Crew Options
    │
    ▼
Google Gemini ────► Synthesizes natural-language explanation
    │
    ▼
Clear Explanation for the Organizer
```

> **The matching engine checks the rules. Gemini explains the result.**

* Gemini does not guess or hallucinate crew members.
* The deterministic matching engine guarantees that budget caps and role counts are never violated.
* Gemini provides transparent reasons for each recommendation.

---

## Slide 08 — Budget

# The crew must fit the budget.

```text
Event Budget: ₹1,00,000

Crew Option A:
• Total Cost: ₹94,000
• Overall Match: 92%
• Remaining Budget: ₹6,000
```

### [ Find Another Crew ]

**Organizers can compare different valid crews before deciding.**

* **Balanced Fit:** Highest overall score across skills, reliability, and cost.
* **Cost Saver:** Maximum budget savings while meeting all role requirements.
* **High Reliability:** Prioritizes top-rated crew members for high-stakes keynotes.

---

## Slide 09 — Product Demo

# From brief to confirmed crew.

```text
1. Create Event  ──►  2. Applicants Pool  ──►  3. AI Optimizer  ──►  4. Final Crew
```

* **Live Evidence:**
  * **Organizer Dashboard:** Active events, applicant counters, and budget tracking.
  * **Applicant Pool:** Filter by role, sort by match score, hourly rate, or distance.
  * **AI Optimizer Terminal:** Constraint-checked roster permutations with Gemini explanations.
  * **Confirmed Roster:** Locked shifts and automated notifications with QR dispatch passes.

---

## Slide 10 — Tech Stack

# Built for Web, Android and iOS.

```text
Flutter (Web, Android, iOS)
         │
      Riverpod (State Management)
         │
      Supabase (Auth & Realtime)
         │
   PostgreSQL Database (RLS & Atomic Transactions)
         │
    Supabase Edge Functions (Deno)
         │
   Google Gemini API (NLP & Explainability)
```

* One unified codebase in Flutter.
* Realtime updates for live shift confirmations and notifications.
* Gemini API key securely kept server-side inside Supabase Edge Functions.

---

## Slide 11 — Why MUSTER

### Constraint-aware
Works within real event requirements, strict budgets, and role quotas.

### Explainable
Shows plain-language reasons why each crew member was selected.

### Human-controlled
AI recommends. The organizer decides and approves.

### Cross-platform
One clean application running across Web, Android, and iOS.

---

## Slide 12 — Closing

# From applicants
# to the right crew.

**MUSTER**  
AI-Powered Crew Assembly for Event Staffing

MIT India Hackathon 2026 · Problem Statement: PSE15
