from django.db import models
from django.conf import settings


class HouseTeam(models.Model):
    name = models.CharField(max_length=50)
    color = models.CharField(max_length=20, blank=True)
    house_master = models.ForeignKey(
        'staff.Staff', on_delete=models.SET_NULL, null=True, blank=True
    )
    is_active = models.BooleanField(default=True)

    def __str__(self): return self.name
    class Meta: db_table = 'house_team'; app_label = 'sports'


class Sport(models.Model):
    name = models.CharField(max_length=100)
    category = models.CharField(max_length=50, choices=[
        ('indoor', 'Indoor'), ('outdoor', 'Outdoor'), ('water', 'Water')
    ], default='outdoor')
    coach = models.ForeignKey(
        'staff.Staff', on_delete=models.SET_NULL, null=True, blank=True
    )
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self): return self.name
    class Meta: db_table = 'sport'; app_label = 'sports'


class Activity(models.Model):
    """Extra-curricular activities: music, dance, drama, art, debate..."""
    name = models.CharField(max_length=100)
    category = models.CharField(max_length=50, choices=[
        ('music', 'Music'), ('dance', 'Dance'), ('drama', 'Drama'),
        ('art', 'Art'), ('debate', 'Debate'), ('club', 'Club'), ('other', 'Other'),
    ], default='club')
    coordinator = models.ForeignKey(
        'staff.Staff', on_delete=models.SET_NULL, null=True, blank=True
    )
    schedule = models.CharField(max_length=200, blank=True)
    max_members = models.PositiveSmallIntegerField(default=30)
    is_active = models.BooleanField(default=True)

    def __str__(self): return self.name
    class Meta: db_table = 'activity'; app_label = 'sports'; verbose_name_plural = 'Activities'


class StudentAchievement(models.Model):
    LEVEL_CHOICES = [
        ('school', 'School'), ('inter_school', 'Inter-School'),
        ('district', 'District'), ('state', 'State'),
        ('national', 'National'), ('international', 'International'),
    ]
    POSITION_CHOICES = [
        ('1', '1st'), ('2', '2nd'), ('3', '3rd'),
        ('participation', 'Participation'), ('other', 'Other'),
    ]
    student = models.ForeignKey('students.Student', on_delete=models.CASCADE, related_name='achievements')
    achievement_type = models.CharField(max_length=20, choices=[
        ('sport', 'Sports'), ('activity', 'Activity'), ('academic', 'Academic'), ('other', 'Other')
    ])
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    level = models.CharField(max_length=20, choices=LEVEL_CHOICES)
    position = models.CharField(max_length=15, choices=POSITION_CHOICES)
    date = models.DateField()
    certificate = models.FileField(upload_to='certificates/', null=True, blank=True)
    added_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.student.full_name} — {self.title}"
    class Meta: db_table = 'student_achievement'; app_label = 'sports'; ordering = ['-date']
