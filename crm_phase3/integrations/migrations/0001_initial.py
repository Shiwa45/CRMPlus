# integrations/migrations/0001_initial.py
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('tenants', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Integration',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('service', models.CharField(choices=[
                    ('whatsapp','WhatsApp Business'),('sarvam','Sarvam AI'),
                    ('gemini','Google Gemini AI'),('smtp','Custom SMTP'),
                    ('sendgrid','SendGrid'),('razorpay','Razorpay'),
                ], max_length=30)),
                ('is_enabled', models.BooleanField(default=False)),
                ('api_key', models.CharField(blank=True, max_length=500)),
                ('api_secret', models.CharField(blank=True, max_length=500)),
                ('extra', models.JSONField(blank=True, default=dict)),
                ('last_tested', models.DateTimeField(blank=True, null=True)),
                ('test_ok', models.BooleanField(null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='integrations', to='tenants.tenant')),
                ('created_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['service'], 'unique_together': {('tenant', 'service')}},
        ),
        migrations.CreateModel(
            name='WhatsAppTemplate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('name', models.CharField(max_length=100)),
                ('category', models.CharField(choices=[('utility','Utility'),('marketing','Marketing'),('authentication','Authentication')], default='utility', max_length=20)),
                ('language', models.CharField(default='en', max_length=10)),
                ('header_text', models.CharField(blank=True, max_length=200)),
                ('body', models.TextField()),
                ('footer_text', models.CharField(blank=True, max_length=100)),
                ('status', models.CharField(choices=[('draft','Draft'),('pending','Pending'),('approved','Approved'),('rejected','Rejected')], default='draft', max_length=20)),
                ('wa_template_id', models.CharField(blank=True, max_length=100)),
                ('variables', models.JSONField(blank=True, default=list)),
                ('use_count', models.IntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='wa_templates', to='tenants.tenant')),
                ('created_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['name']},
        ),
        migrations.CreateModel(
            name='WhatsAppLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True)),
                ('to_phone', models.CharField(max_length=20)),
                ('to_name', models.CharField(blank=True, max_length=200)),
                ('message', models.TextField()),
                ('status', models.CharField(default='pending', max_length=20)),
                ('wa_msg_id', models.CharField(blank=True, max_length=200)),
                ('error', models.TextField(blank=True)),
                ('lead_id', models.IntegerField(blank=True, null=True)),
                ('contact_id', models.IntegerField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('tenant', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='wa_logs', to='tenants.tenant')),
                ('template', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='integrations.whatsapptemplate')),
                ('sent_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
