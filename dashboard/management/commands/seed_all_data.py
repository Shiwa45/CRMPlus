# dashboard/management/commands/seed_all_data.py
"""
Comprehensive multi-tenant CRM seed data.
Usage:  python manage.py seed_all_data
        python manage.py seed_all_data --flush   (wipes DB first)
"""
import random, uuid
from datetime import timedelta, date
from decimal import Decimal
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.contrib.auth import get_user_model

from tenants.models import Plan, Tenant, TenantUser, TenantInvitation, TenantAuditLog
from accounts.models import UserProfile
from leads.models import Lead, LeadSource, LeadActivity
from contacts.models import Company, Contact, ContactActivity
from deals.models import Pipeline, PipelineStage, Deal, DealActivity, DealStageHistory
from tickets.models import TicketCategory, SLAPolicy, Ticket, TicketReply, TicketActivity
from communications.models import (EmailConfiguration, EmailTemplate, EmailCampaign,
                                    Email, EmailSequence, EmailSequenceStep)
from integrations.models import Integration, WhatsAppTemplate
from workflows.models import Workflow, WorkflowCondition, WorkflowAction, Notification, Task
from quotes.models import TaxProfile, Product, Quote, QuoteItem, Invoice, InvoiceItem, Payment
from dashboard.models import DashboardWidget, DashboardPreference, KPITarget, NotificationPreference

User = get_user_model()
NOW = timezone.now()

# ─── Indian realistic data pools ──────────────────────────────────────
FIRST_NAMES = ['Aarav','Vivaan','Aditya','Vihaan','Arjun','Sai','Reyansh','Ayaan','Krishna','Ishaan',
               'Ananya','Diya','Myra','Sara','Aadhya','Isha','Kavya','Riya','Priya','Neha']
LAST_NAMES = ['Sharma','Patel','Gupta','Singh','Kumar','Reddy','Joshi','Verma','Mehta','Nair',
              'Iyer','Rao','Malhotra','Bhat','Chopra','Saxena','Bansal','Agarwal','Kapoor','Das']
CITIES = [('Mumbai','Maharashtra','400001'),('Delhi','Delhi','110001'),('Bangalore','Karnataka','560001'),
          ('Hyderabad','Telangana','500001'),('Chennai','Tamil Nadu','600001'),('Pune','Maharashtra','411001'),
          ('Ahmedabad','Gujarat','380001'),('Kolkata','West Bengal','700001'),('Jaipur','Rajasthan','302001'),
          ('Lucknow','Uttar Pradesh','226001')]
INDUSTRIES = ['technology','manufacturing','retail','healthcare','finance','education','real_estate',
              'pharma','automotive','fmcg']
COMPANY_SUFFIXES = ['Pvt Ltd','Solutions','Industries','Technologies','Enterprises','Corp','Systems',
                    'Services','Group','Digital']
JOB_TITLES = ['CEO','CTO','CFO','VP Sales','Director','Manager','Sr. Engineer','Consultant',
              'Business Head','Account Manager']

def rdate(days_back=180):
    return NOW - timedelta(days=random.randint(0, days_back))

def rphone():
    return f'+91{random.randint(70000,99999)}{random.randint(10000,99999)}'

def rname():
    return random.choice(FIRST_NAMES), random.choice(LAST_NAMES)

def rcity():
    return random.choice(CITIES)


