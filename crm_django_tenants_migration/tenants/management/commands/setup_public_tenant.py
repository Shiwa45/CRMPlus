# tenants/management/commands/setup_public_tenant.py
"""
One-time bootstrap command for a fresh django-tenants installation.

Creates:
  1. The 'public' Tenant (required by django-tenants)
  2. A Domain entry for localhost
  3. A superadmin user

Usage:
    python manage.py setup_public_tenant
    python manage.py setup_public_tenant --domain=crm.mycompany.com
    python manage.py setup_public_tenant --no-superuser   (skip user creation)
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.db import transaction

User = get_user_model()


class Command(BaseCommand):
    help = 'Bootstrap the public tenant and superadmin user (run once after migrate_schemas --shared)'

    def add_arguments(self, parser):
        parser.add_argument('--domain',        default='localhost',
                            help='Primary domain for the public tenant (default: localhost)')
        parser.add_argument('--no-superuser',  action='store_true',
                            help='Skip superadmin user creation')
        parser.add_argument('--su-username',   default='superadmin')
        parser.add_argument('--su-email',      default='superadmin@easyian.com')
        parser.add_argument('--su-password',   default='superadmin123')

    def handle(self, *args, **options):
        from tenants.models import Tenant, Domain

        with transaction.atomic():
            # ── 1. Public Tenant ─────────────────────────────────────────
            public, created = Tenant.objects.get_or_create(
                schema_name='public',
                defaults={
                    'name':   'EasyIAN CRM Platform',
                    'slug':   'public',
                    'email':  'admin@easyian.com',
                    'status': 'active',
                },
            )
            if created:
                self.stdout.write(self.style.SUCCESS('  ✓ Public tenant created'))
            else:
                self.stdout.write('  · Public tenant already exists')

            # ── 2. Domain ─────────────────────────────────────────────────
            domain_val = options['domain']
            domain, created = Domain.objects.get_or_create(
                domain=domain_val,
                defaults={'tenant': public, 'is_primary': True},
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'  ✓ Domain "{domain_val}" created'))
            else:
                self.stdout.write(f'  · Domain "{domain_val}" already exists')

            # ── 3. Superadmin ─────────────────────────────────────────────
            if not options['no_superuser']:
                username = options['su_username']
                email    = options['su_email']
                password = options['su_password']

                user, created = User.objects.get_or_create(
                    username=username,
                    defaults={
                        'email':        email,
                        'first_name':   'Super',
                        'last_name':    'Admin',
                        'role':         'superadmin',
                        'is_staff':     True,
                        'is_superuser': True,
                        'is_active':    True,
                    },
                )
                if created:
                    user.set_password(password)
                    user.save()
                    self.stdout.write(self.style.SUCCESS(
                        f'  ✓ Superadmin "{username}" created (password: {password})'
                    ))
                    self.stdout.write(
                        self.style.WARNING('  ⚠  Change the password before going to production!')
                    )
                else:
                    self.stdout.write(f'  · Superadmin "{username}" already exists')

        self.stdout.write(self.style.SUCCESS('\n🎉 Public tenant bootstrap complete!'))
        self.stdout.write('\nNext steps:')
        self.stdout.write('  python manage.py seed_all_data   ← optional demo data')
        self.stdout.write('  python manage.py runserver')
