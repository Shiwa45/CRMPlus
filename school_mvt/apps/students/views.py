"""
Students Views - MVT
"""
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import (
    ListView, DetailView, CreateView, UpdateView, DeleteView, TemplateView
)
from django.contrib import messages
from django.urls import reverse_lazy
from django.db.models import Q, Count
from django.core.paginator import Paginator
from .models import Student, Guardian
from .forms import StudentForm, GuardianForm
from apps.academics.models import Class, Section


class StudentListView(LoginRequiredMixin, ListView):
    model = Student
    template_name = 'students/list.html'
    context_object_name = 'students'
    paginate_by = 20

    def get_queryset(self):
        qs = Student.objects.select_related('current_class', 'current_section').order_by(
            'current_class', 'roll_number', 'first_name'
        )
        search = self.request.GET.get('search', '')
        class_id = self.request.GET.get('class_id', '')
        section_id = self.request.GET.get('section_id', '')
        status = self.request.GET.get('status', 'active')
        gender = self.request.GET.get('gender', '')

        if search:
            qs = qs.filter(
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search) |
                Q(admission_number__icontains=search) |
                Q(roll_number__icontains=search)
            )
        if class_id:
            qs = qs.filter(current_class_id=class_id)
        if section_id:
            qs = qs.filter(current_section_id=section_id)
        if status:
            qs = qs.filter(status=status)
        if gender:
            qs = qs.filter(gender=gender)

        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Students',
            'classes': Class.objects.all().order_by('order'),
            'sections': Section.objects.all(),
            'search': self.request.GET.get('search', ''),
            'selected_class': self.request.GET.get('class_id', ''),
            'selected_section': self.request.GET.get('section_id', ''),
            'selected_status': self.request.GET.get('status', 'active'),
            'total_count': self.get_queryset().count(),
            'gender_choices': Student.GENDER_CHOICES,
        })
        return ctx


class StudentDetailView(LoginRequiredMixin, DetailView):
    model = Student
    template_name = 'students/detail.html'
    context_object_name = 'student'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        student = self.object
        ctx.update({
            'page_title': student.full_name,
            'guardians': student.guardians.all(),
            'attendance_summary': self._get_attendance_summary(student),
            'fee_summary': self._get_fee_summary(student),
            'recent_exams': self._get_recent_exams(student),
        })
        return ctx

    def _get_attendance_summary(self, student):
        from apps.attendance.models import StudentAttendance
        records = StudentAttendance.objects.filter(student=student)
        total = records.count()
        present = records.filter(status='present').count()
        return {
            'total': total,
            'present': present,
            'absent': total - present,
            'percentage': round((present / total * 100), 1) if total else 0,
        }

    def _get_fee_summary(self, student):
        from apps.fees.models import FeePayment
        from django.db.models import Sum
        paid = FeePayment.objects.filter(student=student).aggregate(
            total=Sum('amount_paid')
        )['total'] or 0
        return {'paid': paid}

    def _get_recent_exams(self, student):
        from apps.examinations.models import StudentMark
        return StudentMark.objects.filter(
            student=student
        ).select_related('exam', 'subject').order_by('-exam__start_date')[:5]


class StudentCreateView(LoginRequiredMixin, CreateView):
    model = Student
    form_class = StudentForm
    template_name = 'students/form.html'
    success_url = reverse_lazy('students:list')

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = 'Add New Student'
        ctx['action'] = 'Add'
        return ctx

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, f'Student {self.object.full_name} added successfully.')
        return response


class StudentUpdateView(LoginRequiredMixin, UpdateView):
    model = Student
    form_class = StudentForm
    template_name = 'students/form.html'

    def get_success_url(self):
        return reverse_lazy('students:detail', kwargs={'pk': self.object.pk})

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = f'Edit {self.object.full_name}'
        ctx['action'] = 'Update'
        return ctx

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, 'Student profile updated.')
        return response


class StudentDeleteView(LoginRequiredMixin, DeleteView):
    model = Student
    template_name = 'students/confirm_delete.html'
    success_url = reverse_lazy('students:list')

    def delete(self, request, *args, **kwargs):
        student = self.get_object()
        messages.warning(request, f'{student.full_name} has been removed.')
        return super().delete(request, *args, **kwargs)


class AdmissionsView(LoginRequiredMixin, TemplateView):
    template_name = 'students/admissions.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = 'Student Admissions'
        ctx['classes'] = Class.objects.all().order_by('order')
        ctx['recent_admissions'] = Student.objects.order_by('-admission_date')[:20]
        return ctx


class PromotionsView(LoginRequiredMixin, TemplateView):
    template_name = 'students/promotions.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = 'Student Promotions'
        ctx['classes'] = Class.objects.all().order_by('order')
        return ctx
