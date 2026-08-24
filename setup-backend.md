# Kinetic Fusion — Backend Setup & Architecture Guide

Complete, step-by-step documentation for deploying, configuring, and operating the **Kinetic Fusion Backend Engine**. This backend powers the **Kinetic Fusion Mobile App (Flutter)** with dual JWT authentication, authoritative changelog sync, exercise taxonomy, and intelligence telemetry.

---

## 🏗️ Architecture Overview

Kinetic Fusion utilizes a **hybrid local-first architecture**:
1. **Mobile App**: Executes all intelligence, calculations, and local queries autonomously against an on-device Drift SQLite database.
2. **Backend Engine**: A hardened **Django 6.0 REST API** providing central authentication, multi-device changelog synchronization, reference exercise databases, and analytics telemetry.

```
┌────────────────────────────────────────────────────────┐
│               Kinetic Fusion Mobile App                │
│       - On-Device SQLite (Drift) & Secure Storage      │
└───────────────────────────┬────────────────────────────┘
                            │ HTTP/HTTPS + Bearer JWT
                            ▼
┌────────────────────────────────────────────────────────┐
│             Kinetic Fusion Backend Engine              │
│  - /api/v2/auth/*      (Dual JWT: Access & Refresh)    │
│  - /api/v2/sync/*      (Authoritative ChangeLog Engine)│
│  - /api/v2/exercise/*  (872+ Exercises & Translations) │
│  - /api/v2/routine/*   (Routines & Workouts)           │
│  - /api/v2/nutrition/* (Closed Nutrition & Diary)      │
│  - /api/v2/activity/*  (GPS Telemetry & Pedometer)     │
└───────────────────────────┬────────────────────────────┘
                            ▼
              [ SQLite / PostgreSQL DB ]
```

---

## Part 1: Offline / Local Development Setup

Use this setup to run the backend on your development computer for testing with Android Studio Emulators or Physical Devices over Wi-Fi.

### 1.1 Virtual Environment & Dependencies

From the project root:

```bash
# Windows PowerShell
.\.venv\Scripts\Activate.ps1

# Or with Python directly
.\.venv\Scripts\python.exe -m pip install -e .
```

---

### 1.2 Run Database Migrations

Initialize the local database schema:

```bash
.\.venv\Scripts\python.exe manage.py migrate --settings=settings.local_dev
```

---

### 1.3 Seed Reference Data & Exercise Library

Populate all 872 English exercise records, categories, muscle anatomy, and license metadata:

```bash
.\.venv\Scripts\python.exe manage.py loaddata languages.json licenses.json setting_repetition_units.json setting_weight_units.json categories.json equipment.json muscles.json exercise-base-data.json translations.json --settings=settings.local_dev
```

---

### 1.4 Bootstrap System Config & Test User

Run the bootstrap command to link the default gym and create a testing account:

```bash
.\.venv\Scripts\python.exe manage.py shell --settings=settings.local_dev -c "from wger.gym.models import Gym; from wger.config.models.gym_config import GymConfig; gym, _ = Gym.objects.get_or_create(id=1, defaults={'name':'Kinetic Fusion HQ'}); gc, _ = GymConfig.objects.get_or_create(id=1); gc.default_gym = gym; gc.save(); from django.contrib.auth.models import User; u, _ = User.objects.get_or_create(username='kinetic_user', defaults={'email':'test@kineticprecision.com'}); u.set_password('KineticPass123!'); u.save(); print('Bootstrap Complete. Test User:', u.username)"
```

---

### 1.5 Start the Local Backend Server

```bash
.\.venv\Scripts\python.exe -u manage.py runserver 0.0.0.0:8000 --settings=settings.local_dev --noreload
```

- **Local URL:** `http://127.0.0.1:8000/`
- **Network Interface:** `http://0.0.0.0:8000/`

---

## Part 2: Online / Cloud Production Setup

For deploying Kinetic Fusion on Cloud VPS, Railway, Render, AWS, or Docker.

### 2.1 Environment Configuration (`.env`)

Create a production `.env` file in the root directory:

```env
# Security
DJANGO_SECRET_KEY="your-production-secret-key-at-least-50-characters"
DJANGO_DEBUG=False
DJANGO_ALLOWED_HOSTS="api.yourdomain.com,your-railway-app.up.railway.app"

# Database (PostgreSQL)
DJANGO_DB_ENGINE="django_prometheus.db.backends.postgresql"
DJANGO_DB_NAME="kinetic_fusion_db"
DJANGO_DB_USER="postgres"
DJANGO_DB_PASSWORD="your-secure-db-password"
DJANGO_DB_HOST="your-db-host.internal"
DJANGO_DB_PORT=5432

# CORS & CSRF Origins
CORS_ALLOWED_ORIGINS="https://your-frontend.com,http://localhost:8080"
CSRF_TRUSTED_ORIGINS="https://api.yourdomain.com,https://your-railway-app.up.railway.app"

# JWT Token Lifetime
SIMPLE_JWT_ACCESS_DAYS=7
SIMPLE_JWT_REFRESH_DAYS=30
```

---

### 2.2 Docker Production Deployment

Using Docker Compose from the root:

