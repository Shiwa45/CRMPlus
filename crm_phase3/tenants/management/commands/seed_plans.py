# tenants/management/commands/seed_plans.py
from django.core.management.base import BaseCommand
from tenants.models import Plan


class Command(BaseCommand):
    help = 'Seed the 4 default Indian CRM plans'

    def handle(self, *args, **options):
        Plan.seed()
        self.stdout.write(self.style.SUCCESS('✓ Plans seeded successfully'))
        for p in Plan.objects.all():
            self.stdout.write(f'  • {p.display_name:15s} ₹{p.monthly_price}/mo  |  '
                              f'{p.max_users} users  |  {p.max_leads} leads')
