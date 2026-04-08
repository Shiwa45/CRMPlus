# apps/visitor/models.py
from django.db import models
from django.conf import settings
from django.utils import timezone


class Visitor(models.Model):
    PURPOSE_CHOICES = [
        ('meeting', 'Meeting'), ('delivery', 'Delivery'),
        ('parent', 'Parent Visit'), ('interview', 'Interview'),
        ('maintenance', 'Maintenance'), ('official', 'Official Work'), ('other', 'Other'),
    ]
    visitor_name = models.CharField(max_length=100)
    phone = models.CharField(max_length=15)
    id_proof_type = models.CharField(max_length=30, blank=True)
    id_proof_number = models.CharField(max_length=50, blank=True)
    purpose = models.CharField(max_length=15, choices=PURPOSE_CHOICES, default='meeting')
    whom_to_meet = models.CharField(max_length=100)
    department = models.CharField(max_length=100, blank=True)
    check_in_time = models.DateTimeField(default=timezone.now)
    check_out_time = models.DateTimeField(null=True, blank=True)
    visitor_pass_number = models.CharField(max_length=20, blank=True)
    photo = models.ImageField(upload_to='visitors/', null=True, blank=True)
    is_blacklisted = models.BooleanField(default=False)
    remarks = models.TextField(blank=True)
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.visitor_name} — {self.check_in_time.date()}"

    @property
    def duration(self):
        if self.check_out_time:
            delta = self.check_out_time - self.check_in_time
            return f"{int(delta.total_seconds() // 60)} min"
        return "Still inside"

    class Meta: db_table = 'visitor'; app_label = 'visitor'; ordering = ['-check_in_time']
