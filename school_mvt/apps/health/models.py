# apps/health/models.py
from django.db import models
from django.conf import settings


class HealthRecord(models.Model):
    student = models.ForeignKey('students.Student', on_delete=models.CASCADE, related_name='health_records')
    checkup_date = models.DateField()
    height_cm = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    weight_kg = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    bmi = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    vision_left = models.CharField(max_length=20, blank=True)
    vision_right = models.CharField(max_length=20, blank=True)
    blood_pressure = models.CharField(max_length=20, blank=True)
    blood_group = models.CharField(max_length=5, blank=True)
    vaccination_up_to_date = models.BooleanField(default=True)
    remarks = models.TextField(blank=True)
    doctor_name = models.CharField(max_length=100, blank=True)
    checked_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.student.full_name} — {self.checkup_date}"
    class Meta: db_table = 'health_record'; app_label = 'health'; ordering = ['-checkup_date']


class SickRoomVisit(models.Model):
    student = models.ForeignKey('students.Student', on_delete=models.CASCADE, related_name='sick_visits')
    visit_date = models.DateField(auto_now_add=True)
    symptoms = models.TextField()
    treatment_given = models.TextField(blank=True)
    referred_to_doctor = models.BooleanField(default=False)
    parent_notified = models.BooleanField(default=False)
    attended_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self): return f"{self.student.full_name} — {self.visit_date}"
    class Meta: db_table = 'sick_room_visit'; app_label = 'health'
