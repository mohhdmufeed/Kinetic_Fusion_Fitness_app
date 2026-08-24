# Kinetic Fusion Mobile App

Cross-platform mobile client for the **Kinetic Fusion** fitness intelligence system, built with **Flutter**, **Riverpod**, and **Drift (SQLite)**.

---

## ⚡ Core Architecture

Kinetic Fusion follows a strict **local-first** layered architecture where domain mechanics and calculations run entirely on-device without cloud dependence.

```text
UI Screens (Widgets & Motion)
          ↓
Application Services & Facade
          ↓
Intelligence Engines & Estimators
          ↓
Domain Models & Math Algorithms
          ↓
Local Persistence Layer (Drift SQLite)
```

---

## 📁 Key Modules

- **`lib/kinetic/intelligence/`**: Recovery engine, training progression engine, sleep engine, and latent state estimator.
- **`lib/kinetic/math/`**: ACWR calculations, volume load modeling, time-series rolling computations, and baseline statistics.
- **`lib/kinetic/persistence/`**: Drift SQLite persistence (`kinetic_store.dart`) for on-device state.
- **`lib/kinetic/simulation/`**: Deterministic synthetic archetypes for multi-month offline simulations.
- **`lib/core/`**: JWT Auth service, Dio HTTP client, route navigation, and background sync triggers.
- **`lib/features/`**: Flutter UI components (Dashboard, Today readiness card, Workouts, Activity, and Settings).

---

## 🚀 Build Instructions

### Prerequisites
- Flutter SDK (3.x+)
- Android SDK / Java JDK 17+

### Install Dependencies
```bash
flutter pub get
```

### Run Unit Test Suite
```bash
flutter test
```

### Build Android APK (Release)
```bash
flutter build apk --release
```

Output:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🌐 Connecting to the Backend

Configure backend host in [`lib/core/constants.dart`](lib/core/constants.dart):

```dart
class AppConstants {
  // Local Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Physical Device on Wi-Fi LAN
  // static const String baseUrl = 'http://<YOUR_IP>:8000';

  // Online Cloud Server
  // static const String baseUrl = 'https://your-production-domain.com';
}
```
