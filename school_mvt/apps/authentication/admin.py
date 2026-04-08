from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import User

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = ["username", "email", "get_full_name", "role", "is_active"]
    list_filter = ["role", "is_active", "is_staff"]
    fieldsets = UserAdmin.fieldsets + (
        ("School Info", {"fields": ("role", "phone", "profile_picture")}),
    )
    add_fieldsets = UserAdmin.add_fieldsets + (
        ("School Info", {"fields": ("role", "phone")}),
    )