class Command(BaseCommand):
    help = 'Seeds the CRM with comprehensive multi-tenant dummy data'

    def add_arguments(self, parser):
        parser.add_argument('--flush', action='store_true', help='Delete all existing data first')

    def handle(self, *args, **opts):
        if opts['flush']:
            self.stdout.write(self.style.WARNING('⚠ Flushing all data...'))
            for M in [Payment,InvoiceItem,Invoice,QuoteItem,Quote,TaxProfile,Product,
                       TicketActivity,TicketReply,Ticket,SLAPolicy,TicketCategory,
                       DealStageHistory,DealActivity,Deal,PipelineStage,Pipeline,
                       ContactActivity,Contact,Company,LeadActivity,Lead,LeadSource,
                       EmailSequenceStep,EmailSequence,EmailCampaign,Email,EmailTemplate,
                       EmailConfiguration,WhatsAppTemplate,Integration,
                       WorkflowAction,WorkflowCondition,Workflow,Notification,Task,
                       KPITarget,NotificationPreference,DashboardPreference,DashboardWidget,
                       TenantAuditLog,TenantInvitation,TenantUser,UserProfile]:
                M.objects.all().delete()
            Tenant.objects.all().delete()
            Plan.objects.all().delete()
            User.objects.all().delete()
            self.stdout.write(self.style.SUCCESS('  ✓ Flushed'))

        # ── 1. Plans ──
        Plan.seed()
        plans = {p.name: p for p in Plan.objects.all()}
        self.stdout.write(self.style.SUCCESS('✓ Plans seeded'))

        # ── 2. Superuser ──
        su, created = User.objects.get_or_create(username='superadmin', defaults={
            'email':'superadmin@easyian.com','first_name':'Super','last_name':'Admin',
            'role':'superadmin','is_superuser':True,'is_staff':True})
        if created:
            su.set_password('superadmin123'); su.save()
        self._profile(su, 'Platform superadmin', 'Mumbai')
        self.stdout.write(self.style.SUCCESS(f'✓ Superuser: superadmin / superadmin123'))

        # ── 3. Shared lookup data ──
        sources = self._seed_sources()
        categories = self._seed_ticket_categories()
        sla_policies = self._seed_sla_policies(su)
        products = self._seed_products(su)

        # ── 4. Tenants ──
        tenant_configs = [
            {'name':'Sharma InfoTech Pvt Ltd','slug':'sharma-infotech','plan':plans['professional'],
             'status':'active','gstin':'27AABCS1234F1ZP','pan':'AABCS1234F',
             'city':'Mumbai','state':'Maharashtra','pincode':'400001',
             'phone':'+912228001234','email':'info@sharmainfotech.in',
             'admin':('sharma_admin','Rajesh','Sharma','rajesh@sharmainfotech.in'),
             'team':[('sharma_mgr','Priya','Mehta','priya@sharmainfotech.in','sales_manager'),
                     ('sharma_rep1','Aarav','Joshi','aarav@sharmainfotech.in','sales_rep'),
                     ('sharma_rep2','Diya','Verma','diya@sharmainfotech.in','sales_rep'),
                     ('sharma_support','Sai','Kumar','sai@sharmainfotech.in','support')]},
            {'name':'Patel Trading Co','slug':'patel-trading','plan':plans['growth'],
             'status':'active','gstin':'24AABCP5678G1ZQ','pan':'AABCP5678G',
             'city':'Ahmedabad','state':'Gujarat','pincode':'380001',
             'phone':'+917928005678','email':'hello@pateltrading.co.in',
             'admin':('patel_admin','Nikhil','Patel','nikhil@pateltrading.co.in'),
             'team':[('patel_mgr','Kavya','Reddy','kavya@pateltrading.co.in','sales_manager'),
                     ('patel_rep1','Vihaan','Nair','vihaan@pateltrading.co.in','sales_rep'),
                     ('patel_mkt','Ananya','Das','ananya@pateltrading.co.in','marketing')]},
            {'name':'Gupta Enterprises','slug':'gupta-enterprises','plan':plans['starter'],
             'status':'trial','gstin':'09AABCG9012H1ZR','pan':'AABCG9012H',
             'city':'Lucknow','state':'Uttar Pradesh','pincode':'226001',
             'phone':'+915224009012','email':'contact@guptaenterprises.in',
             'admin':('gupta_admin','Amit','Gupta','amit@guptaenterprises.in'),
             'team':[('gupta_rep1','Ishaan','Bansal','ishaan@guptaenterprises.in','sales_rep')]},
        ]

        for tc in tenant_configs:
            self.stdout.write(self.style.MIGRATE_HEADING(f'\n═══ Tenant: {tc["name"]} ═══'))
            tenant, users = self._create_tenant_and_users(tc, su)
            admin_user = users[0]
            all_users = users

            self._seed_leads(tenant, all_users, admin_user, sources)
            companies = self._seed_companies(tenant, all_users, admin_user)
            contacts = self._seed_contacts(tenant, all_users, admin_user, companies)
            pipeline, stages = self._seed_pipeline(tenant, admin_user)
            deals = self._seed_deals(tenant, all_users, admin_user, pipeline, stages, contacts, companies)
            self._seed_tickets(tenant, all_users, admin_user, categories, sla_policies, contacts, companies)
            self._seed_quotes_invoices(tenant, all_users, admin_user, products, contacts, companies, deals)
            self._seed_workflows(tenant, admin_user, all_users)
            self._seed_communications(tenant, admin_user, all_users)
            self._seed_integrations(tenant, admin_user)
            self._seed_dashboard(tenant, all_users)
            self._seed_audit_logs(tenant, all_users)
            self.stdout.write(self.style.SUCCESS(f'  ✓ {tc["name"]} complete'))

        self.stdout.write(self.style.SUCCESS('\n🎉 All seed data created successfully!'))
        self.stdout.write('  Superadmin login: superadmin / superadmin123')
        self.stdout.write('  Tenant admin passwords: password123')

    # ═══════════════════════════════════════════════════════════════════
    # Helper methods
    # ═══════════════════════════════════════════════════════════════════

    def _profile(self, user, bio, city_name):
        city_data = next((c for c in CITIES if c[0]==city_name), CITIES[0])
        UserProfile.objects.update_or_create(user=user, defaults={
            'bio':bio,'city':city_data[0],'state':city_data[1],
            'postal_code':city_data[2],'country':'India'})

    def _create_tenant_and_users(self, tc, su):
        tenant, _ = Tenant.objects.update_or_create(slug=tc['slug'], defaults={
            'name':tc['name'],'plan':tc['plan'],'status':tc['status'],
            'gstin':tc['gstin'],'pan':tc['pan'],'address':f'{tc["city"]} Main Road',
            'city':tc['city'],'state':tc['state'],'pincode':tc['pincode'],
            'phone':tc['phone'],'email':tc['email'],'billing':'monthly',
            'trial_ends': NOW + timedelta(days=14) if tc['status']=='trial' else None,
            'plan_ends': NOW + timedelta(days=365) if tc['status']=='active' else None,
        })
        # Admin user
        au = tc['admin']
        admin_user, c = User.objects.get_or_create(username=au[0], defaults={
            'email':au[3],'first_name':au[1],'last_name':au[2],
            'role':'admin','is_staff':True})
        if c: admin_user.set_password('password123'); admin_user.save()
        self._profile(admin_user, f'Admin of {tc["name"]}', tc['city'])
        TenantUser.objects.update_or_create(tenant=tenant, user=admin_user,
            defaults={'role':'tenant_admin'})
        # Also link superadmin
        TenantUser.objects.update_or_create(tenant=tenant, user=su,
            defaults={'role':'super_admin'})

        users = [admin_user]
        for t in tc['team']:
            u, c = User.objects.get_or_create(username=t[0], defaults={
                'email':t[3],'first_name':t[1],'last_name':t[2],'role':t[4]})
            if c: u.set_password('password123'); u.save()
            self._profile(u, f'{t[4].replace("_"," ").title()} at {tc["name"]}', tc['city'])
            TenantUser.objects.update_or_create(tenant=tenant, user=u,
                defaults={'role':t[4]})
            users.append(u)

        self.stdout.write(f'  ✓ Tenant + {len(users)} users')
        return tenant, users

    def _seed_sources(self):
        names = ['Website','Referral','Google Ads','LinkedIn','Trade Show','Cold Call',
                 'WhatsApp','IndiaMART','JustDial','Email Campaign']
        objs = []
        for n in names:
            o, _ = LeadSource.objects.get_or_create(name=n, defaults={'description':f'Leads from {n}'})
            objs.append(o)
        self.stdout.write(self.style.SUCCESS(f'✓ {len(objs)} Lead Sources'))
        return objs

    def _seed_ticket_categories(self):
        cats = [('Billing & Payments','#ef4444'),('Technical Support','#3b82f6'),
                ('Account Management','#f59e0b'),('Product Inquiry','#10b981'),
                ('Onboarding','#8b5cf6'),('Bug Report','#ec4899')]
        objs = []
        for name, color in cats:
            o, _ = TicketCategory.objects.get_or_create(name=name, defaults={'color':color})
            objs.append(o)
        self.stdout.write(self.style.SUCCESS(f'✓ {len(objs)} Ticket Categories'))
        return objs

    def _seed_sla_policies(self, su):
        slas = [('Critical SLA','critical',1,4),('High SLA','high',2,8),
                ('Medium SLA','medium',4,24),('Low SLA','low',8,48)]
        objs = []
        for name, pri, resp, res in slas:
            o, _ = SLAPolicy.objects.get_or_create(name=name, defaults={
                'priority':pri,'first_response_hours':resp,'resolution_hours':res,
                'escalate_to':su})
            objs.append(o)
        self.stdout.write(self.style.SUCCESS(f'✓ {len(objs)} SLA Policies'))
        return objs

    def _seed_products(self, su):
        prods = [
            ('CRM Basic License','CRM-LIC-001','service','998314','nos',4999,18),
            ('CRM Premium License','CRM-LIC-002','service','998314','nos',9999,18),
            ('Custom Development','CRM-DEV-001','service','998314','hr',2500,18),
            ('Annual Maintenance','CRM-AMC-001','service','998314','month',1999,18),
            ('Data Migration','CRM-MIG-001','service','998314','nos',14999,18),
            ('Training Session','CRM-TRN-001','service','998314','hr',1500,18),
            ('Server Hosting','CRM-HST-001','service','998315','month',3499,18),
            ('SMS Pack - 10K','CRM-SMS-001','product','998319','nos',2000,18),
        ]
        objs = []
        for name, code, ptype, hsn, unit, price, gst in prods:
            o, _ = Product.objects.get_or_create(code=code, defaults={
                'name':name,'product_type':ptype,'hsn_sac_code':hsn,
                'unit':unit,'unit_price':Decimal(str(price)),'gst_rate':gst,'created_by':su})
            objs.append(o)
        self.stdout.write(self.style.SUCCESS(f'✓ {len(objs)} Products'))
        return objs

    # ── Per-Tenant Seeds ──────────────────────────────────────────────

    def _seed_leads(self, tenant, users, admin, sources):
        statuses = ['new','contacted','qualified','proposal','negotiation','won','lost','on_hold']
        priorities = ['hot','warm','cold']
        leads = []
        for i in range(random.randint(15, 20)):
            fn, ln = rname()
            city, state, pin = rcity()
            status = random.choice(statuses)
            created = rdate(180)
            lead = Lead.objects.create(
                first_name=fn, last_name=ln,
                email=f'{fn.lower()}.{ln.lower()}{i}@example.com',
                phone=rphone(), company=f'{ln} {random.choice(COMPANY_SUFFIXES)}',
                job_title=random.choice(JOB_TITLES),
                source=random.choice(sources), status=status,
                priority=random.choice(priorities),
                assigned_to=random.choice(users), created_by=admin,
                city=city, state=state, country='India', postal_code=pin,
                budget=Decimal(str(random.randint(10000, 500000))),
                requirements=f'Looking for CRM solution for {random.randint(10,500)} users',
                last_contacted=rdate(30) if status != 'new' else None)
            Lead.objects.filter(pk=lead.pk).update(created_at=created)
            leads.append(lead)
            # Activities
            for _ in range(random.randint(1, 3)):
                LeadActivity.objects.create(
                    lead=lead, user=random.choice(users),
                    activity_type=random.choice(['call','email','meeting','note']),
                    subject=random.choice(['Initial discussion','Follow-up call',
                        'Sent proposal','Requirements gathering','Demo scheduled']),
                    description='Activity logged during sales process.')
        self.stdout.write(f'  ✓ {len(leads)} Leads + activities')
        return leads

    def _seed_companies(self, tenant, users, admin):
        companies = []
        for i in range(random.randint(5, 8)):
            fn, ln = rname()
            city, state, pin = rcity()
            ind = random.choice(INDUSTRIES)
            name = f'{ln} {random.choice(COMPANY_SUFFIXES)}'
            # Ensure unique name
            name = f'{name} {tenant.slug[:3].upper()}'
            c = Company.objects.create(
                name=name, website=f'https://www.{name.lower().replace(" ","")}.in',
                phone=rphone(), email=f'info@{name.lower().replace(" ","")}.in',
                industry=ind, employee_size=random.choice(['1-10','11-50','51-200','201-500']),
                annual_revenue=Decimal(str(random.randint(500000, 50000000))),
                gstin=f'{random.randint(10,37)}AABCX{random.randint(1000,9999)}X1Z{random.randint(1,9)}',
                address_line1=f'{random.randint(1,500)}, {city} Business Park',
                city=city, state=state, postal_code=pin,
                owner=random.choice(users), created_by=admin)
            companies.append(c)
        self.stdout.write(f'  ✓ {len(companies)} Companies')
        return companies

    def _seed_contacts(self, tenant, users, admin, companies):
        contacts = []
        for i in range(random.randint(8, 12)):
            fn, ln = rname()
            city, state, pin = rcity()
            c = Contact.objects.create(
                salutation=random.choice(['mr','mrs','ms','dr']),
                first_name=fn, last_name=ln,
                job_title=random.choice(JOB_TITLES),
                department=random.choice(['Sales','Engineering','Finance','Operations','HR']),
                company=random.choice(companies) if companies else None,
                email=f'{fn.lower()}.{ln.lower()}{i}@{random.choice(["gmail.com","outlook.com","company.in"])}',
                phone=rphone(), mobile=rphone(),
                whatsapp=rphone(),
                address_line1=f'{random.randint(1,999)}, {city} Road',
                city=city, state=state, postal_code=pin,
                tags=['prospect','vip'] if random.random() > 0.7 else ['prospect'],
                owner=random.choice(users), created_by=admin)
            contacts.append(c)
            # Contact activities
            for _ in range(random.randint(1, 2)):
                ContactActivity.objects.create(
                    contact=c, activity_type=random.choice(['call','email','meeting','whatsapp']),
                    subject=random.choice(['Introductory call','Sent brochure','Meeting at office','WhatsApp follow-up']),
                    description='Routine follow-up activity.',
                    outcome=random.choice(['Interested','Will revert','Needs more info','']),
                    performed_by=random.choice(users))
        self.stdout.write(f'  ✓ {len(contacts)} Contacts + activities')
        return contacts

    def _seed_pipeline(self, tenant, admin):
        pipeline, _ = Pipeline.objects.get_or_create(
            name=f'Sales Pipeline', created_by=admin,
            defaults={'is_default':True, 'description':'Main sales pipeline'})
        stage_data = [('Discovery',0,10,'#6366f1'),('Qualification',1,25,'#8b5cf6'),
                      ('Proposal',2,50,'#a855f7'),('Negotiation',3,75,'#d946ef'),
                      ('Closed Won',4,100,'#22c55e'),('Closed Lost',5,0,'#ef4444')]
        stages = []
        for name, order, prob, color in stage_data:
            s, _ = PipelineStage.objects.get_or_create(
                pipeline=pipeline, name=name,
                defaults={'order':order,'probability':prob,'color':color,
                          'is_won':name=='Closed Won','is_lost':name=='Closed Lost'})
            stages.append(s)
        self.stdout.write(f'  ✓ Pipeline + {len(stages)} stages')
        return pipeline, stages

    def _seed_deals(self, tenant, users, admin, pipeline, stages, contacts, companies):
        won = next((s for s in stages if s.is_won), stages[0])
        lost = next((s for s in stages if s.is_lost), stages[-1])
        open_stages = [s for s in stages if not s.is_won and not s.is_lost]
        deals = []
        for i in range(random.randint(10, 15)):
            roll = random.random()
            stage = won if roll < 0.2 else (lost if roll < 0.3 else random.choice(open_stages))
            created = rdate(120)
            value = Decimal(str(random.choice([25000,50000,75000,100000,200000,500000,1000000])))
            d = Deal.objects.create(
                title=random.choice(['CRM Implementation','Annual License Renewal',
                    'Custom Module Development','Data Migration Project','Cloud Hosting Setup',
                    'Training Package','Enterprise Upgrade','WhatsApp Integration',
                    'API Integration Project','Support Contract']) + f' #{i}',
                pipeline=pipeline, stage=stage,
                priority=random.choice(['critical','high','medium','low']),
                value=value, currency='INR',
                contact=random.choice(contacts) if contacts else None,
                company=random.choice(companies) if companies else None,
                owner=random.choice(users), created_by=admin,
                close_date=(created + timedelta(days=random.randint(15,90))).date(),
                description=f'Deal for {tenant.name}',
                tags=['enterprise'] if value > 500000 else ['smb'],
                lead_source=random.choice(['Website','Referral','LinkedIn','Trade Show']))
            Deal.objects.filter(pk=d.pk).update(created_at=created)
            deals.append(d)
            # Deal activity
            for _ in range(random.randint(1, 2)):
                DealActivity.objects.create(
                    deal=d, activity_type=random.choice(['call','email','meeting','demo','proposal']),
                    subject=random.choice(['Discovery call','Sent proposal','Product demo','Price negotiation']),
                    description='Deal progress activity.',
                    performed_by=random.choice(users), status='done')
        self.stdout.write(f'  ✓ {len(deals)} Deals + activities')
        return deals

    def _seed_tickets(self, tenant, users, admin, categories, slas, contacts, companies):
        tickets = []
        for i in range(random.randint(8, 10)):
            pri = random.choice(['critical','high','medium','low'])
            sla = next((s for s in slas if s.priority == pri), slas[0])
            status = random.choice(['open','in_progress','waiting','resolved','closed'])
            t = Ticket.objects.create(
                subject=random.choice([
                    'Unable to login to dashboard','Invoice not generating correctly',
                    'Need help with WhatsApp setup','Data import failing','Slow performance on reports',
                    'Feature request: bulk email','Password reset not working',
                    'API integration error','Mobile app crashing','Need user training']),
                description=f'Support ticket for {tenant.name}. Need assistance with this issue.',
                status=status, priority=pri,
                channel=random.choice(['email','phone','whatsapp','web']),
                contact=random.choice(contacts) if contacts and random.random()>0.3 else None,
                company=random.choice(companies) if companies and random.random()>0.5 else None,
                category=random.choice(categories), sla_policy=sla,
                assigned_to=random.choice(users), created_by=admin,
                tags=['urgent'] if pri in ['critical','high'] else [])
            created = rdate(60)
            Ticket.objects.filter(pk=t.pk).update(created_at=created)
            if status in ['resolved','closed']:
                Ticket.objects.filter(pk=t.pk).update(
                    resolved_at=created + timedelta(hours=random.randint(1,48)))
            tickets.append(t)
            # Replies
            TicketReply.objects.create(
                ticket=t, reply_type='reply', body='Thank you for reaching out. We are looking into this.',
                is_public=True, author=random.choice(users))
            if random.random() > 0.5:
                TicketReply.objects.create(
                    ticket=t, reply_type='note', body='Internal: Escalated to engineering team.',
                    is_public=False, author=admin)
        self.stdout.write(f'  ✓ {len(tickets)} Tickets + replies')

    def _seed_quotes_invoices(self, tenant, users, admin, products, contacts, companies, deals):
        # Tax profile per tenant
        tp, _ = TaxProfile.objects.get_or_create(
            name=tenant.name, defaults={
                'gstin':tenant.gstin,'pan':tenant.pan,
                'address':tenant.address,'city':tenant.city,
                'state':'MH' if tenant.state=='Maharashtra' else ('GJ' if tenant.state=='Gujarat' else 'UP'),
                'postal_code':tenant.pincode,'phone':tenant.phone,'email':tenant.email,
                'bank_name':'State Bank of India','bank_account':f'{random.randint(10000000000,99999999999)}',
                'bank_ifsc':'SBIN0001234','bank_branch':f'{tenant.city} Main Branch',
                'upi_id':f'{tenant.slug}@sbi'})

        quotes_created = 0
        invoices_created = 0
        for i in range(random.randint(3, 4)):
            contact = random.choice(contacts) if contacts else None
            company = random.choice(companies) if companies else None
            deal = random.choice(deals) if deals else None
            q = Quote.objects.create(
                title=f'Quote for {company.name if company else "Customer"} #{i+1}',
                status=random.choice(['draft','sent','accepted']),
                tax_profile=tp,
                contact=contact, company=company, deal=deal,
                bill_to_name=company.name if company else 'Customer',
                bill_to_gstin=company.gstin if company else '',
                bill_to_city=company.city if company else tenant.city,
                bill_to_state='MH' if tenant.state=='Maharashtra' else ('GJ' if tenant.state=='Gujarat' else 'UP'),
                supply_type='intra',
                valid_until=(NOW + timedelta(days=30)).date(),
                terms='Payment within 30 days. GST extra as applicable.',
                owner=random.choice(users), created_by=admin)
            # Quote items
            for j in range(random.randint(2, 3)):
                prod = random.choice(products)
                QuoteItem.objects.create(
                    quote=q, product=prod, name=prod.name,
                    hsn_sac_code=prod.hsn_sac_code, quantity=Decimal(str(random.randint(1,5))),
                    unit=prod.unit, unit_price=prod.unit_price,
                    discount_pct=Decimal('0'), gst_rate=prod.gst_rate, order=j)
            q.calculate_totals()
            quotes_created += 1

            # Convert some to invoices
            if q.status == 'accepted':
                inv = Invoice.objects.create(
                    quote=q, status='sent',
                    tax_profile=tp, contact=contact, company=company, deal=deal,
                    bill_to_name=q.bill_to_name, bill_to_gstin=q.bill_to_gstin,
                    bill_to_city=q.bill_to_city, bill_to_state=q.bill_to_state,
                    supply_type=q.supply_type,
                    due_date=(NOW + timedelta(days=30)).date(),
                    subtotal=q.subtotal, taxable_amount=q.taxable_amount,
                    cgst_total=q.cgst_total, sgst_total=q.sgst_total,
                    igst_total=q.igst_total, grand_total=q.grand_total,
                    amount_due=q.grand_total,
                    terms=q.terms, owner=random.choice(users), created_by=admin)
                for qi in q.items.all():
                    InvoiceItem.objects.create(
                        invoice=inv, product=qi.product, name=qi.name,
                        hsn_sac_code=qi.hsn_sac_code, quantity=qi.quantity,
                        unit=qi.unit, unit_price=qi.unit_price,
                        discount_pct=Decimal('0'),
                        gst_rate=qi.gst_rate, amount=qi.amount, order=qi.order)
                # Partial payment
                Payment.objects.create(
                    invoice=inv, amount=inv.grand_total / 2,
                    method=random.choice(['upi','neft','rtgs']),
                    status='confirmed',
                    transaction_id=f'TXN{random.randint(100000,999999)}',
                    notes='Advance payment received', recorded_by=admin)
                invoices_created += 1
        self.stdout.write(f'  ✓ {quotes_created} Quotes, {invoices_created} Invoices + payments')

    def _seed_workflows(self, tenant, admin, users):
        wf_configs = [
            ('Auto-assign new leads','lead_created',
             {'action':'assign_round_robin','config':{'team':'sales'}}),
            ('Notify on deal won','deal_won',
             {'action':'send_email_notification','config':{'template':'deal_won'}}),
            ('Escalate overdue tickets','ticket_sla_breached',
             {'action':'create_notification','config':{'priority':'high'}}),
        ]
        for name, trigger, action_cfg in wf_configs:
            wf, _ = Workflow.objects.get_or_create(
                name=name, created_by=admin,
                defaults={'trigger':trigger,'is_active':True,'description':f'Automated: {name}'})
            WorkflowAction.objects.get_or_create(
                workflow=wf, action_type=action_cfg['action'],
                defaults={'config':action_cfg['config'],'order':0})

        # Tasks
        task_count = 0
        for i in range(random.randint(5, 8)):
            Task.objects.create(
                title=random.choice(['Follow up with client','Prepare proposal','Schedule demo',
                    'Send pricing document','Review contract','Onboarding call',
                    'Quarterly review meeting','Collect feedback']),
                description='CRM task for team member.',
                task_type=random.choice(['call','email','meeting','follow_up','demo']),
                status=random.choice(['todo','in_progress','done']),
                priority=random.choice(['high','medium','low']),
                due_date=NOW + timedelta(days=random.randint(-5, 15)),
                assigned_to=random.choice(users), created_by=admin)
            task_count += 1

        # Notifications
        for u in users[:3]:
            for ntype, title, body in [
                ('lead_assigned','New lead assigned',f'A new lead has been assigned to you.'),
                ('deal_stage_changed','Deal moved forward','A deal has progressed to the next stage.'),
                ('system','Welcome to EasyIan CRM',f'Welcome aboard! Start by exploring your dashboard.'),
            ]:
                Notification.objects.create(
                    user=u, notif_type=ntype, title=title, body=body,
                    is_read=random.choice([True, False]))

        self.stdout.write(f'  ✓ {len(wf_configs)} Workflows, {task_count} Tasks, Notifications')

    def _seed_communications(self, tenant, admin, users):
        # Email templates
        templates = []
        tmpl_data = [
            ('Welcome Email','welcome','Welcome to {{company}}',
             '<h1>Welcome {{lead_name}}!</h1><p>We are excited to have you.</p>'),
            ('Follow-up','follow_up','Following up on our conversation',
             '<p>Hi {{lead_name}},</p><p>Just checking in regarding our last discussion.</p>'),
            ('Proposal','proposal','Proposal for {{company}}',
             '<p>Dear {{lead_name}},</p><p>Please find our proposal attached.</p>'),
            ('Thank You','thank_you','Thank you for choosing us!',
             '<p>Dear {{lead_name}},</p><p>Thank you for your business!</p>'),
        ]
        for name, ttype, subject, body in tmpl_data:
            t, _ = EmailTemplate.objects.get_or_create(
                user=admin, name=f'{name} - {tenant.slug}',
                defaults={'template_type':ttype,'subject':subject,
                          'body_html':body,'is_active':True,'is_shared':True})
            templates.append(t)

        # Email config (no real credentials)
        EmailConfiguration.objects.get_or_create(
            user=admin, name=f'SMTP - {tenant.slug}',
            defaults={'provider':'smtp','smtp_host':'smtp.example.com','smtp_port':587,
                      'from_email':tenant.email,'from_name':tenant.name,
                      'is_default':True})

        self.stdout.write(f'  ✓ {len(templates)} Email Templates + config')

    def _seed_integrations(self, tenant, admin):
        services = [
            ('whatsapp', {'phone_id': '', 'waba_id': ''}),
            ('gemini', {}),
            ('sarvam', {}),
            ('smtp', {'host': 'smtp.example.com', 'port': 587}),
        ]
        for svc, extra in services:
            Integration.objects.update_or_create(
                tenant=tenant, service=svc,
                defaults={'is_enabled':False,'api_key':'','api_secret':'',
                          'extra':extra,'created_by':admin})

        # WhatsApp templates (draft, no real IDs)
        wa_tmpls = [
            ('welcome_message','Hello {{name}}! Welcome to {{company}}. How can we help you today?',
             'utility',['name','company']),
            ('order_update','Hi {{name}}, your order #{{order_id}} status: {{status}}.',
             'utility',['name','order_id','status']),
            ('promo_offer','Hi {{name}}! Special offer: {{offer_details}}. Valid till {{expiry}}.',
             'marketing',['name','offer_details','expiry']),
        ]
        for name, body, cat, variables in wa_tmpls:
            WhatsAppTemplate.objects.get_or_create(
                tenant=tenant, name=name,
                defaults={'body':body,'category':cat,'language':'en',
                          'status':'draft','variables':variables,'created_by':admin})
        self.stdout.write(f'  ✓ {len(services)} Integrations (disabled), {len(wa_tmpls)} WA Templates')

    def _seed_dashboard(self, tenant, users):
        widgets = [('stats_card','Overview Stats',0),('chart','Revenue Chart',1),
                   ('recent_leads','Recent Leads',2),('activity_feed','Activity Feed',3)]
        for u in users[:2]:  # Admin + manager
            for wtype, title, pos in widgets:
                DashboardWidget.objects.get_or_create(
                    user=u, widget_type=wtype,
                    defaults={'title':title,'position':pos,'is_visible':True})
            DashboardPreference.objects.get_or_create(
                user=u, defaults={'default_date_range':'month','theme':'dark'})

        # KPI targets for reps
        today = NOW.date()
        period_start = today.replace(day=1)
        period_end = (period_start + timedelta(days=32)).replace(day=1) - timedelta(days=1)
        for u in users:
            for kpi, target in [('leads_created',30),('revenue_generated',500000),('calls_made',100)]:
                KPITarget.objects.get_or_create(
                    user=u, kpi_type=kpi, period_start=period_start, period_end=period_end,
                    defaults={'target_value':Decimal(str(target)),
                              'current_value':Decimal(str(int(target * random.uniform(0.3, 0.9))))})

        # Notification preferences
        for u in users[:2]:
            for ntype in ['new_lead','lead_status_change','daily_summary']:
                NotificationPreference.objects.get_or_create(
                    user=u, notification_type=ntype,
                    defaults={'email_enabled':True,'in_app_enabled':True})

        self.stdout.write(f'  ✓ Dashboard widgets, KPIs, preferences')

    def _seed_audit_logs(self, tenant, users):
        actions = [
            ('login','User','Login from web browser'),
            ('create_lead','Lead','Created new lead'),
            ('update_deal','Deal','Updated deal stage'),
            ('send_email','Email','Sent email to contact'),
            ('create_invoice','Invoice','Generated new invoice'),
        ]
        for action, resource, detail in actions:
            TenantAuditLog.objects.create(
                tenant=tenant, user=random.choice(users),
                action=action, resource=resource,
                details={'description': detail},
                ip='192.168.1.' + str(random.randint(1, 254)))
        self.stdout.write(f'  ✓ {len(actions)} Audit Logs')
