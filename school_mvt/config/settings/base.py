"""
EduManage Pro — Base Settings
Multi-tenant SaaS: django-tenants + PostgreSQL
"""
import os
from pathlib import Path
from django.contrib.messages import constants as msg_const

BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ.get('SECRET_KEY', 'django-insecure-change-this-in-production')
DEBUG = os.environ.get('DEBUG', 'True') == 'True'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split(',')

# ── django-tenants ────────────────────────────────────
TENANT_MODEL = 'tenants.School'
TENANT_DOMAIN_MODEL = 'tenants.Domain'
PUBLIC_SCHEMA_NAME = 'public'
SHOW_PUBLIC_IF_NO_TENANT_FOUND = True

# ── Apps ──────────────────────────────────────────────
SHARED_APPS = [
    'django_tenants',
    'apps.tenants',
    'django.contrib.contenttypes',
    'django.contrib.auth',
    'django.contrib.admin',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    'crispy_forms',
    'crispy_bootstrap5',
    'widget_tweaks',
    'apps.authentication',
]

TENANT_APPS = [
    'apps.dashboard',
    'apps.students',
    'apps.academics',
    'apps.attendance',
    'apps.fees',
    'apps.staff',
    'apps.examinations',
    'apps.communication',
    'apps.library',
    'apps.transport',
    'apps.hostel',
    'apps.inventory',
    'apps.health',
    'apps.sports',
    'apps.visitor',
    'apps.alumni',
    'apps.reports',
    'apps.discipline',
    'apps.helpdesk',
    'apps.notifications',
    'apps.settings_app',
]

INSTALLED_APPS = list(SHARED_APPS) + [a for a in TENANT_APPS if a not in SHARED_APPS]

MIDDLEWARE = [
    'django_tenants.middleware.main.TenantMainMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'apps.dashboard.context_processors.school_context',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# ── PostgreSQL + django-tenants ───────────────────────
DATABASES = {
    'default': {
        'ENGINE': 'django_tenants.postgresql_backend',
        'NAME': os.environ.get('DB_NAME', 'edumanage_pro'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'your_password_here'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
        'CONN_MAX_AGE': 60,
    }
}

DATABASE_ROUTERS = ['django_tenants.routers.TenantSyncRouter']

# ── Auth ──────────────────────────────────────────────
AUTH_USER_MODEL = 'authentication.User'
LOGIN_URL = '/auth/login/'
LOGIN_REDIRECT_URL = '/dashboard/'
LOGOUT_REDIRECT_URL = '/auth/login/'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ── Static & Media ────────────────────────────────────
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

CRISPY_ALLOWED_TEMPLATE_PACKS = 'bootstrap5'
CRISPY_TEMPLATE_PACK = 'bootstrap5'

LANGUAGE_CODE = 'en-in'
TIME_ZONE = 'Asia/Kolkata'
USE_I18N = True
USE_TZ = True
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

MESSAGE_TAGS = {
    msg_const.DEBUG: 'secondary',
    msg_const.INFO: 'info',
    msg_const.SUCCESS: 'success',
    msg_const.WARNING: 'warning',
    msg_const.ERROR: 'danger',
}

EMAIL_BACKEND = os.environ.get('EMAIL_BACKEND', 'django.core.mail.backends.console.EmailBackend')
EMAIL_HOST = os.environ.get('EMAIL_HOST', 'smtp.gmail.com')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', 587))
EMAIL_USE_TLS = True
EMAIL_HOST_USER = os.environ.get('EMAIL_HOST_USER', '')
EMAIL_HOST_PASSWORD = os.environ.get('EMAIL_HOST_PASSWORD', '')
DEFAULT_FROM_EMAIL = os.environ.get('DEFAULT_FROM_EMAIL', 'noreply@edumanage.pro')

CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}

SESSION_COOKIE_AGE = 86400
FILE_UPLOAD_MAX_MEMORY_SIZE = 10 * 1024 * 1024

SUBSCRIPTION_PLANS = {
    'free':       {'max_students': 100,  'max_staff': 10},
    'basic':      {'max_students': 500,  'max_staff': 50},
    'standard':   {'max_students': 1500, 'max_staff': 150},
    'premium':    {'max_students': 5000, 'max_staff': 500},
    'enterprise': {'max_students': 0,    'max_staff': 0},
}
