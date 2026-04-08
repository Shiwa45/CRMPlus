"""
Authentication Models - Custom User with roles
"""
from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    ROLE_CHOICES = [
        ('super_admin', 'Super Admin'),
        ('school_admin', 'School Admin'),
        ('principal', 'Principal'),
        ('vice_principal', 'Vice Principal'),
        ('teacher', 'Teacher'),
        ('student', 'Student'),
        ('parent', 'Parent/Guardian'),
        ('accountant', 'Accountant'),
        ('librarian', 'Librarian'),
        ('transport_manager', 'Transport Manager'),
        ('support_staff', 'Support Staff'),
    ]

    role = models.CharField(max_length=30, choices=ROLE_CHOICES, default='teacher')
    phone = models.CharField(max_length=15, blank=True)
    profile_picture = models.ImageField(upload_to='profiles/', null=True, blank=True)
    is_active = models.BooleanField(default=True)
    last_login_ip = models.GenericIPAddressField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'auth_users'
        verbose_name = 'User'
        verbose_name_plural = 'Users'

    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.get_role_display()})"

    @property
    def is_admin(self):
        return self.role in ('super_admin', 'school_admin', 'principal')

    @property
    def is_teacher(self):
        return self.role == 'teacher'

    @property
    def is_student(self):
        return self.role == 'student'

    def get_dashboard_url(self):
        return '/dashboard/'
