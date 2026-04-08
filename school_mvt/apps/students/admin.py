from django.contrib import admin
from .models import Student, Guardian

@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ["admission_number", "full_name", "current_class", "current_section", "status"]
    list_filter = ["status", "current_class", "gender"]
    search_fields = ["first_name", "last_name", "admission_number"]
    list_per_page = 30

@admin.register(Guardian)
class GuardianAdmin(admin.ModelAdmin):
    list_display = ["name", "relation", "phone", "email"]
