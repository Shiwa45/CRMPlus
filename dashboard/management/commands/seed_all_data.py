# dashboard/management/commands/seed_all_data.py  ← FULL REPLACEMENT
"""
Comprehensive multi-tenant CRM seed data — django-tenants edition.

Usage:
    python manage.py seed_all_data
    python manage.py seed_all_data --flush   (drops all tenant schemas and re-creates)

Key change from previous version:
    All tenant-scoped seeding is wrapped in  django_tenants.utils.tenant_context()
    which switches the active PostgreSQL schema before writing data.
"""
import random
import secrets
from datetime import timedelta, date
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth import get_user_model
from django_tenants.utils import tenant_context, get_public_schema_name

from tenants.models import Plan, Tenant, Domain, TenantUser, TenantInvitation, TenantAuditLog
from accounts.models import UserProfile

User = get_user_model()
NOW  = timezone.now()

# ── Indian data pools ──────────────────────────────────────────────────────────
FIRST_NAMES = ['Aarav','Vivaan','Aditya','Vihaan','Arjun','Sai','Reyansh','Ayaan','Krishna','Ishaan',
               'Ananya','Diya','Myra','Sara','Aadhya','Isha','Kavya','Riya','Priya','Neha']
LAST_NAMES  = ['Sharma','Patel','Gupta','Singh','Kumar','Reddy','Joshi','Verma','Mehta','Nair',
               'Iyer','Rao','Malhotra','Bhat','Chopra','Saxena','Bansal','Agarwal','Kapoor','Das']
CITIES = [('Mumbai','Maharashtra','400001'),('Delhi','Delhi','110001'),
          ('Bangalore','Karnataka','560001'),('Hyderabad','Telangana','500001'),
          ('Chennai','Tamil Nadu','600001'),('Pune','Maharashtra','411001'),
          ('Ahmedabad','Gujarat','380001'),('Kolkata','West Bengal','700001'),
          ('Jaipur','Rajasthan','302001'),('Lucknow','Uttar Pradesh','226001')]


def rdate(days_back=90):
    return NOW - timedelta(days=random.randint(0, days_back))


