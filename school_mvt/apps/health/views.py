from django.views.generic import ListView, CreateView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.db.models import Avg
from .models import HealthRecord, SickRoomVisit
from apps.students.models import Student


class HealthRecordListView(LoginRequiredMixin, ListView):
    model = HealthRecord
    template_name = "health/records.html"
    context_object_name = "records"
    paginate_by = 20

    def get_queryset(self):
        qs = HealthRecord.objects.select_related("student", "checked_by")
        student_id = self.request.GET.get("student_id")
        if student_id:
            qs = qs.filter(student_id=student_id)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Health Records",
            "students": Student.objects.filter(is_active=True).order_by("first_name"),
            "avg_bmi": HealthRecord.objects.aggregate(avg=Avg("bmi"))["avg"],
        })
        return ctx


class SickRoomView(LoginRequiredMixin, ListView):
    model = SickRoomVisit
    template_name = "health/sick_room.html"
    context_object_name = "visits"
    paginate_by = 20

    def get_queryset(self):
        return SickRoomVisit.objects.select_related(
            "student", "attended_by"
        ).order_by("-visit_date")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Sick Room",
            "students": Student.objects.filter(is_active=True),
            "today_count": SickRoomVisit.objects.filter(
                visit_date=__import__("django.utils.timezone", fromlist=["now"]).now().date()
            ).count(),
        })
        return ctx

    def post(self, request):
        from django.shortcuts import redirect
        from django.utils import timezone
        SickRoomVisit.objects.create(
            student_id=request.POST.get("student_id"),
            symptoms=request.POST.get("symptoms"),
            treatment_given=request.POST.get("treatment_given", ""),
            referred_to_doctor=bool(request.POST.get("referred")),
            parent_notified=bool(request.POST.get("parent_notified")),
            attended_by=request.user,
        )
        messages.success(request, "Sick room visit recorded.")
        return redirect("health:sick_room")
