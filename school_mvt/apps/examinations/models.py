# models.py
from django.db import models
from django.conf import settings


class Exam(models.Model):
    EXAM_TYPE_CHOICES = [
        ('unit_test', 'Unit Test'), ('mid_term', 'Mid Term'),
        ('final', 'Final / Annual'), ('pre_board', 'Pre-Board'),
        ('quarterly', 'Quarterly'),
    ]
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'), ('ongoing', 'Ongoing'),
        ('completed', 'Completed'), ('cancelled', 'Cancelled'),
    ]
    name = models.CharField(max_length=100)
    exam_type = models.CharField(max_length=20, choices=EXAM_TYPE_CHOICES)
    academic_year = models.CharField(max_length=10, default='2024-25')
    classes = models.ManyToManyField('academics.Class', related_name='exams')
    start_date = models.DateField()
    end_date = models.DateField()
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='scheduled')
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )

    def __str__(self):
        return f"{self.name} ({self.academic_year})"

    class Meta:
        db_table = 'exams'
        ordering = ['-start_date']


class ExamSchedule(models.Model):
    exam = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='schedules')
    school_class = models.ForeignKey('academics.Class', on_delete=models.CASCADE)
    subject = models.ForeignKey('academics.Subject', on_delete=models.CASCADE)
    exam_date = models.DateField()
    start_time = models.TimeField()
    end_time = models.TimeField()
    room = models.CharField(max_length=20, blank=True)
    max_marks = models.PositiveSmallIntegerField(default=100)

    class Meta:
        db_table = 'exam_schedules'
        ordering = ['exam_date', 'start_time']


class StudentMark(models.Model):
    GRADE_CHOICES = [
        ('A1', 'A1 (91-100)'), ('A2', 'A2 (81-90)'),
        ('B1', 'B1 (71-80)'), ('B2', 'B2 (61-70)'),
        ('C1', 'C1 (51-60)'), ('C2', 'C2 (41-50)'),
        ('D', 'D (33-40)'), ('E', 'E (below 33)'),
    ]
    student = models.ForeignKey('students.Student', on_delete=models.CASCADE, related_name='marks')
    exam = models.ForeignKey(Exam, on_delete=models.CASCADE, related_name='student_marks')
    subject = models.ForeignKey('academics.Subject', on_delete=models.CASCADE)
    theory_marks = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    practical_marks = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    total_marks = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    grade = models.CharField(max_length=5, choices=GRADE_CHOICES, blank=True)
    is_absent = models.BooleanField(default=False)
    entered_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True
    )
    entered_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'student_marks'
        unique_together = ('student', 'exam', 'subject')

    def save(self, *args, **kwargs):
        # Auto-calculate total and grade
        theory = float(self.theory_marks or 0)
        practical = float(self.practical_marks or 0)
        self.total_marks = theory + practical
        pct = (self.total_marks / 100) * 100
        if pct >= 91: self.grade = 'A1'
        elif pct >= 81: self.grade = 'A2'
        elif pct >= 71: self.grade = 'B1'
        elif pct >= 61: self.grade = 'B2'
        elif pct >= 51: self.grade = 'C1'
        elif pct >= 41: self.grade = 'C2'
        elif pct >= 33: self.grade = 'D'
        else: self.grade = 'E'
        super().save(*args, **kwargs)