```bash
# Build and start all services (App, PostgreSQL, Redis, Celery)
docker compose -f extras/docker/production/docker-compose.yml up -d --build

# Run initial migrations in container
docker compose -f extras/docker/production/docker-compose.yml exec web python manage.py migrate

# Seed exercise data in container
docker compose -f extras/docker/production/docker-compose.yml exec web python manage.py loaddata languages.json licenses.json setting_repetition_units.json setting_weight_units.json categories.json equipment.json muscles.json exercise-base-data.json translations.json
```

---

## Part 3: API & Authentication Reference for APK

All endpoints are versioned under `/api/v2/`.

### 3.1 Authentication Endpoints

| Method | Endpoint | Description | Payload | Response |
|---|---|---|---|---|
| `POST` | `/api/v2/auth/signup/` | Register new user account | `{"username": "...", "email": "...", "password": "..."}` | `{"detail": "Verification email sent.", "verification_token": "..."}` |
| `POST` | `/api/v2/auth/login/` | Issue JWT access & refresh tokens | `{"username": "...", "password": "..."}` | `{"access": "jwt...", "refresh": "jwt...", "user_id": 1, "username": "..."}` |
| `POST` | `/api/v2/auth/refresh/` | Rotate access token | `{"refresh": "jwt_refresh_token"}` | `{"access": "new_jwt_access_token"}` |
| `POST` | `/api/v2/auth/logout/` | Revoke active device token | `{"refresh": "jwt_refresh_token"}` | `{"detail": "Session revoked."}` |
| `POST` | `/api/v2/auth/logout-all/`| Revoke all active user sessions | Headers: `Authorization: Bearer <token>` | `{"detail": "All sessions revoked."}` |

---

### 3.2 Core Data & Sync Endpoints

| Method | Endpoint | Query Parameters / Payload | Description |
|---|---|---|---|
| `GET` | `/api/v2/exerciseinfo/` | `language=2&limit=100&offset=0` | Paginated exercise library with names, muscles & instructions |
| `GET` | `/api/v2/routine/` | Header: `Authorization: Bearer <token>` | List user's saved routines and split days |
| `POST` | `/api/v2/routine/` | `{"name": "Upper Body Strength", "description": "..."}` | Create a workout routine |
| `GET` | `/api/v2/workoutlog/` | `date__gte=YYYY-MM-DD` | Fetch historical workout logs |
| `POST` | `/api/v2/workoutlog/` | `{"exercise": 1, "reps": 10, "weight": 80.0, "date": "..."}` | Record a completed set |
| `POST` | `/api/v2/sync/pull/` | `{"last_sync": "2026-08-24T00:00:00Z"}` | Pull delta changelogs for offline sync |
| `POST` | `/api/v2/sync/push/` | `{"changes": [...]}` | Push locally created logs to authoritative server |
| `GET` | `/api/v2/dashboard/today/` | Header: `Authorization: Bearer <token>` | Fetch consolidated daily telemetry payload |

---

## Part 4: Connecting the Mobile APK to the Backend

In the Flutter project (`getfit_flutter/`), configure your endpoint in [`lib/core/constants.dart`](file:///c:/Users/mohdm/Downloads/wger-master/getfit_flutter/lib/core/constants.dart):

```dart
class AppConstants {
  // Option A: Android Studio Emulator (Host loopback)
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Option B: Physical Device over Wi-Fi LAN (Replace with host IP)
  // static const String baseUrl = 'http://192.168.1.150:8000';

  // Option C: Online Cloud Server
  // static const String baseUrl = 'https://api.yourdomain.com';

  static const String apiBase = '$baseUrl/api/v2';
  ...
}
```

### Android Manifest Network Configuration
Cleartext traffic is enabled in [`getfit_flutter/android/app/src/main/AndroidManifest.xml`](file:///c:/Users/mohdm/Downloads/wger-master/getfit_flutter/android/app/src/main/AndroidManifest.xml) for local development:

```xml
<application
    android:label="Kinetic Fusion"
    android:usesCleartextTraffic="true"
    ... >
```

---

## Part 5: Verification & Automated Test Commands

### 1. Verify Backend Login & JWT Token Output

```bash
.\.venv\Scripts\python.exe -c "import urllib.request, json; data = json.dumps({'username': 'kinetic_user', 'password': 'KineticPass123!'}).encode('utf-8'); req = urllib.request.Request('http://127.0.0.1:8000/api/v2/auth/login/', data=data, headers={'Content-Type': 'application/json'}); res = json.loads(urllib.request.urlopen(req).read().decode('utf-8')); print('Login SUCCESS! Token:', res.get('access')[:30] + '...')"
```

---

### 2. Verify Exercise Taxonomy API (872 Exercises)

```bash
.\.venv\Scripts\python.exe -c "import urllib.request, json; login = json.dumps({'username': 'kinetic_user', 'password': 'KineticPass123!'}).encode('utf-8'); token = json.loads(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8000/api/v2/auth/login/', data=login, headers={'Content-Type': 'application/json'})).read().decode('utf-8'))['access']; ex = json.loads(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8000/api/v2/exerciseinfo/?language=2', headers={'Authorization': 'Bearer ' + token})).read().decode('utf-8')); print('Exercises API Success! Total records:', ex.get('count'))"
```

---

### 3. Run Mobile App Unit Test Suite (167 Tests)

```bash
cd getfit_flutter
flutter test
```
*Expected Result:* `00:12 +167: All tests passed!`
