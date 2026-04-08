from django.db import models
from django.conf import settings


class Department(models.Model):
    name = models.CharField(max_length=100)
    head = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='department_head'
    )

    def __str__(self):
        return self.name

    class Meta:
        db_table = 'departments'


class Designation(models.Model):
    name = models.CharField(max_length=100)
    department = models.ForeignKey(Department, on_delete=models.CASCADE, related_name='designations')

    def __str__(self):
        return f"{self.name} ({self.department})"

    class Meta:
        db_table = 'designations'


class Staff(models.Model):
    EMPLOYMENT_TYPE_CHOICES = [
        ('permanent', 'Permanent'), ('temporary', 'Temporary'),
        ('contract', 'Contract'), ('guest', 'Guest'),
    ]
    GENDER_CHOICES = [('M', 'Male'), ('F', 'Female'), ('O', 'Other')]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='staff_profile'
    )
    employee_id = models.CharField(max_length=20, unique=True)
    department = models.ForeignKey(Department, on_delete=models.SET_NULL, null=True, blank=True)
    designation = models.ForeignKey(Designation, on_delete=models.SET_NULL, null=True, blank=True)
    employment_type = models.CharField(max_length=20, choices=EMPLOYMENT_TYPE_CHOICES, default='permanent')
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    joining_date = models.DateField()
    relieving_date = models.DateField(null=True, blank=True)
    phone = models.CharField(max_length=15, blank=True)
    emergency_contact = models.CharField(max_length=15, blank=True)
    address = models.TextField(blank=True)
    aadhar_number = models.CharField(max_length=12, blank=True)
    pan_number = models.CharField(max_length=10, blank=True)
    bank_account = models.CharField(max_length=20, blank=True)
    bank_ifsc = models.CharField(max_length=11, blank=True)
    bank_name = models.CharField(max_length=100, blank=True)
    qualification = models.TextField(blank=True)
    experience_years = models.PositiveSmallIntegerField(default=0)
    basic_salary = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    is_active = models.BooleanField(default=True)
    photo = models.ImageField(upload_to='staff/photos/', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.get_full_name()} ({self.employee_id})"

    class Meta:
        db_table = 'staff'
        verbose_name_plural = 'Staff'

    @property
    def full_name(self):
        return self.user.get_full_name()


class LeaveType(models.Model):
    name = models.CharField(max_length=50)
    code = models.CharField(max_length=10, unique=True)
    days_allowed = models.PositiveSmallIntegerField(default=12)
    is_paid = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.code})"

    class Meta:
        db_table = 'leave_types'


class LeaveRequest(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'), ('approved', 'Approved'),
        ('rejected', 'Rejected'), ('cancelled', 'Cancelled'),
    ]
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='leave_requests')
    leave_type = models.ForeignKey(LeaveType, on_delete=models.CASCADE)
    from_date = models.DateField()
    to_date = models.DateField()
    total_days = models.PositiveSmallIntegerField()
    reason = models.TextField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    approved_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='approved_leaves'
    )
    applied_on = models.DateTimeField(auto_now_add=True)
    remarks = models.TextField(blank=True)

    def __str__(self):
        return f"{self.staff} | {self.leave_type} | {self.from_date} to {self.to_date}"

    class Meta:
        db_table = 'leave_requests'
        ordering = ['-applied_on']


class SalarySlip(models.Model):
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='salary_slips')
    month = models.PositiveSmallIntegerField()
    year = models.PositiveSmallIntegerField()
    basic = models.DecimalField(max_digits=10, decimal_places=2)
    hra = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    da = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    ta = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    other_allowances = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    gross = models.DecimalField(max_digits=10, decimal_places=2)
    pf_deduction = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    esi_deduction = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    tds = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    other_deductions = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    net_pay = models.DecimalField(max_digits=10, decimal_places=2)
    paid_on = models.DateField(null=True, blank=True)
    is_paid = models.BooleanField(default=False)

    class Meta:
        db_table = 'salary_slips'
        unique_together = ('staff', 'month', 'year')
