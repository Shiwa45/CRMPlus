from django.db import models
from django.conf import settings


class Alumni(models.Model):
    student = models.OneToOneField(
        'students.Student', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='alumni_profile'
    )
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)
    graduation_year = models.PositiveSmallIntegerField()
    passed_class = models.CharField(max_length=20, default='Class 12')
    phone = models.CharField(max_length=15, blank=True)
    email = models.EmailField(blank=True)
    current_city = models.CharField(max_length=100, blank=True)
    occupation = models.CharField(max_length=200, blank=True)
    company = models.CharField(max_length=200, blank=True)
    higher_education = models.CharField(max_length=200, blank=True)
    linkedin_url = models.URLField(blank=True)
    photo = models.ImageField(upload_to='alumni/', null=True, blank=True)
    achievements = models.TextField(blank=True)
    is_verified = models.BooleanField(default=False)
    wants_to_mentor = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.first_name} {self.last_name} ({self.graduation_year})"

    class Meta:
        db_table = 'alumni'
        app_label = 'alumni'
        verbose_name_plural = 'Alumni'
        ordering = ['-graduation_year', 'first_name']
