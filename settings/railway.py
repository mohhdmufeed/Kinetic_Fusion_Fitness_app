"""
Railway.app production settings for GetFit.
Reads all config from environment variables set in Railway dashboard.
"""
# ruff: noqa: F405, F403

import os

import environ

from .settings_global import *  # noqa: F403

env = environ.Env()

DEBUG = False

SECRET_KEY = os.environ['SECRET_KEY']

# Railway injects DATABASE_URL automatically when you add a Postgres plugin
DATABASES = {'default': env.db_url('DATABASE_URL')}

ALLOWED_HOSTS = ['*']

SITE_URL = os.environ.get('RAILWAY_PUBLIC_DOMAIN', 'http://localhost')
if SITE_URL and not SITE_URL.startswith('http'):
    SITE_URL = 'https://' + SITE_URL

CSRF_TRUSTED_ORIGINS = [f'https://{os.environ.get("RAILWAY_PUBLIC_DOMAIN", "localhost")}']

# Static & media files — serve from local disk (fine for a demo/friends)
STATIC_ROOT = os.path.join(BASE_DIR.parent, 'staticfiles')
STATIC_URL = '/static/'
MEDIA_ROOT = os.path.join(BASE_DIR.parent, 'media')
MEDIA_URL = '/media/'

# Email (console backend — emails show in Railway logs)
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
WGER_SETTINGS['EMAIL_FROM'] = 'GetFit <noreply@getfit.app>'
DEFAULT_FROM_EMAIL = WGER_SETTINGS['EMAIL_FROM']

# Application settings
WGER_SETTINGS['ALLOW_REGISTRATION'] = True
WGER_SETTINGS['ALLOW_GUEST_USERS'] = True
WGER_SETTINGS['USE_CELERY'] = False
WGER_SETTINGS['SYNC_EXERCISES_CELERY'] = False
WGER_SETTINGS['SYNC_INGREDIENTS_CELERY'] = False

# Cache (in-memory is fine for a small deployment)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}

# Turn off axes (login rate-limiting) — no Redis needed
AXES_ENABLED = False

# Disable compression (no node_modules on Railway)
COMPRESS_ENABLED = False
