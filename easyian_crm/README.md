# Easyian CRM — Flutter App

A full-featured CRM Flutter frontend for the Easyian Django backend.

## Features

- 🌗 **Dark & Light Mode** — system-aware + manual toggle
- 📊 **Dashboard** — KPI cards, bar charts, pie charts, line charts, funnel
- 👥 **Leads Management** — full CRUD, filters, search, activity timeline
- 📧 **Email Campaigns, Templates, Sequences, Config**
- 📈 **Analytics** — conversion trends, source performance, status breakdown
- 👤 **Profile & User Management** (Admin only)
- 🔐 **Token Auth** — Django REST Framework token authentication

---

## Setup

### 1. Prerequisites
- Flutter SDK ≥ 3.0
- Django backend running (see crm_project)

### 2. Install dependencies
```bash
cd easyian_crm
flutter pub get
```

### 3. Configure backend URL

Edit `lib/core/constants/app_constants.dart`:

```dart
// Android emulator
static const String baseUrl = 'http://10.0.2.2:8000';

// iOS simulator
// static const String baseUrl = 'http://localhost:8000';

// Physical device / production
// static const String baseUrl = 'http://your-server-ip:8000';
```

### 4. Run
```bash
# Android
flutter run

# iOS
flutter run --release

# Web
flutter run -d chrome
```

---

## Backend Requirements

Your Django `settings.py` must have:

```python
# REST Framework
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

# CORS — required for Flutter Web
CORS_ALLOW_ALL_ORIGINS = True  # or restrict to your origin
```

Install CORS:
```bash
pip install django-cors-headers
```

Add to `INSTALLED_APPS`:
```python
'corsheaders',
```

Add to `MIDDLEWARE` (before CommonMiddleware):
```python
'corsheaders.middleware.CorsMiddleware',
```

---

## API Endpoints Used

| Feature | Endpoint |
|---|---|
| Login | `POST /api/auth/login/` |
| Dashboard Stats | `GET /api/dashboard/stats/` |
| Leads | `GET/POST /api/leads/` |
| Lead Detail | `GET/PATCH/DELETE /api/leads/{id}/` |
| Lead Stats | `GET /api/leads/stats/` |
| Lead Sources | `GET /api/lead-sources/` |
| Activities | `GET/POST /api/lead-activities/` |
| Email Configs | `GET/POST /api/email-configs/` |
| Email Templates | `GET/POST /api/email-templates/` |
| Email Campaigns | `GET/POST /api/email-campaigns/` |
| Emails | `GET /api/emails/` |
| Email Sequences | `GET/POST /api/email-sequences/` |
| Users | `GET/POST /api/users/` |
| KPI Targets | `GET/POST /api/kpi-targets/` |

---

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── constants/app_constants.dart   ← API URLs
│   ├── theme/app_theme.dart           ← Light & dark themes
│   └── utils/
│       ├── api_client.dart            ← HTTP client with auth
│       └── app_provider.dart          ← Global state
├── models/                            ← Data models
├── services/                          ← API services
├── screens/
│   ├── auth/login_screen.dart
│   ├── dashboard/dashboard_screen.dart
│   ├── leads/
│   │   ├── leads_list_screen.dart
│   │   ├── lead_detail_screen.dart
│   │   └── lead_form_screen.dart
│   ├── communications/
│   │   ├── email_templates_screen.dart
│   │   ├── email_campaigns_screen.dart
│   │   ├── email_list_screen.dart
│   │   └── email_sequences_screen.dart
│   ├── analytics/analytics_screen.dart
│   ├── settings/email_config_screen.dart
│   ├── profile/profile_screen.dart
│   └── users/users_list_screen.dart
└── widgets/
    ├── easyian_logo.dart
    ├── app_drawer.dart
    ├── common_widgets.dart
    ├── splash_screen.dart
    └── charts/chart_widgets.dart
```
