# MUSTER — End-to-End Test Accounts & Credentials
**MIT India Hackathon 2026 | Track: PSE15**

This document details the **8 real test accounts** created for MUSTER testing and judging demonstration.

> [!IMPORTANT]
> **Universal Development Password for All Test Accounts:**
> `MusterTest@2026`

---

## 1. Account Directory & Credentials

### 🏢 Event Organizers (2 Accounts)

| Role | Name | Email | Password | Organization | Location | Key Test Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Organizer 01** | Arjun Mehta | `organizer01@muster.test` | `MusterTest@2026` | TechNova Events | Indore, MP | Owns *Indore Tech Leaders Summit 2026* (6 Applicants, ₹1,20,000 budget) |
| **Organizer 02** | Riya Kapoor | `organizer02@muster.test` | `MusterTest@2026` | NextWave Productions | Bhopal, MP | Owns *Bhopal Media & Design Conclave* (Tests RLS event isolation) |

---

### 🛠️ Freelance Specialists (6 Accounts)

| Identifier | Name | Email | Password | Primary Role | Exp (Yrs) | Rate / Shift | Rel. Score | Proximity (Indore) | Key Characteristic / Trade-Off |
| :--- | :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Freelancer 01** | Aarav Sharma | `freelancer01@muster.test` | `MusterTest@2026` | Event Operations | Senior (5) | ₹12,000 | 96% | 4.5 km | **Balanced Senior**: High reliability, local Indore presence |
| **Freelancer 02** | Ishita Verma | `freelancer02@muster.test` | `MusterTest@2026` | Hospitality | Intermediate (3) | ₹9,000 | 92% | 6.0 km | **Mid-Tier Hospitality**: Budget-conscious registration lead |
| **Freelancer 03** | Kabir Patel | `freelancer03@muster.test` | `MusterTest@2026` | AV & Tech Specialist | Senior (6) | ₹15,000 | 98% | 55.0 km | **High-Skill / Higher Rate**: Ujjain specialist with top AV skills |
| **Freelancer 04** | Ananya Joshi | `freelancer04@muster.test` | `MusterTest@2026` | Stage Coordinator | Intermediate (4) | ₹10,000 | 91% | 190.0 km | **Cross-City Talent**: Bhopal specialist exploring regional events |
| **Freelancer 05** | Rohan Singh | `freelancer05@muster.test` | `MusterTest@2026` | Crowd & Security | Senior (7) | ₹14,000 | 99% | 38.0 km | **Max Reliability Veteran**: Top 99% reliability from Dewas |
| **Freelancer 06** | Meera Shah | `freelancer06@muster.test` | `MusterTest@2026` | Registration Coord | Junior (2) | ₹7,000 | 85% | 3.0 km | **Cheapest & Closest**: 3.0 km away, trades experience for cost |

---

## 2. Multi-Constraint Matching Variations Matrix

The 6 freelancers are mathematically calibrated to test realistic trade-offs during AI matching:

```text
Best Match ≠ Cheapest Match ≠ Closest Match
```

| Candidate | Strategy Archetype | Trade-Off Rationale |
| :--- | :--- | :--- |
| **Aarav Sharma** | *Option 1: Balanced Optimal* | Optimal synergy: 96% reliability, 4.5 km distance, moderate rate. |
| **Meera Shah** | *Option 2: Budget-Optimized* | Lowest rate (₹7,000) & shortest transit (3.0 km), but Junior experience. |
| **Rohan Singh** | *Option 3: High-Reliability* | Maximum reliability (99%), 7 years experience, suited for critical security. |
| **Kabir Patel** | *Technical Excellence* | Required AV skillset, higher hourly rate, 55 km transit from Ujjain. |

---

## 3. End-to-End Test Flows

### Flow 1: Organizer 01 (Indore Tech Leaders Summit)
1. Login with `organizer01@muster.test` / `MusterTest@2026`.
2. Open **Indore Tech Leaders Summit 2026** -> Click **Applicant Pool** (6 applications visible).
3. Click **Run AI Matching** -> CP-SAT solver runs & Gemini 1.5 generates explainability rationales.
4. Cycle through **Find Another Crew** to observe Pareto trade-offs.
5. Click **Approve Crew Roster** -> Atomic PostgreSQL transaction confirms crew.

### Flow 2: Organizer 02 (RLS Data Isolation Test)
1. Login with `organizer02@muster.test` / `MusterTest@2026`.
2. Observe that **Indore Tech Leaders Summit 2026** is NOT editable by Organizer 02.
3. Organizer 02 only manages **Bhopal Media & Design Conclave**.

### Flow 3: Freelancer Bidding & Realtime QR Pass
1. Login with `freelancer01@muster.test` / `MusterTest@2026` (Aarav Sharma).
2. Open **Browse Events** -> see events sorted by proximity.
3. Open **My Applications** -> once approved by Organizer 01, status transitions to `Selected` and reveals the **Digital QR Dispatch Pass**.

---

## 4. Setup in Supabase

To load these 8 test accounts and seed applications into your live Supabase environment:
1. Open **[Supabase SQL Editor](https://app.supabase.com)** (Project `hlzcdxnigjyiwfhtwanl`).
2. Run [`SEED_TEST_ACCOUNTS.sql`](SEED_TEST_ACCOUNTS.sql).
