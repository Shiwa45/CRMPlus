"""
Student Models
"""
from django.db import models
from django.utils import timezone
import uuid


class Guardian(models.Model):
    RELATION_CHOICES = [
        ('father', 'Father'), ('mother', 'Mother'), ('guardian', 'Guardian'),
        ('sibling', 'Sibling'), ('other', 'Other'),
    ]
    name = models.CharField(max_length=100)
    relation = models.CharField(max_length=20, choices=RELATION_CHOICES)
    phone = models.CharField(max_length=15)
    email = models.EmailField(blank=True)
    occupation = models.CharField(max_length=100, blank=True)
    annual_income = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    aadhar_number = models.CharField(max_length=12, blank=True)
    is_primary = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} ({self.get_relation_display()})"

    class Meta:
        db_table = 'students_guardians'


class Student(models.Model):
    GENDER_CHOICES = [('M', 'Male'), ('F', 'Female'), ('O', 'Other')]
    BLOOD_GROUP_CHOICES = [
        ('A+', 'A+'), ('A-', 'A-'), ('B+', 'B+'), ('B-', 'B-'),
        ('O+', 'O+'), ('O-', 'O-'), ('AB+', 'AB+'), ('AB-', 'AB-'),
    ]
    CATEGORY_CHOICES = [
        ('general', 'General'), ('obc', 'OBC'), ('sc', 'SC'),
        ('st', 'ST'), ('ews', 'EWS'),
    ]
    STATUS_CHOICES = [
        ('active', 'Active'), ('inactive', 'Inactive'),
        ('transferred', 'Transferred'), ('alumni', 'Alumni'),
    ]

    # Identifiers
    admission_number = models.CharField(max_length=20, unique=True)
    roll_number = models.CharField(max_length=10, blank=True)

    # Personal
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    date_of_birth = models.DateField()
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    blood_group = models.CharField(max_length=5, choices=BLOOD_GROUP_CHOICES, blank=True)
    category = models.CharField(max_length=10, choices=CATEGORY_CHOICES, default='general')
    aadhar_number = models.CharField(max_length=12, blank=True)
    photo = models.ImageField(upload_to='students/photos/', null=True, blank=True)

    # Academic
    current_class = models.ForeignKey(
        'academics.Class', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='students'
    )
    current_section = models.ForeignKey(
        'academics.Section', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='students'
    )
    admission_date = models.DateField(default=timezone.now)
    academic_year = models.CharField(max_length=10, default='2024-25')

    # Contact
    address = models.TextField(blank=True)
    city = models.CharField(max_length=50, blank=True)
    state = models.CharField(max_length=50, blank=True)
    pincode = models.CharField(max_length=6, blank=True)

    # Guardians
    guardians = models.ManyToManyField(Guardian, blank=True, related_name='students')

    # Medical
    medical_conditions = models.TextField(blank=True)
    allergies = models.TextField(blank=True)
    emergency_contact = models.CharField(max_length=15, blank=True)

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    is_active = models.BooleanField(default=True)

    # Transport / Hostel
    requires_transport = models.BooleanField(default=False)
    requires_hostel = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'students'
        ordering = ['current_class', 'roll_number', 'first_name']

    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.admission_number})"

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

    @property
    def age(self):
        today = timezone.now().date()
        return today.year - self.date_of_birth.year - (
            (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
        )

    def get_primary_guardian(self):
        return self.guardians.filter(is_primary=True).first() or self.guardians.first()
