from django.db import models
from django.conf import settings


class StudentAttendance(models.Model):
    STATUS_CHOICES = [
        ('present', 'Present'),
        ('absent', 'Absent'),
        ('late', 'Late'),
        ('half_day', 'Half Day'),
        ('holiday', 'Holiday'),
        ('leave', 'Leave'),
    ]
    student = models.ForeignKey(
        'students.Student', on_delete=models.CASCADE, related_name='attendance_records'
    )
    date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='present')
    marked_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    remarks = models.CharField(max_length=200, blank=True)
    section = models.ForeignKey(
        'academics.Section', on_delete=models.SET_NULL, null=True, blank=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'student_attendance'
        unique_together = ('student', 'date')
        ordering = ['-date']

    def __str__(self):
        return f"{self.student} | {self.date} | {self.status}"


class StaffAttendance(models.Model):
    STATUS_CHOICES = [
        ('present', 'Present'), ('absent', 'Absent'),
        ('half_day', 'Half Day'), ('on_duty', 'On Duty'),
        ('leave', 'Leave'),
    ]
    staff = models.ForeignKey(
        'staff.Staff', on_delete=models.CASCADE, related_name='attendance_records'
    )
    date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='present')
    check_in = models.TimeField(null=True, blank=True)
    check_out = models.TimeField(null=True, blank=True)
    remarks = models.CharField(max_length=200, blank=True)

    class Meta:
        db_table = 'staff_attendance'
        unique_together = ('staff', 'date')
        ordering = ['-date']


class Holiday(models.Model):
    date = models.DateField(unique=True)
    name = models.CharField(max_length=100)
    is_optional = models.BooleanField(default=False)

    class Meta:
        db_table = 'holidays'
        ordering = ['date']

    def __str__(self):
        return f"{self.name} ({self.date})"
