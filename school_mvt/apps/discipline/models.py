from django.db import models
from django.conf import settings


class IncidentReport(models.Model):
    SEVERITY_CHOICES = [
        ('minor', 'Minor'), ('moderate', 'Moderate'),
        ('major', 'Major'), ('critical', 'Critical'),
    ]
    STATUS_CHOICES = [
        ('open', 'Open'), ('investigating', 'Investigating'),
        ('resolved', 'Resolved'), ('closed', 'Closed'),
    ]
    student = models.ForeignKey(
        'students.Student', on_delete=models.CASCADE, related_name='incidents'
    )
    incident_date = models.DateField()
    incident_type = models.CharField(max_length=100)
    description = models.TextField()
    severity = models.CharField(max_length=10, choices=SEVERITY_CHOICES, default='minor')
    location = models.CharField(max_length=100, blank=True)
    witnesses = models.TextField(blank=True)
    action_taken = models.TextField(blank=True)
    parent_notified = models.BooleanField(default=False)
    parent_notified_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='open')
    reported_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, related_name='reported_incidents'
    )
    resolved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='resolved_incidents'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.student.full_name} — {self.incident_type} ({self.incident_date})"

    class Meta:
        db_table = 'incident_report'
        app_label = 'discipline'
        ordering = ['-incident_date']


class DisciplinaryAction(models.Model):
    ACTION_CHOICES = [
        ('warning', 'Warning'), ('written_warning', 'Written Warning'),
        ('detention', 'Detention'), ('suspension', 'Suspension'),
        ('fine', 'Fine'), ('community_service', 'Community Service'),
        ('counselling', 'Counselling Referral'), ('expulsion', 'Expulsion'),
    ]
    incident = models.ForeignKey(
        IncidentReport, on_delete=models.CASCADE, related_name='actions'
    )
    action_type = models.CharField(max_length=20, choices=ACTION_CHOICES)
    description = models.TextField()
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    issued_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.get_action_type_display()} — {self.incident.student.full_name}"

    class Meta:
        db_table = 'disciplinary_action'
        app_label = 'discipline'


class CounsellingSession(models.Model):
    SESSION_TYPE_CHOICES = [
        ('academic', 'Academic'), ('personal', 'Personal'),
        ('career', 'Career'), ('behavioral', 'Behavioral'),
    ]
    student = models.ForeignKey(
        'students.Student', on_delete=models.CASCADE, related_name='counselling_sessions'
    )
    session_date = models.DateField()
    session_type = models.CharField(max_length=15, choices=SESSION_TYPE_CHOICES)
    counsellor = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True
    )
    notes = models.TextField(blank=True, help_text='Confidential — not shown to parents')
    follow_up_required = models.BooleanField(default=False)
    follow_up_date = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.student.full_name} — {self.session_type} ({self.session_date})"

    class Meta:
        db_table = 'counselling_session'
        app_label = 'discipline'
        ordering = ['-session_date']
