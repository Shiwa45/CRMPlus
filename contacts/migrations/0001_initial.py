# contacts/migrations/0001_initial.py
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Company',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=255, unique=True)),
                ('website', models.URLField(blank=True, null=True)),
                ('phone', models.CharField(blank=True, max_length=20, null=True)),
                ('email', models.EmailField(blank=True, null=True)),
                ('industry', models.CharField(blank=True, max_length=50)),
                ('employee_size', models.CharField(blank=True, max_length=20)),
                ('annual_revenue', models.DecimalField(blank=True, decimal_places=2, max_digits=15, null=True)),
                ('gstin', models.CharField(blank=True, max_length=15, null=True)),
                ('pan', models.CharField(blank=True, max_length=10, null=True)),
                ('cin', models.CharField(blank=True, max_length=21, null=True)),
                ('address_line1', models.CharField(blank=True, max_length=255)),
                ('address_line2', models.CharField(blank=True, max_length=255)),
                ('city', models.CharField(blank=True, max_length=100)),
                ('state', models.CharField(blank=True, max_length=100)),
                ('country', models.CharField(default='India', max_length=100)),
                ('postal_code', models.CharField(blank=True, max_length=10)),
                ('description', models.TextField(blank=True)),
                ('logo', models.ImageField(blank=True, null=True, upload_to='company_logos/')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_companies', to=settings.AUTH_USER_MODEL)),
                ('owner', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='owned_companies', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['name'], 'verbose_name_plural': 'companies'},
        ),
        migrations.CreateModel(
            name='Contact',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('salutation', models.CharField(blank=True, max_length=10)),
                ('first_name', models.CharField(max_length=100)),
                ('last_name', models.CharField(blank=True, max_length=100)),
                ('job_title', models.CharField(blank=True, max_length=150)),
                ('department', models.CharField(blank=True, max_length=100)),
                ('email', models.EmailField(blank=True)),
                ('email2', models.EmailField(blank=True, null=True)),
                ('phone', models.CharField(blank=True, max_length=20)),
                ('phone2', models.CharField(blank=True, max_length=20, null=True)),
                ('mobile', models.CharField(blank=True, max_length=20, null=True)),
                ('whatsapp', models.CharField(blank=True, max_length=20, null=True)),
                ('linkedin', models.URLField(blank=True, null=True)),
                ('twitter', models.CharField(blank=True, max_length=100, null=True)),
                ('pan', models.CharField(blank=True, max_length=10, null=True)),
                ('aadhaar_last4', models.CharField(blank=True, max_length=4, null=True)),
                ('address_line1', models.CharField(blank=True, max_length=255)),
                ('city', models.CharField(blank=True, max_length=100)),
                ('state', models.CharField(blank=True, max_length=100)),
                ('country', models.CharField(default='India', max_length=100)),
                ('postal_code', models.CharField(blank=True, max_length=10)),
                ('tags', models.JSONField(blank=True, default=list)),
                ('notes', models.TextField(blank=True)),
                ('avatar', models.ImageField(blank=True, null=True, upload_to='contact_avatars/')),
                ('is_active', models.BooleanField(default=True)),
                ('do_not_contact', models.BooleanField(default=False)),
                ('dnd_reason', models.CharField(blank=True, max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('last_contacted', models.DateTimeField(blank=True, null=True)),
                ('company', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='contacts', to='contacts.company')),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_contacts', to=settings.AUTH_USER_MODEL)),
                ('owner', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='owned_contacts', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['first_name', 'last_name']},
        ),
        migrations.CreateModel(
            name='ContactActivity',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('activity_type', models.CharField(max_length=20)),
                ('subject', models.CharField(max_length=255)),
                ('description', models.TextField(blank=True)),
                ('outcome', models.CharField(blank=True, max_length=255)),
                ('performed_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('contact', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='activities', to='contacts.contact')),
                ('performed_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-performed_at']},
        ),
        migrations.CreateModel(
            name='ContactDocument',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('doc_type', models.CharField(max_length=30)),
                ('title', models.CharField(max_length=200)),
                ('file', models.FileField(upload_to='contact_docs/')),
                ('uploaded_at', models.DateTimeField(auto_now_add=True)),
                ('contact', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='documents', to='contacts.contact')),
                ('uploaded_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
