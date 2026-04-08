from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Count, Sum, Avg, Q
from django.utils import timezone
import datetime


class ReportsDashboardView(LoginRequiredMixin, TemplateView):
    template_name = "reports/dashboard.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Reports & Analytics",
            "report_categories": [
                {"name": "Academic Reports", "icon": "bi-book-fill", "color": "#1a56db", "url": "reports:academic"},
                {"name": "Fee Reports", "icon": "bi-cash-coin", "color": "#059669", "url": "reports:fee"},
                {"name": "Attendance Reports", "icon": "bi-calendar-check-fill", "color": "#d97706", "url": "reports:attendance_report"},
                {"name": "Staff Reports", "icon": "bi-person-badge-fill", "color": "#7c3aed", "url": "reports:staff_report"},
            ],
        })
        return ctx


class AcademicReportView(LoginRequiredMixin, TemplateView):
    template_name = "reports/academic.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from apps.students.models import Student
        from apps.academics.models import Class
        from apps.examinations.models import StudentMark
        ctx.update({
            "page_title": "Academic Reports",
            "total_students": Student.objects.filter(is_active=True).count(),
            "class_wise": Class.objects.annotate(
                student_count=Count("students")
            ).order_by("order"),
            "classes": Class.objects.all().order_by("order"),
        })
        return ctx


class FeeReportView(LoginRequiredMixin, TemplateView):
    template_name = "reports/fee.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from apps.fees.models import FeePayment
        today = timezone.now().date()
        ctx.update({
            "page_title": "Fee Reports",
            "total_collected": FeePayment.objects.aggregate(t=Sum("amount_paid"))["t"] or 0,
            "today_collected": FeePayment.objects.filter(payment_date=today).aggregate(t=Sum("amount_paid"))["t"] or 0,
            "monthly": [
                {
                    "month": (today.replace(day=1) - datetime.timedelta(days=30*i)).strftime("%b %Y"),
                    "total": float(FeePayment.objects.filter(
                        payment_date__year=(today.replace(day=1) - datetime.timedelta(days=30*i)).year,
                        payment_date__month=(today.replace(day=1) - datetime.timedelta(days=30*i)).month,
                    ).aggregate(t=Sum("amount_paid"))["t"] or 0),
                }
                for i in range(11, -1, -1)
            ],
        })
        return ctx


class AttendanceReportSummaryView(LoginRequiredMixin, TemplateView):
    template_name = "reports/attendance.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from apps.attendance.models import StudentAttendance
        from apps.academics.models import Class
        today = timezone.now().date()
        ctx.update({
            "page_title": "Attendance Reports",
            "today_present": StudentAttendance.objects.filter(date=today, status="present").count(),
            "today_absent": StudentAttendance.objects.filter(date=today, status="absent").count(),
            "classes": Class.objects.all().order_by("order"),
        })
        return ctx


class StaffReportView(LoginRequiredMixin, TemplateView):
    template_name = "reports/staff.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from apps.staff.models import Staff, Department
        ctx.update({
            "page_title": "Staff Reports",
            "total_staff": Staff.objects.filter(is_active=True).count(),
            "by_department": Department.objects.annotate(
                staff_count=Count("staff", filter=Q(staff__is_active=True))
            ),
            "by_type": Staff.objects.filter(is_active=True).values(
                "employment_type"
            ).annotate(count=Count("id")),
        })
        return ctx
