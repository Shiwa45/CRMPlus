from django.views.generic import ListView, CreateView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.db.models import Count, Q
from .models import IncidentReport, DisciplinaryAction, CounsellingSession
from apps.students.models import Student


class IncidentListView(LoginRequiredMixin, ListView):
    model = IncidentReport
    template_name = "discipline/incidents.html"
    context_object_name = "incidents"
    paginate_by = 20

    def get_queryset(self):
        qs = IncidentReport.objects.select_related("student", "reported_by")
        status = self.request.GET.get("status", "")
        severity = self.request.GET.get("severity", "")
        if status:
            qs = qs.filter(status=status)
        if severity:
            qs = qs.filter(severity=severity)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Discipline — Incidents",
            "open_count": IncidentReport.objects.filter(status="open").count(),
            "severity_choices": IncidentReport.SEVERITY_CHOICES,
            "status_choices": IncidentReport.STATUS_CHOICES,
            "students": Student.objects.filter(is_active=True).order_by("first_name"),
        })
        return ctx

    def post(self, request):
        from django.shortcuts import redirect
        IncidentReport.objects.create(
            student_id=request.POST.get("student_id"),
            incident_date=request.POST.get("incident_date"),
            incident_type=request.POST.get("incident_type"),
            description=request.POST.get("description"),
            severity=request.POST.get("severity", "minor"),
            location=request.POST.get("location", ""),
            reported_by=request.user,
        )
        messages.success(request, "Incident reported.")
        return redirect("discipline:incidents")


class CounsellingView(LoginRequiredMixin, ListView):
    model = CounsellingSession
    template_name = "discipline/counselling.html"
    context_object_name = "sessions"
    paginate_by = 20

    def get_queryset(self):
        return CounsellingSession.objects.select_related("student", "counsellor").order_by("-session_date")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Counselling Sessions",
            "students": Student.objects.filter(is_active=True).order_by("first_name"),
            "session_types": CounsellingSession.SESSION_TYPE_CHOICES,
        })
        return ctx
