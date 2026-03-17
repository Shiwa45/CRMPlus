# dashboard/models.py  ← FULL REPLACEMENT  (tenant FK removed — schema = isolation)
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()


class DashboardWidget(models.Model):
    WIDGET_TYPES = [
        ('stats_card',    'Stats Card'),
        ('chart',         'Chart'),
        ('recent_leads',  'Recent Leads'),
        ('activity_feed', 'Activity Feed'),
        ('pipeline',      'Pipeline Overview'),
        ('tasks',         'My Tasks'),
        ('calendar',      'Calendar'),
        ('kpi_gauge',     'KPI Gauge'),
    ]

    user         = models.ForeignKey(User, on_delete=models.CASCADE,
                                     related_name='dashboard_widgets')
    widget_type  = models.CharField(max_length=30, choices=WIDGET_TYPES)
    title        = models.CharField(max_length=200)
    position     = models.IntegerField(default=0)
    config       = models.JSONField(default=dict, blank=True)
    is_visible   = models.BooleanField(default=True)
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['user', 'position']
        unique_together = ('user', 'widget_type')

    def __str__(self):
        return f'{self.user.username} — {self.widget_type}'


class DashboardPreference(models.Model):
    DATE_RANGE_CHOICES = [
        ('today',   'Today'),
        ('week',    'This Week'),
        ('month',   'This Month'),
        ('quarter', 'This Quarter'),
        ('year',    'This Year'),
    ]
    THEME_CHOICES = [
        ('light', 'Light'), ('dark', 'Dark'),
    ]

    user                    = models.OneToOneField(User, on_delete=models.CASCADE,
                                                   related_name='dashboard_preference')
    default_date_range      = models.CharField(max_length=10, choices=DATE_RANGE_CHOICES,
                                               default='month')
    show_welcome_message    = models.BooleanField(default=True)
    auto_refresh_interval   = models.IntegerField(default=300, help_text='Seconds')
    theme                   = models.CharField(max_length=10, choices=THEME_CHOICES,
                                               default='light')
    created_at              = models.DateTimeField(auto_now_add=True)
    updated_at              = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s Preferences"


class KPITarget(models.Model):
    KPI_TYPES = [
        ('leads_created',    'Leads Created'),
        ('leads_converted',  'Leads Converted'),
        ('revenue_generated','Revenue Generated'),
        ('calls_made',       'Calls Made'),
        ('emails_sent',      'Emails Sent'),
        ('meetings_scheduled','Meetings Scheduled'),
        ('deals_won',        'Deals Won'),
        ('tickets_resolved', 'Tickets Resolved'),
    ]

    user          = models.ForeignKey(User, on_delete=models.CASCADE,
                                      related_name='kpi_targets')
    kpi_type      = models.CharField(max_length=30, choices=KPI_TYPES)
    target_value  = models.DecimalField(max_digits=12, decimal_places=2)
    current_value = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    period_start  = models.DateField()
    period_end    = models.DateField()
    is_active     = models.BooleanField(default=True)
    created_at    = models.DateTimeField(auto_now_add=True)
    updated_at    = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'kpi_type', 'period_start')
        ordering = ['-period_start', 'kpi_type']

    def __str__(self):
        return f'{self.user.username} — {self.kpi_type}'

    @property
    def progress_pct(self):
        if not self.target_value:
            return 0
        return min(100, int(self.current_value / self.target_value * 100))


class NotificationPreference(models.Model):
    user                = models.ForeignKey(User, on_delete=models.CASCADE,
                                            related_name='notification_preferences')
    notification_type   = models.CharField(max_length=50)
    email_enabled       = models.BooleanField(default=True)
    in_app_enabled      = models.BooleanField(default=True)
    sms_enabled         = models.BooleanField(default=False)
    push_enabled        = models.BooleanField(default=False)
    created_at          = models.DateTimeField(auto_now_add=True)
    updated_at          = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'notification_type')
        ordering = ['user', 'notification_type']

    def __str__(self):
        return f'{self.user.username} — {self.notification_type}'
