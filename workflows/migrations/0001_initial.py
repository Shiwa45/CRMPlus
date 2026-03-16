# workflows/migrations/0001_initial.py
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
            name='Workflow',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=200)),
                ('description', models.TextField(blank=True)),
                ('trigger', models.CharField(max_length=50)),
                ('trigger_config', models.JSONField(blank=True, default=dict)),
                ('is_active', models.BooleanField(default=True)),
                ('run_once_per_object', models.BooleanField(default=True)),
                ('run_count', models.PositiveIntegerField(default=0)),
                ('last_run_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_workflows', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['name']},
        ),
        migrations.CreateModel(
            name='WorkflowCondition',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('field', models.CharField(max_length=100)),
                ('operator', models.CharField(max_length=20)),
                ('value', models.CharField(max_length=500)),
                ('logic', models.CharField(default='and', max_length=5)),
                ('order', models.PositiveIntegerField(default=0)),
                ('workflow', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='conditions', to='workflows.workflow')),
            ],
            options={'ordering': ['order']},
        ),
        migrations.CreateModel(
            name='WorkflowAction',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('action_type', models.CharField(max_length=50)),
                ('config', models.JSONField(default=dict)),
                ('order', models.PositiveIntegerField(default=0)),
                ('delay_minutes', models.PositiveIntegerField(default=0)),
                ('workflow', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='actions', to='workflows.workflow')),
            ],
            options={'ordering': ['order']},
        ),
        migrations.CreateModel(
            name='WorkflowExecution',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('status', models.CharField(default='pending', max_length=20)),
                ('triggered_by', models.CharField(max_length=100)),
                ('object_type', models.CharField(max_length=50)),
                ('object_id', models.PositiveIntegerField()),
                ('actions_executed', models.JSONField(default=list)),
                ('error_message', models.TextField(blank=True)),
                ('started_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('completed_at', models.DateTimeField(blank=True, null=True)),
                ('workflow', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='executions', to='workflows.workflow')),
            ],
            options={'ordering': ['-started_at']},
        ),
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('notif_type', models.CharField(max_length=40)),
                ('title', models.CharField(max_length=255)),
                ('body', models.TextField()),
                ('link', models.CharField(blank=True, max_length=500)),
                ('is_read', models.BooleanField(default=False)),
                ('object_type', models.CharField(blank=True, max_length=50)),
                ('object_id', models.PositiveIntegerField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='notifications', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
        migrations.CreateModel(
            name='Task',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=300)),
                ('description', models.TextField(blank=True)),
                ('task_type', models.CharField(default='follow_up', max_length=20)),
                ('status', models.CharField(default='todo', max_length=20)),
                ('priority', models.CharField(default='medium', max_length=10)),
                ('due_date', models.DateTimeField(blank=True, null=True)),
                ('completed_at', models.DateTimeField(blank=True, null=True)),
                ('lead_id', models.PositiveIntegerField(blank=True, null=True)),
                ('deal_id', models.PositiveIntegerField(blank=True, null=True)),
                ('contact_id', models.PositiveIntegerField(blank=True, null=True)),
                ('ticket_id', models.PositiveIntegerField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('assigned_to', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='assigned_tasks', to=settings.AUTH_USER_MODEL)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_tasks', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['due_date', '-created_at']},
        ),
    ]
