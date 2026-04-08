# models.py
from django.db import models
from django.conf import settings


class AcademicYear(models.Model):
    name = models.CharField(max_length=10, unique=True)  # e.g. 2024-25
    start_date = models.DateField()
    end_date = models.DateField()
    is_current = models.BooleanField(default=False)

    def __str__(self):
        return self.name

    class Meta:
        db_table = 'academic_years'


class Class(models.Model):
    name = models.CharField(max_length=20)  # e.g. Class 1, LKG
    order = models.PositiveSmallIntegerField(default=0)
    stream = models.CharField(max_length=20, blank=True,
                               choices=[('', 'None'), ('science', 'Science'),
                                        ('commerce', 'Commerce'), ('arts', 'Arts')])

    def __str__(self):
        return self.name

    class Meta:
        db_table = 'classes'
        verbose_name_plural = 'Classes'
        ordering = ['order']


class Section(models.Model):
    school_class = models.ForeignKey(Class, on_delete=models.CASCADE, related_name='sections')
    name = models.CharField(max_length=5)  # A, B, C...
    class_teacher = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='class_teacher_of'
    )
    max_strength = models.PositiveSmallIntegerField(default=40)
    room_number = models.CharField(max_length=10, blank=True)

    def __str__(self):
        return f"{self.school_class.name} - {self.name}"

    class Meta:
        db_table = 'sections'
        unique_together = ('school_class', 'name')


class Subject(models.Model):
    SUBJECT_TYPE_CHOICES = [
        ('core', 'Core'), ('elective', 'Elective'),
        ('optional', 'Optional'), ('activity', 'Activity'),
    ]
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=10, unique=True)
    subject_type = models.CharField(max_length=20, choices=SUBJECT_TYPE_CHOICES, default='core')
    has_practical = models.BooleanField(default=False)
    max_theory_marks = models.PositiveSmallIntegerField(default=100)
    max_practical_marks = models.PositiveSmallIntegerField(default=0)
    passing_marks = models.PositiveSmallIntegerField(default=33)
    classes = models.ManyToManyField(Class, blank=True, related_name='subjects')
    teachers = models.ManyToManyField(
        settings.AUTH_USER_MODEL, blank=True, related_name='teaching_subjects'
    )

    def __str__(self):
        return f"{self.name} ({self.code})"

    class Meta:
        db_table = 'subjects'


class Period(models.Model):
    name = models.CharField(max_length=20)  # Period 1, Break, etc.
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_break = models.BooleanField(default=False)
    order = models.PositiveSmallIntegerField(default=0)

    def __str__(self):
        return f"{self.name} ({self.start_time} - {self.end_time})"

    class Meta:
        db_table = 'periods'
        ordering = ['order']


class Timetable(models.Model):
    DAY_CHOICES = [
        (1, 'Monday'), (2, 'Tuesday'), (3, 'Wednesday'),
        (4, 'Thursday'), (5, 'Friday'), (6, 'Saturday'),
    ]
    section = models.ForeignKey(Section, on_delete=models.CASCADE, related_name='timetable')
    day = models.PositiveSmallIntegerField(choices=DAY_CHOICES)
    period = models.ForeignKey(Period, on_delete=models.CASCADE)
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    teacher = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    academic_year = models.ForeignKey(AcademicYear, on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.section} | {self.get_day_display()} | {self.period} | {self.subject}"

    class Meta:
        db_table = 'timetable'
        unique_together = ('section', 'day', 'period', 'academic_year')


class Homework(models.Model):
    STATUS_CHOICES = [('active', 'Active'), ('closed', 'Closed')]
    subject = models.ForeignKey(Subject, on_delete=models.CASCADE)
    section = models.ForeignKey(Section, on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    description = models.TextField()
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True
    )
    assigned_date = models.DateField(auto_now_add=True)
    due_date = models.DateField()
    attachment = models.FileField(upload_to='homework/', null=True, blank=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='active')

    def __str__(self):
        return f"{self.title} | {self.section}"

    class Meta:
        db_table = 'homework'
        ordering = ['-assigned_date']
