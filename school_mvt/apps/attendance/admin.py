from django.contrib import admin
from .models import StudentAttendance, Holiday

@admin.register(StudentAttendance)
class StudentAttendanceAdmin(admin.ModelAdmin):
    list_display = ["student", "date", "status", "marked_by"]
    list_filter = ["status", "date"]

admin.site.register(Holiday)
