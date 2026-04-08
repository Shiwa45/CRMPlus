from django.views.generic import ListView, CreateView, UpdateView, TemplateView, DeleteView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.shortcuts import get_object_or_404
from .models import Class, Section, Subject, Timetable, Period, Homework, AcademicYear


class ClassListView(LoginRequiredMixin, ListView):
    model = Class
    template_name = 'academics/classes.html'
    context_object_name = 'classes'

    def get_queryset(self):
        return Class.objects.prefetch_related('sections', 'subjects').order_by('order')

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Classes & Sections',
            'sections': Section.objects.select_related('school_class', 'class_teacher').all(),
            'total_classes': Class.objects.count(),
        })
        return ctx


class SubjectListView(LoginRequiredMixin, ListView):
    model = Subject
    template_name = 'academics/subjects.html'
    context_object_name = 'subjects'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Subjects',
            'classes': Class.objects.all().order_by('order'),
            'selected_class': self.request.GET.get('class_id', ''),
        })
        return ctx

    def get_queryset(self):
        qs = Subject.objects.prefetch_related('classes', 'teachers')
        class_id = self.request.GET.get('class_id')
        if class_id:
            qs = qs.filter(classes__id=class_id)
        return qs


class TimetableView(LoginRequiredMixin, TemplateView):
    template_name = 'academics/timetable.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        section_id = self.request.GET.get('section_id')
        selected_section = None
        timetable_grid = {}

        if section_id:
            selected_section = get_object_or_404(Section, pk=section_id)
            academic_year = AcademicYear.objects.filter(is_current=True).first()
            entries = Timetable.objects.filter(
                section=selected_section,
                academic_year=academic_year,
            ).select_related('subject', 'teacher', 'period') if academic_year else []

            days = [1, 2, 3, 4, 5, 6]
            periods = Period.objects.filter(is_break=False).order_by('order')

            for day in days:
                timetable_grid[day] = {}
                for period in periods:
                    entry = next(
                        (e for e in entries if e.day == day and e.period_id == period.id),
                        None
                    )
                    timetable_grid[day][period.id] = entry

        ctx.update({
            'page_title': 'Timetable',
            'sections': Section.objects.select_related('school_class').order_by(
                'school_class__order', 'name'
            ),
            'selected_section': selected_section,
            'timetable_grid': timetable_grid,
            'periods': Period.objects.filter(is_break=False).order_by('order'),
            'days': Timetable.DAY_CHOICES,
        })
        return ctx


class HomeworkListView(LoginRequiredMixin, ListView):
    model = Homework
    template_name = 'academics/homework.html'
    context_object_name = 'homeworks'
    paginate_by = 15

    def get_queryset(self):
        qs = Homework.objects.select_related('subject', 'section', 'assigned_by')
        section_id = self.request.GET.get('section_id')
        if section_id:
            qs = qs.filter(section_id=section_id)
        if self.request.user.is_teacher:
            qs = qs.filter(assigned_by=self.request.user)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Homework & Assignments',
            'sections': Section.objects.select_related('school_class').order_by(
                'school_class__order', 'name'
            ),
        })
        return ctx
