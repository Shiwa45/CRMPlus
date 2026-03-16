# tenants/migrations/0001_initial.py
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone
import uuid


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Plan',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(choices=[('starter','Starter'),('growth','Growth'),('professional','Professional'),('enterprise','Enterprise')], max_length=50, unique=True)),
                ('display_name', models.CharField(max_length=100)),
                ('tagline', models.CharField(blank=True, max_length=200)),
                ('monthly_price', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('annual_price', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('max_users', models.IntegerField(default=2)),
                ('max_leads', models.IntegerField(default=500)),
                ('max_contacts', models.IntegerField(default=500)),
                ('max_deals', models.IntegerField(default=100)),
                ('max_emails_pm', models.IntegerField(default=1000)),
                ('max_wa_pm', models.IntegerField(default=0)),
                ('max_ai_pm', models.IntegerField(default=0)),
                ('storage_gb', models.IntegerField(default=1)),
                ('feat_whatsapp', models.BooleanField(default=False)),
                ('feat_ai_scoring', models.BooleanField(default=False)),
                ('feat_ai_assistant', models.BooleanField(default=False)),
                ('feat_ai_calls', models.BooleanField(default=False)),
                ('feat_workflows', models.BooleanField(default=False)),
                ('feat_quotes', models.BooleanField(default=True)),
                ('feat_invoices', models.BooleanField(default=True)),
                ('feat_tickets', models.BooleanField(default=False)),
                ('feat_analytics', models.BooleanField(default=True)),
                ('feat_api_access', models.BooleanField(default=False)),
                ('feat_custom_domain', models.BooleanField(default=False)),
                ('feat_sso', models.BooleanField(default=False)),
                ('feat_audit_log', models.BooleanField(default=False)),
                ('is_active', models.BooleanField(default=True)),
                ('sort_order', models.IntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={'ordering': ['sort_order']},
        ),
        migrations.CreateModel(
            name='Tenant',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=200)),
                ('slug', models.SlugField(max_length=100, unique=True)),
                ('domain', models.CharField(blank=True, max_length=200)),
                ('gstin', models.CharField(blank=True, max_length=20)),
                ('pan', models.CharField(blank=True, max_length=10)),
                ('address', models.TextField(blank=True)),
                ('city', models.CharField(blank=True, max_length=100)),
                ('state', models.CharField(blank=True, max_length=100)),
                ('pincode', models.CharField(blank=True, max_length=10)),
                ('phone', models.CharField(blank=True, max_length=20)),
                ('email', models.EmailField(blank=True)),
                ('logo', models.ImageField(blank=True, null=True, upload_to='tenants/')),
                ('billing', models.CharField(default='monthly', max_length=10)),
                ('status', models.CharField(choices=[('trial','Trial'),('active','Active'),('suspended','Suspended'),('expired','Expired')], default='trial', max_length=20)),
                ('trial_ends', models.DateTimeField(blank=True, null=True)),
                ('plan_ends', models.DateTimeField(blank=True, null=True)),
                ('emails_sent', models.IntegerField(default=0)),
                ('wa_sent', models.IntegerField(default=0)),
                ('ai_used', models.IntegerField(default=0)),
                ('usage_reset', models.DateTimeField(default=django.utils.timezone.now)),
                ('timezone', models.CharField(db_column='timezone', default='Asia/Kolkata', max_length=50)),
                ('currency', models.CharField(default='INR', max_length=5)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('plan', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='tenants', to='tenants.plan')),
            ],
            options={'ordering': ['name']},
        ),
        migrations.CreateModel(
            name='TenantUser',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('role', models.CharField(choices=[('super_admin','Super Admin'),('tenant_admin','Tenant Admin'),('sales_manager','Sales Manager'),('sales_rep','Sales Rep'),('marketing','Marketing'),('support','Support'),('readonly','Read Only')], default='sales_rep', max_length=20)),
                ('is_active', models.BooleanField(default=True)),
                ('joined_at', models.DateTimeField(auto_now_add=True)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='members', to='tenants.tenant')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='tenants', to=settings.AUTH_USER_MODEL)),
            ],
            options={'unique_together': {('tenant', 'user')}},
        ),
        migrations.CreateModel(
            name='TenantInvitation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('email', models.EmailField()),
                ('role', models.CharField(choices=[('super_admin','Super Admin'),('tenant_admin','Tenant Admin'),('sales_manager','Sales Manager'),('sales_rep','Sales Rep'),('marketing','Marketing'),('support','Support'),('readonly','Read Only')], default='sales_rep', max_length=20)),
                ('token', models.UUIDField(default=uuid.uuid4, unique=True)),
                ('accepted', models.BooleanField(default=False)),
                ('expires_at', models.DateTimeField()),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('invited_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='invitations', to='tenants.tenant')),
            ],
        ),
        migrations.CreateModel(
            name='TenantAuditLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('action', models.CharField(max_length=100)),
                ('resource', models.CharField(blank=True, max_length=100)),
                ('resource_id', models.CharField(blank=True, max_length=100)),
                ('details', models.JSONField(blank=True, default=dict)),
                ('ip', models.GenericIPAddressField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='audit_logs', to='tenants.tenant')),
                ('user', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
