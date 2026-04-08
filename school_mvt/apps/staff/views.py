# views.py
from django.views.generic import ListView, DetailView, CreateView, UpdateView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.db.models import Q, Sum
from .models import Staff, LeaveRequest, SalarySlip, Department


class StaffListView(LoginRequiredMixin, ListView):
    model = Staff
    template_name = 'staff/list.html'
    context_object_name = 'staff_list'
    paginate_by = 20

    def get_queryset(self):
        qs = Staff.objects.filter(is_active=True).select_related(
            'user', 'department', 'designation'
        )
        search = self.request.GET.get('search', '')
        dept = self.request.GET.get('department', '')
        emp_type = self.request.GET.get('type', '')
        if search:
            qs = qs.filter(
                Q(user__first_name__icontains=search) |
                Q(user__last_name__icontains=search) |
                Q(employee_id__icontains=search)
            )
        if dept:
            qs = qs.filter(department_id=dept)
        if emp_type:
            qs = qs.filter(employment_type=emp_type)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Staff Management',
            'departments': Department.objects.all(),
            'employment_choices': Staff.EMPLOYMENT_TYPE_CHOICES,
            'search': self.request.GET.get('search', ''),
            'total_staff': Staff.objects.filter(is_active=True).count(),
        })
        return ctx


class StaffDetailView(LoginRequiredMixin, DetailView):
    model = Staff
    template_name = 'staff/detail.html'
    context_object_name = 'staff'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        staff = self.object
        ctx.update({
            'page_title': staff.full_name,
            'leave_requests': LeaveRequest.objects.filter(staff=staff).order_by('-applied_on')[:5],
            'salary_slips': SalarySlip.objects.filter(staff=staff).order_by('-year', '-month')[:6],
        })
        return ctx


class LeaveRequestView(LoginRequiredMixin, TemplateView):
    template_name = 'staff/leave.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        status = self.request.GET.get('status', 'pending')
        leaves = LeaveRequest.objects.select_related(
            'staff__user', 'leave_type', 'approved_by'
        ).order_by('-applied_on')
        if status:
            leaves = leaves.filter(status=status)
        ctx.update({
            'page_title': 'Leave Requests',
            'leaves': leaves,
            'status_filter': status,
            'status_choices': LeaveRequest.STATUS_CHOICES,
            'pending_count': LeaveRequest.objects.filter(status='pending').count(),
        })
        return ctx

    def post(self, request):
        leave_id = request.POST.get('leave_id')
        action = request.POST.get('action')
        remarks = request.POST.get('remarks', '')
        leave = LeaveRequest.objects.get(pk=leave_id)
        if action == 'approve':
            leave.status = 'approved'
            leave.approved_by = request.user
            leave.remarks = remarks
            leave.save()
            messages.success(request, 'Leave approved.')
        elif action == 'reject':
            leave.status = 'rejected'
            leave.approved_by = request.user
            leave.remarks = remarks
            leave.save()
            messages.warning(request, 'Leave rejected.')
        from django.shortcuts import redirect
        return redirect('staff:leave')


class PayrollView(LoginRequiredMixin, TemplateView):
    template_name = 'staff/payroll.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from django.utils import timezone
        today = timezone.now().date()
        ctx.update({
            'page_title': 'Payroll',
            'salary_slips': SalarySlip.objects.select_related('staff__user').order_by(
                '-year', '-month'
            )[:20],
            'current_month': today.month,
            'current_year': today.year,
            'months': range(1, 13),
            'total_payable': SalarySlip.objects.filter(
                month=today.month, year=today.year, is_paid=False
            ).aggregate(t=Sum('net_pay'))['t'] or 0,
        })
        return ctx
