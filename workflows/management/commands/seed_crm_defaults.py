# workflows/management/commands/seed_crm_defaults.py
"""
Run once after migrations to bootstrap a production-ready CRM:
  python manage.py seed_crm_defaults

Creates:
  - Default Sales Pipeline with 7 stages
  - 4 SLA Policies (Critical / High / Medium / Low)
  - 6 Ticket Categories
  - 3 starter Workflows
  - 1 TaxProfile placeholder (update GSTIN before use)
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Seed default pipeline, SLA policies, ticket categories, and workflows'

    def handle(self, *args, **options):
        self._seed_pipeline()
        self._seed_sla()
        self._seed_ticket_categories()
        self._seed_tax_profile()
        self._seed_workflows()
        self.stdout.write(self.style.SUCCESS('✅  CRM defaults seeded successfully.'))

    # ── Pipeline ──────────────────────────────────────────────────────────────

    def _seed_pipeline(self):
        from deals.models import Pipeline, PipelineStage
        admin = User.objects.filter(is_superuser=True).first()
        if not admin:
            self.stdout.write(self.style.WARNING('  No superuser found – skipping pipeline seed.'))
            return

        pipeline, created = Pipeline.objects.get_or_create(
            name='Sales Pipeline',
            defaults={'is_default': True, 'is_active': True, 'created_by': admin}
        )
        if not created:
            self.stdout.write('  Pipeline already exists – skipping.')
            return

        stages = [
            ('New Lead',     5,  '#94a3b8', False, False),
            ('Contacted',    15, '#60a5fa', False, False),
            ('Qualified',    30, '#a78bfa', False, False),
            ('Proposal',     50, '#f59e0b', False, False),
            ('Negotiation',  75, '#fb923c', False, False),
            ('Won',         100, '#22c55e', True,  False),
            ('Lost',          0, '#ef4444', False, True),
        ]
        for i, (name, prob, color, is_won, is_lost) in enumerate(stages):
            PipelineStage.objects.get_or_create(
                pipeline=pipeline, name=name,
                defaults={'order': i, 'probability': prob, 'color': color,
                          'is_won': is_won, 'is_lost': is_lost}
            )
        self.stdout.write('  ✓ Default pipeline created with 7 stages.')

    # ── SLA Policies ──────────────────────────────────────────────────────────

    def _seed_sla(self):
        from tickets.models import SLAPolicy
        policies = [
            ('Critical SLA', 'critical', 1, 4),
            ('High Priority SLA', 'high', 4, 12),
            ('Standard SLA', 'medium', 8, 48),
            ('Low Priority SLA', 'low', 24, 120),
        ]
        for name, priority, first_resp, resolution in policies:
            SLAPolicy.objects.get_or_create(
                name=name,
                defaults={
                    'priority': priority,
                    'first_response_hours': first_resp,
                    'resolution_hours': resolution,
                    'business_hours_only': True,
                }
            )
        self.stdout.write('  ✓ 4 SLA policies created.')

    # ── Ticket Categories ─────────────────────────────────────────────────────

    def _seed_ticket_categories(self):
        from tickets.models import TicketCategory
        cats = [
            ('Billing & Payments', '#f59e0b'),
            ('Technical Support', '#6366f1'),
            ('Product Query',      '#22c55e'),
            ('Refund Request',     '#ef4444'),
            ('Onboarding',         '#0ea5e9'),
            ('General Inquiry',    '#94a3b8'),
        ]
        for name, color in cats:
            TicketCategory.objects.get_or_create(name=name, defaults={'color': color})
        self.stdout.write('  ✓ 6 ticket categories created.')

    # ── Tax Profile placeholder ───────────────────────────────────────────────

    def _seed_tax_profile(self):
        from quotes.models import TaxProfile
        if TaxProfile.objects.exists():
            return
        TaxProfile.objects.create(
            name='Your Company Name Pvt. Ltd.',
            gstin='29AAAAA0000A1Z5',  # placeholder – update before use
            pan='AAAAA0000A',
            address='123, Business Park',
            city='Bengaluru',
            state='KA',
            postal_code='560001',
            phone='+91-9999999999',
            email='billing@yourcompany.com',
        )
        self.stdout.write('  ✓ Placeholder tax profile created (update GSTIN before use).')

    # ── Starter Workflows ─────────────────────────────────────────────────────

    def _seed_workflows(self):
        from workflows.models import Workflow, WorkflowAction
        admin = User.objects.filter(is_superuser=True).first()
        if not admin:
            return

        starters = [
            {
                'name': 'Notify on New Lead',
                'trigger': 'lead_created',
                'description': 'Send in-app notification to admin when a new lead is created.',
                'actions': [
                    {'action_type': 'create_notification', 'order': 0,
                     'config': {'user_id': admin.id, 'title': 'New Lead Created',
                                'body': 'A new lead has been added to the CRM.'}}
                ],
            },
            {
                'name': 'Auto-Task on Deal Won',
                'trigger': 'deal_won',
                'description': 'Create a follow-up task when a deal is won.',
                'actions': [
                    {'action_type': 'create_task', 'order': 0,
                     'config': {'title': 'Post-Sale Onboarding Call', 'task_type': 'call',
                                'priority': 'high', 'due_hours': 24,
                                'created_by_id': admin.id}}
                ],
            },
            {
                'name': 'Notify on Ticket SLA Breach',
                'trigger': 'ticket_sla_breached',
                'description': 'Alert admin when a ticket breaches SLA.',
                'actions': [
                    {'action_type': 'create_notification', 'order': 0,
                     'config': {'user_id': admin.id, 'title': '⚠️ Ticket SLA Breached',
                                'body': 'A ticket has exceeded its SLA deadline.'}}
                ],
            },
        ]

        for wf_data in starters:
            actions_data = wf_data.pop('actions')
            wf, created = Workflow.objects.get_or_create(
                name=wf_data['name'],
                defaults={**wf_data, 'created_by': admin, 'is_active': True}
            )
            if created:
                for a in actions_data:
                    WorkflowAction.objects.create(workflow=wf, **a)

        self.stdout.write('  ✓ 3 starter workflows created.')
