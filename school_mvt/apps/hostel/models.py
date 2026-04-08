from django.db import models
from django.conf import settings
from django.utils import timezone


class Hostel(models.Model):
    HOSTEL_TYPE_CHOICES = [('boys', 'Boys'), ('girls', 'Girls'), ('mixed', 'Mixed')]
    name = models.CharField(max_length=100)
    hostel_type = models.CharField(max_length=10, choices=HOSTEL_TYPE_CHOICES)
    warden = models.ForeignKey(
        'staff.Staff', on_delete=models.SET_NULL, null=True, blank=True, related_name='warden_of'
    )
    total_rooms = models.PositiveSmallIntegerField(default=0)
    address = models.TextField(blank=True)
    phone = models.CharField(max_length=15, blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self): return f"{self.name} ({self.get_hostel_type_display()})"
    class Meta: db_table = 'hostel'


class Room(models.Model):
    ROOM_TYPE_CHOICES = [
        ('single', 'Single'), ('double', 'Double'),
        ('triple', 'Triple'), ('dormitory', 'Dormitory'),
    ]
    hostel = models.ForeignKey(Hostel, on_delete=models.CASCADE, related_name='rooms')
    room_number = models.CharField(max_length=20)
    floor = models.PositiveSmallIntegerField(default=0)
    room_type = models.CharField(max_length=15, choices=ROOM_TYPE_CHOICES, default='double')
    capacity = models.PositiveSmallIntegerField(default=2)
    current_occupancy = models.PositiveSmallIntegerField(default=0)
    monthly_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    has_ac = models.BooleanField(default=False)
    has_attached_bathroom = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    def __str__(self): return f"{self.hostel.name} — Room {self.room_number}"

    @property
    def is_available(self):
        return self.current_occupancy < self.capacity

    class Meta: db_table = 'hostel_room'; unique_together = ('hostel', 'room_number')


class HostelAllocation(models.Model):
    STATUS_CHOICES = [('active', 'Active'), ('vacated', 'Vacated'), ('transferred', 'Transferred')]
    student = models.ForeignKey(
        'students.Student', on_delete=models.CASCADE, related_name='hostel_allocations'
    )
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name='allocations')
    academic_year = models.CharField(max_length=10, default='2024-25')
    allotment_date = models.DateField(default=timezone.now)
    vacating_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='active')
    emergency_contact = models.CharField(max_length=15, blank=True)
    remarks = models.TextField(blank=True)

    def __str__(self): return f"{self.student.full_name} → {self.room}"
    class Meta: db_table = 'hostel_allocation'


class HostelAttendance(models.Model):
    STATUS_CHOICES = [('present', 'Present'), ('absent', 'Absent'), ('on_leave', 'On Leave')]
    student = models.ForeignKey('students.Student', on_delete=models.CASCADE)
    date = models.DateField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='present')
    check_in_time = models.TimeField(null=True, blank=True)
    check_out_time = models.TimeField(null=True, blank=True)
    remarks = models.CharField(max_length=200, blank=True)

    class Meta: db_table = 'hostel_attendance'; unique_together = ('student', 'date')
