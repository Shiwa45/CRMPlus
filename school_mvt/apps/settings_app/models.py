from django.db import models


class SchoolSettings(models.Model):
    """
    Per-tenant school configuration key-value store.
    One row per setting key.
    """
    key = models.CharField(max_length=100, unique=True)
    value = models.TextField()
    description = models.CharField(max_length=200, blank=True)
    is_public = models.BooleanField(default=False, help_text='Visible in context processor')
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self): return f"{self.key} = {self.value[:50]}"
    class Meta: db_table = 'school_settings'; app_label = 'settings_app'; verbose_name_plural = 'School Settings'

    @classmethod
    def get(cls, key, default=None):
        try:
            return cls.objects.get(key=key).value
        except cls.DoesNotExist:
            return default

    @classmethod
    def set(cls, key, value, description=''):
        obj, _ = cls.objects.update_or_create(
            key=key, defaults={'value': str(value), 'description': description}
        )
        return obj


class GradeConfiguration(models.Model):
    """Configurable grading system per school."""
    grade = models.CharField(max_length=5)
    min_percentage = models.DecimalField(max_digits=5, decimal_places=2)
    max_percentage = models.DecimalField(max_digits=5, decimal_places=2)
    grade_point = models.DecimalField(max_digits=4, decimal_places=2, default=0)
    description = models.CharField(max_length=50, blank=True)
    color_class = models.CharField(max_length=30, default='bg-secondary', help_text='Bootstrap color class')

    def __str__(self): return f"{self.grade} ({self.min_percentage}% – {self.max_percentage}%)"
    class Meta: db_table = 'grade_configuration'; app_label = 'settings_app'; ordering = ['-min_percentage']


class AcademicYearSettings(models.Model):
    year = models.CharField(max_length=10, unique=True)
    start_date = models.DateField()
    end_date = models.DateField()
    is_current = models.BooleanField(default=False)
    is_locked = models.BooleanField(default=False, help_text='Lock previous year data')

    def __str__(self): return self.year
    class Meta: db_table = 'academic_year_settings'; app_label = 'settings_app'

    def save(self, *args, **kwargs):
        if self.is_current:
            AcademicYearSettings.objects.exclude(pk=self.pk).update(is_current=False)
        super().save(*args, **kwargs)
