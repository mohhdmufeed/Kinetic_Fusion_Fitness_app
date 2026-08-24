# Kinetic Fusion

<p align="center">
  <img src="https://raw.githubusercontent.com/wger-project/wger/master/wger/core/static/images/logos/logo.png" width="100" height="100" alt="Kinetic Fusion Logo">
</p>

<p align="center">
  <strong>Local-First Personal Fitness Intelligence System & Robust Backend Engine</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Django-6.0-092E20?logo=django" alt="Django">
  <img src="https://img.shields.io/badge/Database-SQLite%20%7C%20PostgreSQL-336791?logo=postgresql" alt="Database">
  <img src="https://img.shields.io/badge/Architecture-Local--First-orange" alt="Local First">
  <img src="https://img.shields.io/badge/Tests-167%20Passing-brightgreen" alt="Tests">
</p>

---

## ⚡ Overview

**Kinetic Fusion** is a personal fitness intelligence system engineered with a strict **local-first** architecture. Rather than acting as a passive log, Kinetic Fusion functions as a **decision and autoregulation engine** that transforms personal recovery, sleep, strain, and workout telemetry into actionable recommendations.

### Key Pillars:
- 🧠 **Applied Intelligence & Autoregulation**: ACWR (Acute:Chronic Workload Ratio) modeling, recovery index estimation, and dynamic intra-workout double progression.
- 📱 **Local-First Flutter Mobile App**: High-performance cross-platform application powered by Riverpod and Drift (SQLite) with zero network requirement for core operations.
- 🌐 **Hardened Django REST Backend**: Authoritative sync changelog engine, dual JWT token authentication (`/api/v2/auth/*`), and extensive exercise databases.
- 🔒 **Privacy-First Data Boundary**: On-device calculation, local telemetry sanitization, and end-to-end data ownership.

---

## 🏗️ System Architecture

```
┌────────────────────────────────────────────────────────┐
│               Kinetic Fusion Mobile App                │
│                 (Flutter / Android / iOS)              │
│                                                        │
│   [ UI Screens & ViewModels ]                          │
│                ↓                                       │
│   [ Application Services & Intelligence Engines ]      │
│     • Recovery Engine   • Progression Engine           │
│     • Sleep Engine      • State Estimator              │
│                ↓                                       │
│   [ Local Persistence Layer (Drift SQLite) ]           │
└───────────────────────────┬────────────────────────────┘
                            │
               Optional Background Sync (REST + JWT)
                            ▼
┌────────────────────────────────────────────────────────┐
│             Kinetic Fusion Backend Engine              │
│               (Django REST Framework)                  │
│                                                        │
│   • Auth & Security Tier (/api/v2/auth/*)              │
│   • Authoritative Sync Engine (/api/v2/sync/*)         │
│   • Exercise & Nutrition Database (/api/v2/*)          │
│   • Telemetry & Admin Command Center                   │
└───────────────────────────┬────────────────────────────┘
                            ▼
            [ PostgreSQL / SQLite Database ]
```

---

## 🚀 Quickstart

### 1. Backend Setup & Run

#### Prerequisites
- Python 3.12+ (Virtual environment recommended)
- Dependencies installed via `pip` or `uv`

```bash
# 1. Apply database migrations
python manage.py migrate --settings=settings.local_dev

# 2. Seed database with core exercise library & translations
python manage.py loaddata languages.json licenses.json setting_repetition_units.json setting_weight_units.json categories.json equipment.json muscles.json exercise-base-data.json translations.json --settings=settings.local_dev

# 3. Start the backend development server
python manage.py runserver 0.0.0.0:8000 --settings=settings.local_dev
```

---

### 2. Mobile App (Flutter) Setup & Build

```bash
cd getfit_flutter

# 1. Install Flutter dependencies
flutter pub get

# 2. Run unit tests
flutter test

# 3. Build Release Android APK
flutter build apk --release
```

The compiled release APK is generated at:
`getfit_flutter/build/app/outputs/flutter-apk/app-release.apk`

---

## 🧪 Testing & Verification

The Kinetic Fusion test suite verifies end-to-end mathematical determinism, offline resilience, and domain models:

```bash
cd getfit_flutter
flutter test
```
*Status:* **167 tests passed (0 failures)** covering:
- Deterministic simulation pipelines across synthetic archetypes.
- Dynamic load progression and volume adjustments.
- Offline SQLite storage and local query performance.
- JWT session rotation and fallback recovery.

---

## 📂 Repository Structure

```
├── getfit_flutter/         # Kinetic Fusion Mobile App (Flutter)
│   ├── lib/
│   │   ├── kinetic/        # Intelligence Engines, Math Models & Persistence
│   │   ├── core/           # Auth, Database, API Client, Routing & Sync
│   │   └── features/       # Screens, Dashboards, Workouts & Telemetry UI
│   └── test/               # Comprehensive Unit & Integration Test Suites
├── wger/                   # Kinetic Fusion Backend Engine (Django REST)
│   ├── core/               # Auth, Security, Sync Engine & Models
│   ├── exercises/          # Exercise Database, Muscle Groups & Taxonomy
│   └── nutrition/          # Nutrition Tracking & Ingredient Database
├── settings/               # Environment & Deployment Configurations
└── setup-backend.md        # Comprehensive Backend Setup & Migration Guide
```

---

## 📄 License

- **Application Code:** Licensed under the [AGPL-3.0-or-later](LICENSE.txt).
- **Exercise & Reference Data:** Creative Commons (see individual fixture files).
