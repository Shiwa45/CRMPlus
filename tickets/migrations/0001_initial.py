# tickets/migrations/0001_initial.py
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('contacts', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='TicketCategory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=100, unique=True)),
                ('description', models.TextField(blank=True)),
                ('color', models.CharField(default='#6366f1', max_length=7)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={'ordering': ['name'], 'verbose_name_plural': 'Ticket Categories'},
        ),
        migrations.CreateModel(
            name='SLAPolicy',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=200)),
                ('priority', models.CharField(max_length=20)),
                ('first_response_hours', models.PositiveIntegerField(default=4)),
                ('resolution_hours', models.PositiveIntegerField(default=24)),
                ('business_hours_only', models.BooleanField(default=True)),
                ('escalate_after_hours', models.PositiveIntegerField(default=8)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('escalate_to', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='escalation_targets', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['priority'], 'verbose_name': 'SLA Policy', 'verbose_name_plural': 'SLA Policies'},
        ),
        migrations.CreateModel(
            name='Ticket',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('ticket_number', models.CharField(editable=False, max_length=20, unique=True)),
                ('subject', models.CharField(max_length=300)),
                ('description', models.TextField()),
                ('status', models.CharField(default='open', max_length=20)),
                ('priority', models.CharField(default='medium', max_length=20)),
                ('channel', models.CharField(default='manual', max_length=20)),
                ('sla_due_date', models.DateTimeField(blank=True, null=True)),
                ('first_response_at', models.DateTimeField(blank=True, null=True)),
                ('first_response_due', models.DateTimeField(blank=True, null=True)),
                ('sla_breached', models.BooleanField(default=False)),
                ('resolution_due', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('resolved_at', models.DateTimeField(blank=True, null=True)),
                ('closed_at', models.DateTimeField(blank=True, null=True)),
                ('csat_score', models.PositiveIntegerField(blank=True, null=True)),
                ('csat_comment', models.TextField(blank=True)),
                ('csat_sent_at', models.DateTimeField(blank=True, null=True)),
                ('csat_received_at', models.DateTimeField(blank=True, null=True)),
                ('tags', models.JSONField(blank=True, default=list)),
                ('contact', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='tickets', to='contacts.contact')),
                ('company', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='tickets', to='contacts.company')),
                ('category', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='tickets', to='tickets.ticketcategory')),
                ('sla_policy', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='tickets', to='tickets.slapolicy')),
                ('assigned_to', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='assigned_tickets', to=settings.AUTH_USER_MODEL)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_tickets', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
        migrations.CreateModel(
            name='TicketReply',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('reply_type', models.CharField(default='reply', max_length=10)),
                ('body', models.TextField()),
                ('is_public', models.BooleanField(default=True)),
                ('attachments', models.JSONField(blank=True, default=list)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('ticket', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='replies', to='tickets.ticket')),
                ('author', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='ticket_replies', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['created_at']},
        ),
        migrations.CreateModel(
            name='TicketAttachment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('file', models.FileField(upload_to='ticket_attachments/')),
                ('file_name', models.CharField(max_length=255)),
                ('file_size', models.PositiveIntegerField(default=0)),
                ('uploaded_at', models.DateTimeField(auto_now_add=True)),
                ('ticket', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='attachments', to='tickets.ticket')),
                ('uploaded_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='TicketActivity',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('action', models.CharField(max_length=30)),
                ('description', models.TextField()),
                ('old_value', models.CharField(blank=True, max_length=255)),
                ('new_value', models.CharField(blank=True, max_length=255)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('ticket', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='activities', to='tickets.ticket')),
                ('performed_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
