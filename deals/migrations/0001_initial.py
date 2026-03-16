# deals/migrations/0001_initial.py
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
            name='Pipeline',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=200)),
                ('description', models.TextField(blank=True)),
                ('is_default', models.BooleanField(default=False)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_pipelines', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['name']},
        ),
        migrations.CreateModel(
            name='PipelineStage',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=150)),
                ('order', models.PositiveIntegerField(default=0)),
                ('probability', models.PositiveIntegerField(default=0)),
                ('color', models.CharField(default='#6366f1', max_length=7)),
                ('is_won', models.BooleanField(default=False)),
                ('is_lost', models.BooleanField(default=False)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('pipeline', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='stages', to='deals.pipeline')),
            ],
            options={'ordering': ['order'], 'unique_together': {('pipeline', 'name')}},
        ),
        migrations.CreateModel(
            name='Deal',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=300)),
                ('priority', models.CharField(default='medium', max_length=10)),
                ('value', models.DecimalField(decimal_places=2, default=0, max_digits=15)),
                ('currency', models.CharField(default='INR', max_length=3)),
                ('weighted_value', models.DecimalField(decimal_places=2, default=0, max_digits=15)),
                ('expected_revenue', models.DecimalField(decimal_places=2, default=0, max_digits=15)),
                ('close_date', models.DateField(blank=True, null=True)),
                ('actual_close_date', models.DateField(blank=True, null=True)),
                ('won_at', models.DateTimeField(blank=True, null=True)),
                ('lost_at', models.DateTimeField(blank=True, null=True)),
                ('lost_reason', models.TextField(blank=True)),
                ('competitor', models.CharField(blank=True, max_length=200)),
                ('description', models.TextField(blank=True)),
                ('tags', models.JSONField(blank=True, default=list)),
                ('lead_source', models.CharField(blank=True, max_length=100)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('pipeline', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='deals', to='deals.pipeline')),
                ('stage', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='deals', to='deals.pipelinestage')),
                ('contact', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='deals', to='contacts.contact')),
                ('company', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='deals', to='contacts.company')),
                ('owner', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='owned_deals', to=settings.AUTH_USER_MODEL)),
                ('co_owners', models.ManyToManyField(blank=True, related_name='co_owned_deals', to=settings.AUTH_USER_MODEL)),
                ('created_by', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='created_deals', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
        migrations.CreateModel(
            name='DealActivity',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('activity_type', models.CharField(max_length=20)),
                ('subject', models.CharField(max_length=255)),
                ('description', models.TextField(blank=True)),
                ('outcome', models.CharField(blank=True, max_length=255)),
                ('status', models.CharField(default='done', max_length=20)),
                ('due_date', models.DateTimeField(blank=True, null=True)),
                ('performed_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('deal', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='activities', to='deals.deal')),
                ('performed_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-performed_at']},
        ),
        migrations.CreateModel(
            name='DealStageHistory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False)),
                ('days_in_stage', models.PositiveIntegerField(default=0)),
                ('changed_at', models.DateTimeField(auto_now_add=True)),
                ('deal', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='stage_history', to='deals.deal')),
                ('from_stage', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='deals.pipelinestage')),
                ('to_stage', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='deals.pipelinestage')),
                ('changed_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
