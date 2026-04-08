from django.views.generic import TemplateView, ListView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.shortcuts import redirect
from .models import SchoolSettings, GradeConfiguration, AcademicYearSettings


class SettingsDashboardView(LoginRequiredMixin, TemplateView):
    template_name = "settings_app/dashboard.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "School Settings",
            "settings": SchoolSettings.objects.all().order_by("key"),
            "grade_config": GradeConfiguration.objects.all().order_by("-min_percentage"),
            "academic_years": AcademicYearSettings.objects.all().order_by("-year"),
        })
        return ctx

    def post(self, request):
        key = request.POST.get("key")
        value = request.POST.get("value")
        description = request.POST.get("description", "")
        if key and value is not None:
            SchoolSettings.set(key, value, description)
            messages.success(request, f"Setting '{key}' updated.")
        return redirect("settings_app:dashboard")


class TenantSettingsView(LoginRequiredMixin, TemplateView):
    """View to see and edit current tenant (school) settings."""
    template_name = "settings_app/tenant.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from django.db import connection
        ctx.update({
            "page_title": "School Profile & Configuration",
            "schema": connection.schema_name,
        })
        return ctx
