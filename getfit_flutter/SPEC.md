# KINETIC PRECISION — MECHANICS / APPLICATION CORE

## Mission

Build the **mechanics, data layer, intelligence engine, local persistence, simulation environment, and application services** for Kinetic Precision while the product UI/UX is being designed separately.

The UI is being developed independently.

Your job is to build the **machine underneath the UI**.

Do not spend time polishing visual design.

Do not hardcode business logic into screens.

Do not make the application dependent on the current mockup structure.

The final UI should be able to consume clean, stable domain APIs and render whatever experience the design team creates.

---

# 1. Product Definition

Kinetic Precision is a **fully local personal fitness intelligence system**.

It is not primarily a tracker.

It is a:

> **Decision engine with a fitness interface.**

The system ingests a large amount of personal data and converts it into useful recommendations.

The primary question is:

> **What should this person do next?**

Potential inputs include:

* sleep
* activity
* walking
* running
* cycling
* exercise
* sets
* reps
* load
* RPE
* heart rate
* resting heart rate
* HRV
* blood pressure
* weight
* height
* body composition
* nutrition
* hydration
* meal timing
* lifestyle
* stress
* routine
* location
* environmental conditions
* training history
* recovery history
* goals
* constraints
* device data

The system must be designed to support many additional signals later.

Do not hardcode the current input list as the permanent architecture.

---

# 2. Non-Negotiable Architecture Principles

## Local-first

The application must work without cloud dependency.

Core functionality must run locally:

* persistence
* calculations
* feature generation
* recommendation engine
* model inference
* historical analysis
* workout generation
* state estimation

Network connectivity may be used later for optional integrations, updates, or backup, but the core product must not depend on it.

---

## Separation of concerns

Strictly separate:

```text
UI
↓
Application Services
↓
Domain Logic
↓
Intelligence Engine
↓
Data Layer
↓
Local Storage
```

Do not place domain calculations inside UI components.

Do not let UI state become the source of truth.

---

# 3. Nutrition & Food Diary Architecture (Module 11 Reconciled)

## Barcode Scanning as an Entry Method
* Barcode scanning (Open Food Facts integration) is strictly an **entry method** into the existing food diary (`KineticDiaryEntry` / `NutritionDiary`).
* No secondary or parallel food-diary or macro-calculation system is permitted.
* All foods, whether logged via text search, curated seed library, or camera barcode scan, share the identical canonical per-100g schema (`energy`, `protein`, `carbs`, `fat`, `fiber`, `sugar`, `sodium`).
* All macro calculations use pure weight-based evaluation:
  $$\text{actual\_value} = \left(\frac{\text{stored\_value\_per\_100g}}{100}\right) \times \text{entered\_grams}$$
* Multi-tier caching guarantees full offline capability: previously scanned items resolve from local Drift cache with 0 network calls; uncached offline scans surface explicit guidance without blocking manual logging.
