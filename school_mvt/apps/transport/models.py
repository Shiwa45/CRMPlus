from django.db import models
from django.conf import settings


class Vehicle(models.Model):
    VEHICLE_TYPE_CHOICES = [
        ('bus', 'Bus'), ('van', 'Van'), ('auto', 'Auto'), ('other', 'Other')
    ]
    registration_number = models.CharField(max_length=20, unique=True)
    vehicle_type = models.CharField(max_length=10, choices=VEHICLE_TYPE_CHOICES, default='bus')
    make_model = models.CharField(max_length=100, blank=True)
    seating_capacity = models.PositiveSmallIntegerField(default=40)
    fitness_expiry = models.DateField(null=True, blank=True)
    insurance_expiry = models.DateField(null=True, blank=True)
    puc_expiry = models.DateField(null=True, blank=True)
    permit_expiry = models.DateField(null=True, blank=True)
    gps_device_id = models.CharField(max_length=50, blank=True)
    driver = models.ForeignKey(
        'staff.Staff', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='driving_vehicles'
    )
    conductor = models.ForeignKey(
        'staff.Staff', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='conducting_vehicles'
    )
    is_active = models.BooleanField(default=True)

    def __str__(self): return f"{self.registration_number} ({self.get_vehicle_type_display()})"
    class Meta: db_table = 'transport_vehicle'


class Route(models.Model):
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=20, unique=True)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.SET_NULL, null=True, blank=True, related_name='routes')
    start_point = models.CharField(max_length=100)
    end_point = models.CharField(max_length=100)
    total_distance_km = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    morning_departure = models.TimeField()
    morning_arrival = models.TimeField()
    evening_departure = models.TimeField()
    evening_arrival = models.TimeField()
    monthly_fee = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)

    def __str__(self): return f"{self.name} ({self.code})"
    class Meta: db_table = 'transport_route'


class RouteStop(models.Model):
    route = models.ForeignKey(Route, on_delete=models.CASCADE, related_name='stops')
    stop_name = models.CharField(max_length=100)
    stop_order = models.PositiveSmallIntegerField()
    morning_pickup_time = models.TimeField(null=True, blank=True)
    evening_drop_time = models.TimeField(null=True, blank=True)
    landmark = models.CharField(max_length=200, blank=True)

    def __str__(self): return f"{self.route.name} → {self.stop_name}"
    class Meta: db_table = 'transport_stop'; ordering = ['route', 'stop_order']


class StudentTransport(models.Model):
    student = models.OneToOneField(
        'students.Student', on_delete=models.CASCADE, related_name='transport'
    )
    route = models.ForeignKey(Route, on_delete=models.CASCADE, related_name='students')
    stop = models.ForeignKey(RouteStop, on_delete=models.CASCADE)
    pickup_required = models.BooleanField(default=True)
    dropoff_required = models.BooleanField(default=True)
    academic_year = models.CharField(max_length=10, default='2024-25')
    effective_from = models.DateField()
    effective_to = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    def __str__(self): return f"{self.student.full_name} → {self.route.name}"
    class Meta: db_table = 'student_transport'
