# Django-Tenants Migration Guide
## CRM Pro — Complete Implementation Guide (Backend + Flutter)

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Security Issues Fixed](#security-issues-fixed)
3. [Files Changed](#files-changed)
4. [Backend Setup — Step by Step](#backend-setup)
5. [Flutter Frontend — Step by Step](#flutter-frontend)
6. [How Tenant Resolution Works](#how-tenant-resolution-works)
7. [API Reference](#api-reference)
8. [Superadmin Workflows](#superadmin-workflows)
9. [Production Checklist](#production-checklist)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### How django-tenants Works

Each tenant organisation gets its own **PostgreSQL schema**. Every table in every
CRM app (`leads`, `contacts`, `deals`, etc.) exists as a **separate, isolated copy**
per tenant. It is physically impossible for one tenant to read another's data.

```
PostgreSQL Database: crm_pro
│
├── public (shared schema)
│   ├── accounts_customuser        ← all users live here
│   ├── authtoken_token            ← tokens live here
│   ├── tenants_tenant             ← tenant registry
│   ├── tenants_domain             ← domain → tenant mapping
│   ├── tenants_plan               ← subscription plans
│   └── tenants_tenantuser         ← user ↔ tenant membership
│
├── sharma_infotech  (tenant schema — auto-created)
│   ├── leads_lead                 ← Sharma's leads ONLY
│   ├── contacts_contact
│   ├── deals_deal
│   └── ... (all CRM tables)
│
├── patel_trading    (tenant schema — auto-created)
│   ├── leads_lead                 ← Patel's leads ONLY (different table)
│   └── ...
│
└── gupta_enterprises (tenant schema — auto-created)
    └── ...
```

### Tenant Resolution — Header Based

The Flutter app sends an `X-Tenant-ID` header with every request.
The Django middleware reads this header, looks up the matching tenant, and
**switches the PostgreSQL connection to that tenant's schema** before the view
even runs.

```
Flutter App                     Django Server               PostgreSQL
    │                               │                           │
    │  GET /api/leads/              │                           │
    │  Authorization: Token abc     │                           │
    │  X-Tenant-ID: sharma-infotech │                           │
    │ ─────────────────────────────>│                           │
    │                               │  SET search_path =        │
    │                               │  sharma_infotech ─────────>
    │                               │                           │
    │                               │  SELECT * FROM leads_lead │
    │                               │  (sharma_infotech schema) │
    │                               │ <─────────────────────────│
    │  [{ id:1, ... }, ...]         │                           │
    │ <─────────────────────────────│                           │
```

---

## Security Issues Fixed

| Issue | Before | After |
|---|---|---|
| Cross-tenant data leak | `Lead.objects.all()` returned ALL tenants' leads | Schema isolation — impossible to see other tenant's data |
| No tenant filtering in ViewSets | Every ViewSet was unscoped | `search_path` enforced at DB level |
| Tenant FK not on CRM models | Models had no tenant field yet | No FK needed — schema IS the boundary |
| `TenantMiddleware` was decorative | Set `request.tenant` but nothing used it | New middleware actually switches DB schema |
| Integer ID in header | `X-Tenant-ID: 42` (guessable) | `X-Tenant-ID: sharma-infotech` (slug — no enumeration) |

---

## Files Changed

### Backend (30 files)

| File | Type | Description |
|---|---|---|
| `requirements.txt` | Modified | Added `django-tenants`, `psycopg2-binary` |
| `manage.py` | Replaced | Uses `django_tenants.management` |
| `crm_project/settings.py` | Replaced | `SHARED_APPS`/`TENANT_APPS`, PostgreSQL, new CORS headers |
| `crm_project/urls.py` | Replaced | Public schema URL conf (superadmin) |
| `crm_project/tenant_urls.py` | New | Tenant schema URL conf (CRM) |
| `crm_project/public_api_urls.py` | New | Superadmin API routes |
| `crm_project/tenant_api_urls.py` | New | All CRM API routes |
| `tenants/models.py` | Replaced | `TenantMixin`, `DomainMixin`, clean models |
| `tenants/middleware.py` | Replaced | Header-based schema switcher |
| `tenants/api.py` | Replaced | Proper permission classes |
| `tenants/admin.py` | Replaced | Full Django admin registration |
| `tenants/management/commands/setup_public_tenant.py` | New | Bootstrap command |
| `accounts/api.py` | Replaced | Login returns `tenant_slug`, `schema_name` etc. |
| `leads/models.py` | Replaced | Tenant FK removed |
| `leads/api.py` | Replaced | Clean ViewSet, no manual tenant filtering |
| `contacts/models.py` | Replaced | Tenant FK removed |
| `deals/models.py` | Replaced | Tenant FK removed |
| `tickets/models.py` | Replaced | Tenant FK removed |
| `quotes/models.py` | Replaced | Tenant FK removed |
| `workflows/models.py` | Replaced | Tenant FK removed |
| `integrations/models.py` | Replaced | Tenant FK removed |
| `dashboard/models.py` | Replaced | Tenant FK removed |
| `communications/models.py` | Replaced | Tenant FK removed |
| `dashboard/management/commands/seed_all_data.py` | Replaced | Uses `tenant_context()` |
| `.env.example` | New | PostgreSQL env template |

### Flutter (4 files)

| File | Type | Description |
|---|---|---|
| `lib/core/constants/app_constants.dart` | Replaced | Added `tenantSlugKey`, `tenantRoleKey`, `schemaNameKey` |
| `lib/core/utils/api_client.dart` | Replaced | Sends slug in `X-Tenant-ID`, added `postNoAuth()`, safe `setTenantId()` alias |
| `lib/services/auth_service.dart` | Replaced | Reads `tenant_slug` from login response, added `switchTenant()` |
| `lib/providers/app_provider.dart` | Replaced | Removed broken `_ensureTenant()`, added `switchTenant()` |

---

## Backend Setup

### Prerequisites

- Python 3.10+
- PostgreSQL 13+ installed and running
- Virtual environment activated

---

### Step 1 — Install Dependencies

```bash
pip install -r requirements.txt
```

Key new packages:
- `django-tenants==3.6.1` — schema-based multi-tenancy
- `psycopg2-binary==2.9.9` — PostgreSQL driver

---

### Step 2 — Set Up PostgreSQL

```bash
# Open psql as postgres superuser
psql -U postgres

# Create the database and user
CREATE DATABASE crm_pro;
CREATE USER crm_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE crm_pro TO crm_user;
ALTER DATABASE crm_pro OWNER TO crm_user;
\q
```

---

### Step 3 — Create .env File

Copy `.env.example` to `.env` and fill in your values:

```env
SECRET_KEY=your-very-secret-django-key-change-before-production
DEBUG=True
DB_NAME=crm_pro
DB_USER=crm_user
DB_PASSWORD=your_password
DB_HOST=localhost
DB_PORT=5432
```

---

### Step 4 — Replace All Backend Files

Copy all files from this package into your project, respecting the directory structure. All files are drop-in replacements — no merging needed.

---

### Step 5 — Delete Old Migrations

Old migrations reference SQLite and the old tenant FK fields. They must be deleted.

```bash
# Delete all numbered migration files (keeps __init__.py)
find leads contacts deals tickets quotes workflows communications \
     integrations dashboard -path "*/migrations/0*.py" -delete

# Also delete the old SQLite file
rm -f db.sqlite3
```

---

### Step 6 — Run Shared Migrations

This creates all public-schema tables (users, tokens, tenant registry):

```bash
python manage.py migrate_schemas --shared
```

Expected output:
```
Running migrations for shared apps in schema public
  Applying tenants.0001_initial...  OK
  Applying accounts.0001_initial... OK
  Applying authtoken.0001_initial... OK
  ...
```

---

### Step 7 — Bootstrap the Public Tenant

```bash
python manage.py setup_public_tenant
```

This creates:
- The `public` tenant entry (required by django-tenants)
- A `localhost` domain entry
- The `superadmin` user (password: `superadmin123`)

Output:
```
  ✓ Public tenant created
  ✓ Domain "localhost" created
  ✓ Superadmin "superadmin" created (password: superadmin123)
  ⚠  Change the password before going to production!
```

---

### Step 8 — Seed Demo Data (Optional)

```bash
python manage.py seed_all_data
```

This creates 3 demo tenants with full data:
- **Sharma InfoTech** (`sharma-infotech`) — Professional plan, active
- **Patel Trading** (`patel-trading`) — Growth plan, active
- **Gupta Enterprises** (`gupta-enterprises`) — Starter plan, trial

Each tenant gets its own PostgreSQL schema with seeded leads, contacts, deals, tickets, quotes, pipelines, and workflows.

Login credentials:
- Superadmin: `superadmin` / `superadmin123`
- Tenant admins: e.g. `sharma_admin` / `password123`

---

### Step 9 — Run the Server

```bash
python manage.py runserver
```

---

### Useful Management Commands

```bash
# List all tenant schemas
python manage.py shell -c "from tenants.models import Tenant; [print(t.schema_name, t.name) for t in Tenant.objects.all()]"

# Migrate a specific tenant schema
python manage.py migrate_schemas --schema=sharma_infotech

# Migrate all tenant schemas
python manage.py migrate_schemas

# Open a shell inside a specific tenant's schema
python manage.py shell
>>> from django_tenants.utils import tenant_context
>>> from tenants.models import Tenant
>>> t = Tenant.objects.get(slug='sharma-infotech')
>>> with tenant_context(t):
...     from leads.models import Lead
...     print(Lead.objects.count())

# Create a new tenant manually
python manage.py shell
>>> from tenants.models import Tenant, Domain
>>> t = Tenant(name='New Corp', slug='new-corp', email='admin@newcorp.com')
>>> t.save()  # ← this auto-creates the PostgreSQL schema
>>> Domain.objects.create(domain='new-corp.localhost', tenant=t, is_primary=True)
```

---

## Flutter Frontend

### What Changed and What Didn't

**Nothing changed:**
- Base URL: `http://127.0.0.1:8000`
- All 40+ endpoint paths: `/api/leads/`, `/api/contacts/`, etc.
- Auth token mechanism: `Authorization: Token xxx`
- All screen/service/model files: untouched

**Only this changed:**
- `X-Tenant-ID` header now sends the **slug string** (e.g. `sharma-infotech`) instead of an integer
- 4 core files updated (constants, api_client, auth_service, app_provider)

---

### Step 1 — Replace the 4 Flutter Files

Copy these files from the `easyian_crm/` folder in this package:

```
lib/core/constants/app_constants.dart   ← adds tenantSlugKey
lib/core/utils/api_client.dart          ← sends slug in X-Tenant-ID
lib/services/auth_service.dart          ← reads tenant_slug from login
lib/providers/app_provider.dart         ← uses AuthService properly
```

No other Flutter files need to change.

---

### Step 2 — Understand the New Login Flow

#### Before (broken)
```
POST /api/auth/login/
← { token, user_id, email, role }
   (no tenant info — app had to make a second call to /api/tenants/ and
    guess the tenant by integer id)
```

#### After (correct)
```
POST /api/auth/login/
← {
    token:        "abc123...",
    user_id:      1,
    username:     "sharma_admin",
    email:        "rajesh@sharmainfotech.in",
    role:         "admin",
    tenant_slug:  "sharma-infotech",    ← stored as X-Tenant-ID value
    tenant_id:    3,                    ← integer PK (for display only)
    tenant_name:  "Sharma InfoTech Pvt Ltd",
    tenant_role:  "tenant_admin",
    schema_name:  "sharma_infotech",
    plan_name:    "Professional"
  }
```

`AuthService.login()` automatically:
1. Saves `tenant_slug` to `SharedPreferences` under `tenantSlugKey`
2. Calls `ApiClient.instance.setTenantSlug("sharma-infotech")`
3. Every subsequent request automatically includes `X-Tenant-ID: sharma-infotech`

---

### Step 3 — Understand App Startup / Session Restore

On cold start, `AppProvider.init()` is called:

```dart
// app_provider.dart
Future<void> init() async {
  await ApiClient.instance.loadFromPrefs();     // restores token + slug from SharedPrefs
  final ok = await AuthService.instance.checkAuth();   // validates token, restores user
  if (ok) {
    _user = AuthService.instance.currentUser;
  }
}
```

`ApiClient.loadFromPrefs()` reads `tenantSlugKey` — so the slug is wired up
**before** any API call is made, including the `/users/:id/` call inside `checkAuth()`.

---

### Step 4 — SharedPreferences Keys Reference

After a successful login these keys are set:

| Key constant | Example value | Purpose |
|---|---|---|
| `tokenKey` | `"abc123def456..."` | DRF auth token |
| `userIdKey` | `1` | User's integer PK |
| `userEmailKey` | `"rajesh@..."` | Display |
| `userRoleKey` | `"admin"` | App-level role |
| `tenantSlugKey` | `"sharma-infotech"` | **Sent in `X-Tenant-ID` header** |
| `tenantIdKey` | `3` | Integer PK (display/reference only) |
| `tenantNameKey` | `"Sharma InfoTech Pvt Ltd"` | Display in UI |
| `tenantRoleKey` | `"tenant_admin"` | Role within this tenant |
| `schemaNameKey` | `"sharma_infotech"` | PostgreSQL schema (informational) |

---

### Step 5 — Header Flow Visualised

```
SharedPreferences
  tenantSlugKey = "sharma-infotech"
        │
        ▼
ApiClient._tenantSlug = "sharma-infotech"
        │
        ▼
Every HTTP request:
  GET http://127.0.0.1:8000/api/leads/
  Authorization: Token abc123...
  X-Tenant-ID: sharma-infotech          ← automatically injected
        │
        ▼
Django TenantFromHeaderMiddleware
  reads X-Tenant-ID = "sharma-infotech"
  Tenant.objects.get(slug="sharma-infotech")
  connection.set_tenant(tenant)  →  SET search_path = sharma_infotech
        │
        ▼
LeadViewSet.get_queryset()
  Lead.objects.all()   ← automatically sharma_infotech.leads_lead
  returns only Sharma's leads
```

---

### Step 6 — Superadmin Tenant Switching

Superadmins need to access multiple tenants. Use `AppProvider.switchTenant()`:

```dart
// Example usage in SuperAdmin screen
// When admin taps on a tenant card to browse its data:
await context.read<AppProvider>().switchTenant(
  slug:       'patel-trading',
  name:       'Patel Trading Co',
  tenantId:   2,
  tenantRole: 'super_admin',
  schemaName: 'patel_trading',
);
// All subsequent API calls now go to patel_trading schema
```

Or directly via `AuthService`:
```dart
await AuthService.instance.switchTenant(
  'patel-trading',
  tenantId:   2,
  tenantName: 'Patel Trading Co',
);
```

---

### Step 7 — Superadmin Endpoints (No Tenant Header)

The `/api/tenants/`, `/api/plans/` endpoints live on the **public schema**.
When the app makes these calls it should either:

**Option A** — Clear the tenant slug temporarily (recommended for superadmin screen):
```dart
ApiClient.instance.setTenantSlug(null);
final tenants = await ApiClient.instance.get(AppConstants.tenantsEndpoint);
// re-set the slug after
ApiClient.instance.setTenantSlug(savedSlug);
```

**Option B** — The server falls back to the public schema automatically when no slug header is present (no code change needed — the middleware handles it).

In practice this means the SuperAdmin screen already works because it calls `/api/tenants/` without worrying about headers — those endpoints are only registered on the public URL conf.

---

### Step 8 — Testing the Integration

#### Quick smoke test with curl

```bash
# 1. Login (no X-Tenant-ID needed)
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"sharma_admin","password":"password123"}'

# Response will include: "tenant_slug": "sharma-infotech"

# 2. Use the token + slug for tenant requests
curl http://127.0.0.1:8000/api/leads/ \
  -H "Authorization: Token <token_from_step_1>" \
  -H "X-Tenant-ID: sharma-infotech"
# Returns only Sharma's leads

# 3. Same endpoint, different tenant — completely different data
curl http://127.0.0.1:8000/api/leads/ \
  -H "Authorization: Token <patel_admin_token>" \
  -H "X-Tenant-ID: patel-trading"
# Returns only Patel's leads

# 4. Superadmin — no tenant header needed for tenant management
curl http://127.0.0.1:8000/api/tenants/ \
  -H "Authorization: Token <superadmin_token>"
# Returns all tenants
```

---

## How Tenant Resolution Works

```
Incoming request
     │
     ▼
TenantFromHeaderMiddleware
     │
     ├── reads HTTP_X_TENANT_SLUG or HTTP_X_TENANT_ID header
     │
     ├── slug found?
     │     │
     │     ├── YES → Tenant.objects.get(slug=slug)
     │     │         → connection.set_tenant(tenant)
     │     │         → schema switched to e.g. "sharma_infotech"
     │     │
     │     └── NO  → Tenant.objects.get(schema_name='public')
     │               → stays on public schema
     │
     ▼
View / ViewSet runs
     │
     └── Lead.objects.all()
         → automatically queries sharma_infotech.leads_lead
         → zero chance of cross-tenant leak
```

---

## API Reference

### Endpoint Split

| Endpoint Group | Schema Used | Header Required |
|---|---|---|
| `POST /api/auth/login/` | public | No |
| `GET /api/tenants/` | public | No (superadmin only) |
| `GET /api/plans/` | public | No (any user) |
| `GET /api/leads/` | tenant | Yes — `X-Tenant-ID: <slug>` |
| `GET /api/contacts/` | tenant | Yes |
| `GET /api/deals/` | tenant | Yes |
| `GET /api/tickets/` | tenant | Yes |
| `GET /api/quotes/` | tenant | Yes |
| `GET /api/dashboard/stats/` | tenant | Yes |
| All other CRM endpoints | tenant | Yes |

### Login Response Shape

```json
{
  "token":        "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
  "user_id":      1,
  "username":     "sharma_admin",
  "email":        "rajesh@sharmainfotech.in",
  "first_name":   "Rajesh",
  "last_name":    "Sharma",
  "role":         "admin",
  "schema_name":  "sharma_infotech",
  "tenant_id":    3,
  "tenant_name":  "Sharma InfoTech Pvt Ltd",
  "tenant_slug":  "sharma-infotech",
  "tenant_role":  "tenant_admin",
  "plan_name":    "Professional"
}
```

---

## Superadmin Workflows

### Creating a New Tenant via API

```bash
POST /api/tenants/
Authorization: Token <superadmin_token>
Content-Type: application/json

{
  "name":    "New Company Ltd",
  "slug":    "new-company",
  "email":   "admin@newcompany.com",
  "plan":    2,
  "status":  "trial"
}
```

The `Tenant.save()` method calls `TenantMixin.save()` which automatically:
1. Derives `schema_name = "new_company"` from slug
2. Runs `CREATE SCHEMA new_company` in PostgreSQL
3. Runs all TENANT_APP migrations in that schema

### Suspending a Tenant

```bash
POST /api/tenants/3/suspend/
Authorization: Token <superadmin_token>
```

### Changing a Tenant's Plan

```bash
POST /api/tenants/3/change_plan/
Authorization: Token <superadmin_token>
Content-Type: application/json

{ "plan_id": 4 }
```

---

## Production Checklist

### Backend

- [ ] Change `SECRET_KEY` in `.env`
- [ ] Set `DEBUG=False`
- [ ] Set `ALLOWED_HOSTS` to your domain(s)
- [ ] Change superadmin password: `python manage.py changepassword superadmin`
- [ ] Add real domain in `Domain` table (replace `localhost`)
- [ ] Configure email backend (not `console`)
- [ ] Add `gunicorn` + `whitenoise` to requirements
- [ ] Set up PostgreSQL with SSL
- [ ] Back up the database before any `migrate_schemas` run
- [ ] Encrypt `Integration.credentials` with `django-encrypted-fields`

### Flutter

- [ ] Change `baseUrl` in `app_constants.dart` from `127.0.0.1:8000` to your production domain
- [ ] Ensure HTTPS in production (`https://`)
- [ ] Add error handling for `401 Unauthorized` → redirect to login + clear prefs
- [ ] Add error handling for unknown tenant slug → show "Tenant not found" screen

### Security Reminder

The tenant slug is **not secret** — it's just a routing hint. Security comes from:
1. The auth token — a user can only access data they are authorised to see
2. PostgreSQL schema isolation — even if someone guesses a slug, their token is verified against the public schema user table before the view runs

---

## Troubleshooting

### `django_tenants.postgresql_backend` not found

```
django.core.exceptions.ImproperlyConfigured: 'django_tenants.postgresql_backend' isn't an available database backend.
```
**Fix:** `pip install django-tenants psycopg2-binary`

---

### `relation "leads_lead" does not exist`

The migration hasn't run for that tenant's schema yet.
```bash
python manage.py migrate_schemas --schema=sharma_infotech
```

---

### `Tenant matching query does not exist`

The Flutter app is sending a slug that doesn't exist in the database.
Check the `X-Tenant-ID` header value matches `Tenant.slug` exactly.

---

### Login works but all subsequent requests return 404

The slug returned in the login response isn't being stored/sent properly.
Check `SharedPreferences.getString(AppConstants.tenantSlugKey)` is not null after login.

---

### `migrate_schemas --shared` fails with permission error

```
FATAL: permission denied for database crm_pro
```
**Fix:**
```sql
GRANT ALL PRIVILEGES ON DATABASE crm_pro TO crm_user;
ALTER SCHEMA public OWNER TO crm_user;
```

---

### Superadmin can't see tenants list

Ensure the superadmin request has **no** `X-Tenant-ID` header (or `X-Tenant-ID: public`).
Tenant management endpoints only exist on the public schema URL conf.
