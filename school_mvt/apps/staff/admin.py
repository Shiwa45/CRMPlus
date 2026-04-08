from django.contrib import admin
from .models import Staff, Department, Designation, LeaveType, LeaveRequest

admin.site.register(Department)
admin.site.register(Designation)
admin.site.register(LeaveType)

@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    list_display = ["employee_id", "full_name", "department", "is_active"]
    list_filter = ["department", "employment_type"]

@admin.register(LeaveRequest)
class LeaveRequestAdmin(admin.ModelAdmin):
    list_display = ["staff", "leave_type", "from_date", "to_date", "status"]
