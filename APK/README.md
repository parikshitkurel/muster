# MUSTER — Android Mobile Application Packages (APKs)
**MIT India Hackathon 2026 • Official Prototype Build**
**Track / Problem Statement:** PSE15 — AI-Powered Crew Assembly for Event Staffing

---

## 📱 Generated APK Packages

All build artifacts have been compiled, verified, and placed in this directory:

| Filename | Build Type | File Size | Recommended Use Case |
| :--- | :--- | :--- | :--- |
| **`MUSTER-v1.0.apk`** | **Release (Signed)** | **48.7 MB** | **Official Hackathon Demo / Judge Device Sideloading** |
| **`muster-prototype-release.apk`** | **Release (Signed)** | **48.7 MB** | Production deployment & testing |
| **`muster-prototype-debug.apk`** | **Debug** | **141.8 MB** | Developer debugging with hot-reload & logging symbols |

---

## 🚀 How to Install and Run on Android

### Option A: Via ADB (Command Line)
Connect your Android phone via USB (with USB Debugging enabled) or start an Android Emulator, then run:
```bash
adb install APK/MUSTER-v1.0.apk
```

### Option B: Direct Sideloading onto Physical Phone
1. Transfer `MUSTER-v1.0.apk` to your phone via USB, Google Drive, WhatsApp, or local download.
2. Tap the `.apk` file in your phone's File Manager / Downloads.
3. If prompted, allow *"Install from unknown sources"*.
4. Tap **Install** and open **MUSTER**.

---

## ✨ Features Included in the Mobile App

The mobile application is a complete, native Android implementation of the **MUSTER AI Workforce Optimization Platform**:

1. **Operations Dashboard**:
   - Active event workspace: *TechNova Conference 2026* (Ujjain Convention Center).
   - Real-time KPI cards: 23 Required Crew, 30 Candidate Pool, ₹1,00,000 Budget Ceiling, 93/100 Crew Quality Index.
   - Quick action shortcuts to solver and live shift rosters.

2. **Event & Requirements Definition**:
   - Event metadata configurator (Venue, Budget ceiling, Footfall).
   - Staffing quotas across 6 departments (Photography, Videography, Tech Support, Security, Hospitality, Media).
   - Interactive dialog to dynamically add new roles and mandatory skills.

3. **Candidate Crew Pool (30 Pre-Seeded Candidates)**:
   - Search bar filtering by candidate name, role, or specific skills.
   - Department filter chips.
   - Comprehensive profile cards displaying **Reliability Score %**, **Geo-Proximity (km)**, **Hourly Rate (₹/hr)**, **Rating (★)**, **Past Event History**, and **Skill Badges**.

4. **Multi-Constraint CP-SAT Optimization Solver**:
   - Mathematical formulation enforcement: Hard headcount equality, Shift non-overlap, Mandatory skill tags, Budget bound ceiling (≤ ₹1,00,000), and Multi-objective weights.
   - Live interactive solver execution with simulated terminal log stream.
   - Optimal feasible solution confirmation in < 200ms with instant navigation to the Optimal Roster.

5. **Optimal Crew Allocation & AI Explainability**:
   - 23/23 confirmed crew allocations.
   - Detailed rationale per candidate explaining why the AI selected them (Skill Match %, Reliability %, Proximity, Budget fit).

6. **Ranked Backups Matrix ($k=2$ Standby Redundancy)**:
   - Department-wise Primary vs Standby Backup #1 vs Standby Backup #2.
   - Live standby readiness chips ensuring zero single points of failure.

7. **Live Shift Assignments & 1-Click Dynamic Backup Replacement**:
   - Shift timeline roster (Morning Shift A, Evening Shift B, Full Day Leads).
   - **Interactive 1-Click Dynamic Replace**: Tap any staff member to simulate an incident/no-show.
   - Intelligent bottom-sheet modal shows the top-ranked standby candidate, calculates delta cost & skill fit, and provides **1-Tap Dynamic Swap**.
   - Live roster state updates instantly with audit trail feedback!

8. **Operations & Financial Health Overview**:
   - Budget utilization visualizer (₹88,500 / ₹1,00,000 - 11.5% contingency savings).
   - Crew readiness (100%), Redundancy ($k=2$), and Shift distribution breakdown.

9. **Freelancer Registration Portal (Mobile Onboarding Flow)**:
   - 3-Step interactive onboarding flow for gig workers: Personal details, verified competencies & equipment tags, and hourly rate quote.
   - On submission, dynamically injects the new applicant into the live Crew Pool!

---

## 🛠️ Technical Specifications
- **Framework:** Flutter 3.44.1 (Channel stable) • Dart 3.12.1
- **UI Architecture:** Material 3 with MUSTER Warm Editorial Design System
- **Min Android SDK:** API 21 (Android 5.0 Lollipop)
- **Target Android SDK:** API 34+ (Android 14 / 15)
- **Engine Support:** ARM64-v8a, ARMv7, x86_64
