#!/usr/bin/env python
"""Django's command-line utility for administrative tasks.

Updated for django-tenants: uses django_tenants.management so that
migrate_schemas, create_tenant, create_tenant_superuser, etc. are available.
"""
import os
import sys


def main():
    """Run administrative tasks."""
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'crm_project.settings')
    try:
        # django-tenants wraps Django's management to add tenant-aware commands
        from django_tenants.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import django-tenants. Make sure it's installed:\n"
            "    pip install django-tenants\n"
            "and that your virtual environment is activated."
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