class Command(BaseCommand):
    help = 'Seed comprehensive demo data for all tenants (django-tenants edition)'

    def add_arguments(self, parser):
        parser.add_argument('--flush', action='store_true',
                            help='Drop all tenant data before seeding')

    def handle(self, *args, **options):
        if options['flush']:
            self._flush()

        # ── 1. Public schema — superadmin + plans ──────────────────────────────
        self.stdout.write(self.style.MIGRATE_HEADING('\n═══ Public Schema Setup ═══'))
        su    = self._create_superadmin()
        plans = self._create_plans()

        # ── 2. Create / ensure public tenant exists ────────────────────────────
        public_tenant, _ = Tenant.objects.get_or_create(
            schema_name='public',
            defaults={'name': 'EasyIAN CRM Platform', 'slug': 'public',
                      'email': 'admin@easyian.com', 'status': 'active'},
        )
        Domain.objects.get_or_create(
            domain='localhost', tenant=public_tenant,
            defaults={'is_primary': True},
        )
        self.stdout.write(self.style.SUCCESS('  ✓ Public tenant & domain'))

        # ── 3. Create tenants ──────────────────────────────────────────────────
        tenant_configs = [
            {'name': 'Sharma InfoTech Pvt Ltd', 'slug': 'sharma-infotech',
             'plan': plans['professional'], 'status': 'active',
             'gstin': '27AABCS1234F1ZP', 'pan': 'AABCS1234F',
             'city': 'Mumbai', 'state': 'Maharashtra', 'pincode': '400001',
             'phone': '+912228001234', 'email': 'info@sharmainfotech.in',
             'domain': 'sharma-infotech.localhost',
             'admin': ('sharma_admin', 'Rajesh', 'Sharma', 'rajesh@sharmainfotech.in'),
             'team': [
                 ('sharma_mgr',    'Priya', 'Mehta',  'priya@sharmainfotech.in',  'sales_manager'),
                 ('sharma_rep1',   'Aarav', 'Joshi',  'aarav@sharmainfotech.in',  'sales_rep'),
                 ('sharma_rep2',   'Diya',  'Verma',  'diya@sharmainfotech.in',   'sales_rep'),
                 ('sharma_support','Sai',   'Kumar',  'sai@sharmainfotech.in',    'support'),
             ]},
            {'name': 'Patel Trading Co', 'slug': 'patel-trading',
             'plan': plans['growth'], 'status': 'active',
             'gstin': '24AABCP5678G1ZQ', 'pan': 'AABCP5678G',
             'city': 'Ahmedabad', 'state': 'Gujarat', 'pincode': '380001',
             'phone': '+917928005678', 'email': 'hello@pateltrading.co.in',
             'domain': 'patel-trading.localhost',
             'admin': ('patel_admin', 'Nikhil', 'Patel', 'nikhil@pateltrading.co.in'),
             'team': [
                 ('patel_mgr', 'Kavya',  'Reddy', 'kavya@pateltrading.co.in',  'sales_manager'),
                 ('patel_rep1','Vihaan', 'Nair',  'vihaan@pateltrading.co.in', 'sales_rep'),
                 ('patel_mkt', 'Ananya', 'Das',   'ananya@pateltrading.co.in', 'marketing'),
             ]},
            {'name': 'Gupta Enterprises', 'slug': 'gupta-enterprises',
             'plan': plans['starter'], 'status': 'trial',
             'gstin': '09AABCG9012H1ZR', 'pan': 'AABCG9012H',
             'city': 'Lucknow', 'state': 'Uttar Pradesh', 'pincode': '226001',
             'phone': '+915224009012', 'email': 'contact@guptaenterprises.in',
             'domain': 'gupta-enterprises.localhost',
             'admin': ('gupta_admin', 'Amit', 'Gupta', 'amit@guptaenterprises.in'),
             'team': [
                 ('gupta_rep1', 'Ishaan', 'Bansal', 'ishaan@guptaenterprises.in', 'sales_rep'),
             ]},
        ]

        for tc in tenant_configs:
            self.stdout.write(self.style.MIGRATE_HEADING(f'\n═══ Tenant: {tc["name"]} ═══'))
            tenant, users = self._create_tenant_and_users(tc, su)

            # ── Switch into tenant's schema and seed all CRM data ──────────────
            with tenant_context(tenant):
                self.stdout.write(f'  Schema: {tenant.schema_name}')
                admin_user = users[0]
                sources    = self._seed_sources()
                categories = self._seed_ticket_categories()
                sla_policies = self._seed_sla_policies(admin_user)
                products   = self._seed_products(admin_user)
                self._seed_leads(admin_user, users, sources)
                companies  = self._seed_companies(admin_user, users)
                contacts   = self._seed_contacts(admin_user, users, companies)
                pipeline, stages = self._seed_pipeline(admin_user)
                deals      = self._seed_deals(admin_user, users, pipeline, stages,
                                              contacts, companies)
                self._seed_tickets(admin_user, users, categories, sla_policies,
                                   contacts, companies)
                self._seed_quotes_invoices(admin_user, users, products,
                                           contacts, companies, deals)
                self._seed_workflows(admin_user, users)
                self._seed_integrations(admin_user)
                self._seed_dashboard(users)

            self.stdout.write(self.style.SUCCESS(f'  ✓ {tc["name"]} complete'))

        self.stdout.write(self.style.SUCCESS('\n🎉 All seed data created successfully!'))
        self.stdout.write('  Superadmin login:  superadmin / superadmin123')
        self.stdout.write('  Tenant admins:     password123')

    # ══════════════════════════════════════════════════════════════════════════
    # Public-schema helpers (run outside tenant_context)
    # ══════════════════════════════════════════════════════════════════════════

    def _flush(self):
        self.stdout.write(self.style.WARNING('Flushing tenant schemas…'))
        for t in Tenant.objects.exclude(schema_name='public'):
            t.delete()   # TenantMixin.delete() drops the schema
        User.objects.exclude(username='superadmin').delete()
        self.stdout.write(self.style.SUCCESS('  ✓ Done'))

    def _create_superadmin(self):
        su, created = User.objects.get_or_create(
            username='superadmin',
            defaults={'email': 'superadmin@easyian.com', 'first_name': 'Super',
                      'last_name': 'Admin', 'role': 'superadmin',
                      'is_staff': True, 'is_superuser': True},
        )
        if created:
            su.set_password('superadmin123')
            su.save()
        self.stdout.write(self.style.SUCCESS('  ✓ Superadmin'))
        return su

    def _create_plans(self):
        plans_data = [
            ('Starter',      'starter',      999,    9990,  3,  200,  500,   50,  500, 1,  False, False, False),
            ('Growth',       'growth',       2499,  24990,  10, 1000, 2000, 200, 2000, 5,  True,  False, True),
            ('Professional', 'professional', 4999,  49990,  25, 5000,10000,1000, 5000, 20, True,  True,  True),
            ('Enterprise',   'enterprise',   9999,  99990,  0,  0,    0,    0,   0,   100, True,  True,  True),
        ]
        result = {}
        for i, (name, slug, pm, py, mu, ml, mc, md, me, mg, hw, ha, haa) in enumerate(plans_data):
            plan, _ = Plan.objects.update_or_create(
                slug=slug,
                defaults=dict(
                    name=name, price_monthly=pm, price_yearly=py,
                    max_users=mu, max_leads=ml, max_contacts=mc,
                    max_deals=md, max_emails_month=me, max_storage_gb=mg,
                    has_whatsapp=hw, has_ai=ha, has_api_access=haa,
                    is_active=True, sort_order=i,
                ),
            )
            result[slug] = plan
        self.stdout.write(self.style.SUCCESS(f'  ✓ {len(result)} Plans'))
        return result

    def _create_tenant_and_users(self, tc, su):
        # Create Tenant (schema auto-created by TenantMixin)
        tenant, _ = Tenant.objects.update_or_create(
            slug=tc['slug'],
            defaults={
                'name': tc['name'], 'plan': tc['plan'], 'status': tc['status'],
                'gstin': tc['gstin'], 'pan': tc['pan'],
                'address': f'{tc["city"]} Main Road',
                'city': tc['city'], 'state': tc['state'], 'pincode': tc['pincode'],
                'phone': tc['phone'], 'email': tc['email'], 'billing': 'monthly',
                'trial_ends': NOW + timedelta(days=14) if tc['status'] == 'trial' else None,
                'plan_ends':  NOW + timedelta(days=365) if tc['status'] == 'active' else None,
            },
        )

        # Create domain
        Domain.objects.get_or_create(
            domain=tc['domain'], tenant=tenant,
            defaults={'is_primary': True},
        )

        # Admin user (lives in public schema)
        au = tc['admin']
        admin_user, created = User.objects.get_or_create(
            username=au[0],
            defaults={'email': au[3], 'first_name': au[1], 'last_name': au[2],
                      'role': 'admin', 'is_staff': True},
        )
        if created:
            admin_user.set_password('password123')
            admin_user.save()
        self._profile(admin_user, f'Admin of {tc["name"]}', tc['city'])
        TenantUser.objects.update_or_create(
            tenant=tenant, user=admin_user,
            defaults={'role': 'tenant_admin'},
        )
        TenantUser.objects.update_or_create(
            tenant=tenant, user=su,
            defaults={'role': 'super_admin'},
        )

        users = [admin_user]
        for username, fn, ln, email, role in tc.get('team', []):
            u, created = User.objects.get_or_create(
                username=username,
                defaults={'email': email, 'first_name': fn, 'last_name': ln, 'role': role},
            )
            if created:
                u.set_password('password123')
                u.save()
            self._profile(u, f'{role} at {tc["name"]}', tc['city'])
            TenantUser.objects.update_or_create(
                tenant=tenant, user=u,
                defaults={'role': role},
            )
            users.append(u)

        self.stdout.write(f'  ✓ {len(users)} users created / linked')
        return tenant, users

    def _profile(self, user, bio, city_name):
        city_data = next((c for c in CITIES if c[0] == city_name), CITIES[0])
        UserProfile.objects.update_or_create(user=user, defaults={
            'bio': bio, 'city': city_data[0],
            'state': city_data[1], 'postal_code': city_data[2], 'country': 'India',
        })

    # ══════════════════════════════════════════════════════════════════════════
    # Tenant-schema helpers (all called INSIDE tenant_context)
    # ══════════════════════════════════════════════════════════════════════════

    def _seed_sources(self):
        from leads.models import LeadSource
        names = ['Website', 'Cold Call', 'LinkedIn', 'Referral', 'Email Campaign',
                 'Trade Show', 'Google Ads', 'Social Media', 'Partner', 'Inbound Call']
        sources = []
        for name in names:
            s, _ = LeadSource.objects.get_or_create(name=name)
            sources.append(s)
        self.stdout.write(f'  ✓ {len(sources)} LeadSources')
        return sources

    def _seed_leads(self, admin, users, sources):
        from leads.models import Lead, LeadActivity
        for i in range(random.randint(15, 25)):
            lead = Lead.objects.create(
                first_name=random.choice(FIRST_NAMES),
                last_name=random.choice(LAST_NAMES),
                email=f'lead{i}_{random.randint(1000,9999)}@example.com',
                phone=f'+91{random.randint(7000000000,9999999999)}',
                company=f'{random.choice(LAST_NAMES)} {random.choice(["Pvt Ltd","Co","Corp"])}',
                status=random.choice(['new','contacted','qualified','proposal','won','lost']),
                priority=random.choice(['hot','warm','cold']),
                source=random.choice(sources),
                assigned_to=random.choice(users),
                created_by=admin,
            )
            LeadActivity.objects.create(
                lead=lead,
                activity_type=random.choice(['call','email','note']),
                subject='Initial contact',
                notes='Demo activity',
                performed_by=random.choice(users),
            )
        self.stdout.write(f'  ✓ Leads seeded')

    def _seed_companies(self, admin, users):
        from contacts.models import Company
        companies = []
        industries = ['technology','manufacturing','retail','healthcare','finance']
        for i in range(random.randint(8, 12)):
            c = Company.objects.create(
                name=f'{random.choice(LAST_NAMES)} {random.choice(["Solutions","Industries","Corp"])} #{i}',
                industry=random.choice(industries),
                city=random.choice(CITIES)[0],
                country='India',
                created_by=admin,
            )
            companies.append(c)
        self.stdout.write(f'  ✓ {len(companies)} Companies')
        return companies

    def _seed_contacts(self, admin, users, companies):
        from contacts.models import Contact, ContactActivity
        contacts = []
        for i in range(random.randint(15, 20)):
            c = Contact.objects.create(
                first_name=random.choice(FIRST_NAMES),
                last_name=random.choice(LAST_NAMES),
                email=f'contact{i}_{random.randint(100,999)}@example.com',
                phone=f'+91{random.randint(7000000000,9999999999)}',
                company=random.choice(companies) if companies else None,
                created_by=admin,
            )
            contacts.append(c)
            ContactActivity.objects.create(
                contact=c, activity_type='call',
                subject='Introductory call', performed_by=random.choice(users),
            )
        self.stdout.write(f'  ✓ {len(contacts)} Contacts')
        return contacts

    def _seed_pipeline(self, admin):
        from deals.models import Pipeline, PipelineStage
        pipeline, _ = Pipeline.objects.get_or_create(
            name='Sales Pipeline',
            defaults={'is_default': True, 'description': 'Main sales pipeline',
                      'created_by': admin},
        )
        stage_data = [
            ('Discovery', 0, 10, '#6366f1'), ('Qualification', 1, 25, '#8b5cf6'),
            ('Proposal', 2, 50, '#a855f7'), ('Negotiation', 3, 75, '#d946ef'),
            ('Closed Won', 4, 100, '#22c55e'), ('Closed Lost', 5, 0, '#ef4444'),
        ]
        stages = []
        for name, order, prob, color in stage_data:
            s, _ = PipelineStage.objects.get_or_create(
                pipeline=pipeline, name=name,
                defaults={'order': order, 'probability': prob, 'color': color,
                          'is_won': name == 'Closed Won', 'is_lost': name == 'Closed Lost'},
            )
            stages.append(s)
        self.stdout.write(f'  ✓ Pipeline + {len(stages)} stages')
        return pipeline, stages

    def _seed_deals(self, admin, users, pipeline, stages, contacts, companies):
        from deals.models import Deal
        won  = next((s for s in stages if s.is_won), stages[0])
        lost = next((s for s in stages if s.is_lost), stages[-1])
        open_stages = [s for s in stages if not s.is_won and not s.is_lost]
        deals = []
        for i in range(random.randint(10, 15)):
            roll  = random.random()
            stage = won if roll < 0.2 else (lost if roll < 0.3 else random.choice(open_stages))
            d = Deal.objects.create(
                title=f'Deal #{i} — {random.choice(["CRM","License","Integration","Training"])}',
                pipeline=pipeline, stage=stage,
                value=Decimal(str(random.choice([25000,50000,100000,200000,500000]))),
                probability=stage.probability,
                owner=random.choice(users),
                created_by=admin,
                contact=random.choice(contacts) if contacts else None,
                company=random.choice(companies) if companies else None,
                close_date=date.today() + timedelta(days=random.randint(7, 90)),
            )
            deals.append(d)
        self.stdout.write(f'  ✓ {len(deals)} Deals')
        return deals

    def _seed_ticket_categories(self):
        from tickets.models import TicketCategory
        names = ['Technical Issue', 'Billing', 'Feature Request', 'General Inquiry', 'Bug Report']
        cats  = []
        for name in names:
            c, _ = TicketCategory.objects.get_or_create(name=name)
            cats.append(c)
        return cats

    def _seed_sla_policies(self, admin):
        from tickets.models import SLAPolicy
        policies = []
        for name, first, every, resolution in [('Standard', 8, 24, 72), ('Premium', 2, 8, 24)]:
            p, _ = SLAPolicy.objects.get_or_create(
                name=name,
                defaults={'first_response_hours': first,
                          'every_response_hours': every,
                          'resolution_hours': resolution,
                          'created_by': admin},
            )
            policies.append(p)
        return policies

    def _seed_tickets(self, admin, users, categories, sla_policies, contacts, companies):
        from tickets.models import Ticket
        for i in range(random.randint(8, 12)):
            Ticket.objects.create(
                subject=f'Support Ticket #{i}',
                description='Demo ticket description',
                status=random.choice(['open','in_progress','resolved','closed']),
                priority=random.choice(['low','medium','high','urgent']),
                category=random.choice(categories) if categories else None,
                sla_policy=random.choice(sla_policies) if sla_policies else None,
                assigned_to=None,
                created_by=admin,
                contact=random.choice(contacts) if contacts else None,
                company=random.choice(companies) if companies else None,
            )
        self.stdout.write(f'  ✓ Tickets seeded')

    def _seed_products(self, admin):
        from quotes.models import Product, TaxProfile
        tax, _ = TaxProfile.objects.get_or_create(
            name='GST 18%',
            defaults={'rate': Decimal('18.00'), 'created_by': admin},
        )
        products = []
        for name, price in [('CRM Basic', 999), ('CRM Pro', 2499), ('Enterprise', 4999),
                             ('WhatsApp Module', 1499), ('AI Module', 999)]:
            p, _ = Product.objects.get_or_create(
                name=name,
                defaults={'price': Decimal(str(price)), 'tax_profile': tax,
                          'created_by': admin},
            )
            products.append(p)
        return products

    def _seed_quotes_invoices(self, admin, users, products, contacts, companies, deals):
        from quotes.models import Quote, QuoteItem, Invoice, InvoiceItem
        for i in range(random.randint(3, 6)):
            q = Quote.objects.create(
                title=f'Quote #{i}',
                contact=random.choice(contacts) if contacts else None,
                company=random.choice(companies) if companies else None,
                deal=random.choice(deals) if deals else None,
                status=random.choice(['draft', 'sent', 'accepted']),
                valid_until=date.today() + timedelta(days=30),
                created_by=admin,
            )
            for product in random.sample(products, min(2, len(products))):
                QuoteItem.objects.create(
                    quote=q, product=product,
                    quantity=random.randint(1, 5),
                    unit_price=product.price,
                )
        self.stdout.write(f'  ✓ Quotes seeded')

    def _seed_workflows(self, admin, users):
        from workflows.models import Workflow
        for name in ['New Lead Auto-assign', 'Follow-up Reminder', 'Won Deal Notification']:
            Workflow.objects.get_or_create(
                name=name,
                defaults={'trigger': 'lead_created', 'is_active': False,
                          'created_by': admin},
            )
        self.stdout.write(f'  ✓ Workflows seeded')

    def _seed_integrations(self, admin):
        from integrations.models import Integration
        for service in ['gmail', 'whatsapp', 'slack']:
            Integration.objects.get_or_create(
                service=service,
                defaults={'is_active': False, 'created_by': admin},
            )

    def _seed_dashboard(self, users):
        from dashboard.models import DashboardWidget, DashboardPreference
        for u in users[:2]:
            for wtype, title, pos in [('stats_card', 'Overview', 0),
                                       ('chart', 'Revenue', 1),
                                       ('recent_leads', 'Leads', 2)]:
                DashboardWidget.objects.get_or_create(
                    user=u, widget_type=wtype,
                    defaults={'title': title, 'position': pos, 'is_visible': True},
                )
            DashboardPreference.objects.get_or_create(user=u)
        self.stdout.write(f'  ✓ Dashboard seeded')
