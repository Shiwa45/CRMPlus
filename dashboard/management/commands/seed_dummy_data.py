# dashboard/management/commands/seed_dummy_data.py
import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth import get_user_model

# App models
from leads.models import Lead, LeadSource
from contacts.models import Contact, Company
from deals.models import Deal, Pipeline, PipelineStage
from tickets.models import Ticket, TicketCategory, SLAPolicy
from workflows.models import Task

User = get_user_model()

class Command(BaseCommand):
    help = 'Populates the CRM with realistic dummy data for testing the dashboard'

    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING('Seeding dummy data...'))

        # 1. Ensure Lead Sources exist
        sources = ['Website', 'Referral', 'Google Ads', 'Cold Call', 'LinkedIn']
        source_objs = []
        for s in sources:
            obj, _ = LeadSource.objects.get_or_create(name=s)
            source_objs.append(obj)

        # 2. Get/Create Users
        admin, _ = User.objects.get_or_create(username='admin', defaults={'email': 'admin@example.com', 'is_superuser': True, 'is_staff': True, 'role': 'superadmin'})
        if _: admin.set_password('admin123'); admin.save()

        sales_mgr, _ = User.objects.get_or_create(username='manager', defaults={'email': 'manager@example.com', 'role': 'sales_manager', 'first_name': 'Sales', 'last_name': 'Manager'})
        if _: sales_mgr.set_password('pass123'); sales_mgr.save()

        sales_rep, _ = User.objects.get_or_create(username='rep', defaults={'email': 'rep@example.com', 'role': 'sales_rep', 'first_name': 'John', 'last_name': 'Doe'})
        if _: sales_rep.set_password('pass123'); sales_rep.save()

        sales_rep2, _ = User.objects.get_or_create(username='rep2', defaults={'email': 'rep2@example.com', 'role': 'sales_rep', 'first_name': 'Jane', 'last_name': 'Smith'})
        if _: sales_rep2.set_password('pass123'); sales_rep2.save()

        users = [admin, sales_mgr, sales_rep, sales_rep2]

        # Ensure pipeline exists
        pipeline, _ = Pipeline.objects.get_or_create(name='Sales Pipeline', defaults={'is_default': True, 'created_by': admin})
        if _:
            for i, name in enumerate(['New', 'Qualified', 'Proposal', 'Won', 'Lost']):
                PipelineStage.objects.get_or_create(pipeline=pipeline, name=name, order=i, probability=i*25 if name != 'Lost' else 0, is_won=(name=='Won'), is_lost=(name=='Lost'))
        stages = list(PipelineStage.objects.filter(pipeline=pipeline))
        won_stage = next((s for s in stages if s.is_won), stages[-2] if len(stages) > 1 else None)
        open_stages = [s for s in stages if not s.is_won and not s.is_lost]

        now = timezone.now()

        import string
        run_suffix = ''.join(random.choices(string.ascii_lowercase + string.digits, k=4))

        # 3. Create Leads (Generate across the last 6 months)
        lead_statuses = ['new', 'contacted', 'qualified', 'proposal', 'negotiation', 'won', 'lost']
        lead_priorities = ['cold', 'warm', 'hot']
        
        created_leads = 0
        self.stdout.write("Generating Leads...")
        for i in range(50):
            days_ago = random.randint(0, 180)
            created_at = now - timedelta(days=days_ago)

            status = random.choice(lead_statuses)
            priority = random.choice(lead_priorities)
            source = random.choice(source_objs)
            assigned = random.choice(users)

            lead = Lead(
                first_name=f'Dummy {i} {run_suffix}',
                last_name=f'Lead {i}',
                email=f'lead{i}_{run_suffix}@example.com',
                phone=f'+1555{random.randint(1000, 9999)}',
                company=f'Company {i} LLC {run_suffix}',
                status=status,
                priority=priority,
                source=source,
                budget=random.randint(500, 10000),
                assigned_to=assigned,
                created_by=admin,
                last_contacted=now - timedelta(days=random.randint(1, 20)) if status != 'new' else None
            )
            lead.save()
            lead.created_at = created_at
            lead.save(update_fields=['created_at'])
            created_leads += 1

        # 4. Create Companies and Contacts
        self.stdout.write("Generating Contacts and Companies...")
        companies = []
        for i in range(10):
            c, created = Company.objects.get_or_create(
                name=f'Partner Corp {i} {run_suffix}',
                defaults={
                    'industry': 'Tech',
                    'website': f'www.partner{i}_{run_suffix}.com',
                    'created_by': admin,
                    'owner': random.choice(users)
                }
            )
            if created:
                c.created_at = now - timedelta(days=random.randint(0, 100))
                c.save(update_fields=['created_at'])
            companies.append(c)

        for i in range(20):
            contact = Contact.objects.create(
                first_name=f'Contact {i} {run_suffix}',
                email=f'contact{i}_{run_suffix}@example.com',
                company=random.choice(companies),
                created_by=admin,
                owner=random.choice(users)
            )
            contact.created_at = now - timedelta(days=random.randint(0, 100))
            contact.save(update_fields=['created_at'])

        # 5. Create Deals
        self.stdout.write("Generating Deals...")
        for i in range(30):
            is_won = random.choice([True, False, False])
            stage = won_stage if is_won and won_stage else random.choice(open_stages) if open_stages else None
            
            days_ago = random.randint(0, 90)
            created_at = now - timedelta(days=days_ago)
            
            if stage:
                d = Deal.objects.create(
                    title=f'Deal {i} Project {run_suffix}',
                    pipeline=pipeline,
                    stage=stage,
                    value=random.randint(1000, 50000),
                    close_date=(created_at + timedelta(days=30)).date(),
                    owner=random.choice(users),
                    created_by=admin,
                    company=random.choice(companies) if random.choice([True, False]) else None
                )
                d.created_at = created_at
                if is_won:
                    d.won_at = created_at + timedelta(days=15)
                d.save()

        # 6. Create Tickets
        cat, _ = TicketCategory.objects.get_or_create(name='General Support')
        sla, _ = SLAPolicy.objects.get_or_create(name='Standard', defaults={'priority': 'medium', 'first_response_hours': 8, 'resolution_hours': 24})

        self.stdout.write("Generating Tickets...")
        for i in range(15):
            t = Ticket.objects.create(
                subject=f'Help request #{i}',
                description='Can you assist me with my account?',
                status=random.choice(['open', 'in_progress', 'resolved', 'closed']),
                priority=random.choice(['low', 'medium', 'high']),
                category=cat,
                sla_policy=sla,
                assigned_to=random.choice(users),
                created_by=admin
            )
            t.created_at = now - timedelta(days=random.randint(0, 30))
            if t.status in ['resolved', 'closed']:
                t.resolved_at = t.created_at + timedelta(hours=random.randint(1, 48))
            t.save()

        # 7. Create Tasks
        self.stdout.write("Generating Tasks...")
        for i in range(25):
            days_offset = random.randint(-10, 10)
            Task.objects.create(
                title=f'Follow up call {i}',
                task_type='call',
                status='todo' if days_offset > 0 else random.choice(['todo', 'completed']),
                priority=random.choice(['low', 'medium', 'high']),
                due_date=now + timedelta(days=days_offset),
                assigned_to=random.choice(users),
                created_by=admin
            )

        self.stdout.write(self.style.SUCCESS('✅ Successfully seeded dummy data for the Dashboard!'))
