"""
Dashboard Views - MVT
"""
from django.views.generic import TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Count, Sum, Q
from django.utils import timezone
import datetime


class DashboardHomeView(LoginRequiredMixin, TemplateView):
    template_name = 'dashboard/home.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from apps.students.models import Student
        from apps.staff.models import Staff
        from apps.fees.models import FeePayment
        from apps.attendance.models import StudentAttendance
        from apps.communication.models import Notice

        today = timezone.now().date()

        # Stats cards
        total_students = Student.objects.filter(is_active=True).count()
        total_staff = Staff.objects.filter(is_active=True).count()
        fee_collected_today = FeePayment.objects.filter(
            payment_date=today
        ).aggregate(total=Sum('amount_paid'))['total'] or 0
        present_today = StudentAttendance.objects.filter(
            date=today, status='present'
        ).count()
        total_today = StudentAttendance.objects.filter(date=today).count()
        attendance_pct = round((present_today / total_today * 100) if total_today else 0, 1)

        # Recent notices
        recent_notices = Notice.objects.filter(
            is_active=True
        ).order_by('-created_at')[:5]

        # Monthly fee collection (last 6 months)
        months_data = []
        for i in range(5, -1, -1):
            d = today - datetime.timedelta(days=30 * i)
            total = FeePayment.objects.filter(
                payment_date__year=d.year,
                payment_date__month=d.month
            ).aggregate(t=Sum('amount_paid'))['t'] or 0
            months_data.append({
                'month': d.strftime('%b'),
                'total': float(total),
            })

        ctx.update({
            'page_title': 'Dashboard',
            'total_students': total_students,
            'total_staff': total_staff,
            'fee_collected_today': fee_collected_today,
            'attendance_pct': attendance_pct,
            'present_today': present_today,
            'total_today': total_today,
            'recent_notices': recent_notices,
            'months_data': months_data,
            'today': today,
        })
        return ctx
