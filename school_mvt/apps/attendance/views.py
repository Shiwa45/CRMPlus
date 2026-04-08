from django.views.generic import TemplateView, ListView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.shortcuts import render, redirect
from django.contrib import messages
from django.utils import timezone
from django.db.models import Count, Q
from .models import StudentAttendance, Holiday
from apps.academics.models import Section, Class
from apps.students.models import Student


class MarkAttendanceView(LoginRequiredMixin, TemplateView):
    template_name = 'attendance/mark.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        section_id = self.request.GET.get('section_id')
        date_str = self.request.GET.get('date', timezone.now().date().isoformat())

        try:
            from datetime import date
            selected_date = date.fromisoformat(date_str)
        except ValueError:
            selected_date = timezone.now().date()

        selected_section = None
        students = []
        existing_records = {}

        if section_id:
            selected_section = Section.objects.filter(pk=section_id).first()
            if selected_section:
                students = Student.objects.filter(
                    current_section=selected_section, is_active=True
                ).order_by('roll_number', 'first_name')
                existing = StudentAttendance.objects.filter(
                    section=selected_section, date=selected_date
                )
                existing_records = {r.student_id: r.status for r in existing}

        ctx.update({
            'page_title': 'Mark Attendance',
            'sections': Section.objects.select_related('school_class').order_by(
                'school_class__order', 'name'
            ),
            'selected_section': selected_section,
            'selected_date': selected_date,
            'students': students,
            'existing_records': existing_records,
            'status_choices': StudentAttendance.STATUS_CHOICES,
            'is_holiday': Holiday.objects.filter(date=selected_date).exists(),
        })
        return ctx

    def post(self, request):
        section_id = request.POST.get('section_id')
        date_str = request.POST.get('date')
        section = Section.objects.get(pk=section_id)

        from datetime import date
        att_date = date.fromisoformat(date_str)

        students = Student.objects.filter(current_section=section, is_active=True)
        saved = 0
        for student in students:
            status = request.POST.get(f'status_{student.pk}', 'absent')
            obj, created = StudentAttendance.objects.update_or_create(
                student=student, date=att_date,
                defaults={
                    'status': status,
                    'section': section,
                    'marked_by': request.user,
                }
            )
            saved += 1

        messages.success(request, f'Attendance saved for {saved} students.')
        return redirect(f'/attendance/mark/?section_id={section_id}&date={date_str}')


class AttendanceReportView(LoginRequiredMixin, TemplateView):
    template_name = 'attendance/report.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        section_id = self.request.GET.get('section_id')
        month = self.request.GET.get('month', timezone.now().month)
        year = self.request.GET.get('year', timezone.now().year)

        report_data = []
        if section_id:
            section = Section.objects.get(pk=section_id)
            students = Student.objects.filter(current_section=section, is_active=True)
            records = StudentAttendance.objects.filter(
                section=section,
                date__month=month,
                date__year=year,
            )
            stats = records.values('student_id', 'status').annotate(cnt=Count('id'))
            for student in students:
                student_stats = {s['status']: s['cnt'] for s in stats if s['student_id'] == student.pk}
                total = sum(student_stats.values())
                present = student_stats.get('present', 0) + student_stats.get('late', 0)
                report_data.append({
                    'student': student,
                    'present': present,
                    'absent': student_stats.get('absent', 0),
                    'late': student_stats.get('late', 0),
                    'leave': student_stats.get('leave', 0),
                    'total': total,
                    'percentage': round(present / total * 100, 1) if total else 0,
                })

        ctx.update({
            'page_title': 'Attendance Report',
            'sections': Section.objects.select_related('school_class').order_by(
                'school_class__order', 'name'
            ),
            'selected_section_id': section_id,
            'report_data': report_data,
            'month': int(month),
            'year': int(year),
            'months': range(1, 13),
            'years': range(2022, timezone.now().year + 1),
        })
        return ctx


class DefaultersView(LoginRequiredMixin, TemplateView):
    template_name = 'attendance/defaulters.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        threshold = float(self.request.GET.get('threshold', 75))
        class_id = self.request.GET.get('class_id')

        students = Student.objects.filter(is_active=True)
        if class_id:
            students = students.filter(current_class_id=class_id)

        defaulters = []
        for student in students.select_related('current_class', 'current_section'):
            records = StudentAttendance.objects.filter(student=student)
            total = records.count()
            present = records.filter(Q(status='present') | Q(status='late')).count()
            pct = round(present / total * 100, 1) if total else 0
            if pct < threshold:
                defaulters.append({
                    'student': student,
                    'present': present,
                    'total': total,
                    'percentage': pct,
                    'shortfall': round(threshold - pct, 1),
                })

        defaulters.sort(key=lambda x: x['percentage'])

        ctx.update({
            'page_title': 'Attendance Defaulters',
            'defaulters': defaulters,
            'threshold': threshold,
            'classes': Class.objects.all().order_by('order'),
            'selected_class': class_id,
            'total_defaulters': len(defaulters),
        })
        return ctx
