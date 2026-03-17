# crm_project/settings.py  ← FULL REPLACEMENT (django-tenants migration)
import os
from decouple import config
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = config('SECRET_KEY', default='your-secret-key-change-in-production')
DEBUG      = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = ['*']

# ══════════════════════════════════════════════════════════════════════
# django-tenants: SHARED_APPS live in the "public" PostgreSQL schema.
# TENANT_APPS get their own tables in each tenant's private schema.
# INSTALLED_APPS must equal SHARED_APPS + TENANT_APPS (no duplicates).
# django_tenants MUST be first in SHARED_APPS.
# ══════════════════════════════════════════════════════════════════════

SHARED_APPS = [
    # django-tenants (must be first)
    'django_tenants',

    # Django core — shared
    'django.contrib.contenttypes',
    'django.contrib.auth',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.admin',
    'django.contrib.staticfiles',
    'django.contrib.humanize',

    # Third-party — shared
    'crispy_forms',
    'crispy_bootstrap5',
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',

    # Shared CRM apps (users + tenant management live in public schema)
    'accounts',   # CustomUser, UserProfile
    'tenants',    # Plan, Tenant, Domain, TenantUser, TenantInvitation, TenantAuditLog
]

TENANT_APPS = [
    # All CRM business-data apps go into each tenant's private schema
    'django.contrib.contenttypes',   # required duplicate for tenant schemas
    'leads',
    'contacts',
    'deals',
    'quotes',
    'tickets',
    'workflows',
    'communications',
    'integrations',
    'dashboard',
]

# django-tenants requires INSTALLED_APPS = SHARED_APPS + unique TENANT_APPS
INSTALLED_APPS = list(SHARED_APPS) + [
    app for app in TENANT_APPS if app not in SHARED_APPS
]

# ── django-tenants config ──────────────────────────────────────────────────────
TENANT_MODEL        = 'tenants.Tenant'
DOMAIN_MODEL        = 'tenants.Domain'
PUBLIC_SCHEMA_NAME  = 'public'

# Schema names are auto-created when a Tenant object is saved
TENANT_AUTO_CREATE_SCHEMA = True

# ══════════════════════════════════════════════════════════════════════
# Middleware
# TenantFromHeaderMiddleware MUST be first — it sets the DB schema for
# every subsequent middleware and view.
# ══════════════════════════════════════════════════════════════════════
MIDDLEWARE = [
    # ① Tenant resolution (reads X-Tenant-Slug or X-Tenant-ID header)
    'tenants.middleware.TenantFromHeaderMiddleware',

    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# ══════════════════════════════════════════════════════════════════════
# URL Configuration
# ROOT_URLCONF        → used for tenant schemas
# PUBLIC_SCHEMA_URLCONF → used for the "public" schema (superadmin)
# ══════════════════════════════════════════════════════════════════════
ROOT_URLCONF         = 'crm_project.tenant_urls'
PUBLIC_SCHEMA_URLCONF = 'crm_project.urls'

# ── Database (PostgreSQL required for django-tenants) ─────────────────────────
DATABASES = {
    'default': {
        'ENGINE':   'django_tenants.postgresql_backend',
        'NAME':     config('DB_NAME',     default='crm_pro'),
        'USER':     config('DB_USER',     default='postgres'),
        'PASSWORD': config('DB_PASSWORD', default='password'),
        'HOST':     config('DB_HOST',     default='localhost'),
        'PORT':     config('DB_PORT',     default='5432'),
    }
}

DATABASE_ROUTERS = ['django_tenants.routers.TenantSyncRouter']

# ── Templates ─────────────────────────────────────────────────────────────────
TEMPLATES = [{
    'BACKEND': 'django.template.backends.django.DjangoTemplates',
    'DIRS': [BASE_DIR / 'templates'],
    'APP_DIRS': True,
    'OPTIONS': {'context_processors': [
        'django.template.context_processors.debug',
        'django.template.context_processors.request',
        'django.contrib.auth.context_processors.auth',
        'django.contrib.messages.context_processors.messages',
    ]},
}]

WSGI_APPLICATION = 'crm_project.wsgi.application'

# ── Auth ──────────────────────────────────────────────────────────────────────
AUTH_USER_MODEL = 'accounts.CustomUser'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ── REST Framework ────────────────────────────────────────────────────────────
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.SessionAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
}

# ── CORS ──────────────────────────────────────────────────────────────────────
CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'x-tenant-id',      # ← Flutter sends this to identify tenant
    'x-tenant-slug',    # ← alternate header name
]

# ── Internationalisation ──────────────────────────────────────────────────────
LANGUAGE_CODE = 'en-us'
TIME_ZONE     = 'Asia/Kolkata'
USE_I18N      = True
USE_TZ        = True

# ── Static / Media ────────────────────────────────────────────────────────────
STATIC_URL       = '/static/'
STATICFILES_DIRS = [BASE_DIR / 'static']
STATIC_ROOT      = BASE_DIR / 'staticfiles'

MEDIA_URL  = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# ── Crispy Forms ──────────────────────────────────────────────────────────────
CRISPY_ALLOWED_TEMPLATE_PACKS = 'bootstrap5'
CRISPY_TEMPLATE_PACK = 'bootstrap5'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ── Email (development) ───────────────────────────────────────────────────────
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
DEFAULT_FROM_EMAIL = 'noreply@easyian.com'
