# views.py
from django.views.generic import ListView, TemplateView, DetailView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.db.models import Avg, Count
from .models import Exam, ExamSchedule, StudentMark
from apps.academics.models import Class, Section, Subject
from apps.students.models import Student


class ExamListView(LoginRequiredMixin, ListView):
    model = Exam
    template_name = 'examinations/list.html'
    context_object_name = 'exams'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Examinations',
            'exam_types': Exam.EXAM_TYPE_CHOICES,
            'upcoming': Exam.objects.filter(status='scheduled').count(),
            'ongoing': Exam.objects.filter(status='ongoing').count(),
        })
        return ctx


class MarksEntryView(LoginRequiredMixin, TemplateView):
    template_name = 'examinations/marks_entry.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        exam_id = self.request.GET.get('exam_id')
        class_id = self.request.GET.get('class_id')
        subject_id = self.request.GET.get('subject_id')
        students = []
        existing_marks = {}

        if exam_id and class_id and subject_id:
            school_class = Class.objects.get(pk=class_id)
            students = Student.objects.filter(
                current_class=school_class, is_active=True
            ).order_by('roll_number', 'first_name')
            marks = StudentMark.objects.filter(
                exam_id=exam_id, subject_id=subject_id,
                student__current_class_id=class_id
            )
            existing_marks = {m.student_id: m for m in marks}

        ctx.update({
            'page_title': 'Marks Entry',
            'exams': Exam.objects.filter(status__in=['ongoing', 'scheduled']),
            'classes': Class.objects.all().order_by('order'),
            'subjects': Subject.objects.all() if class_id else [],
            'students': students,
            'existing_marks': existing_marks,
            'selected_exam': exam_id,
            'selected_class': class_id,
            'selected_subject': subject_id,
        })
        return ctx

    def post(self, request):
        from django.shortcuts import redirect
        exam_id = request.POST.get('exam_id')
        subject_id = request.POST.get('subject_id')
        student_ids = request.POST.getlist('student_ids')
        saved = 0
        for sid in student_ids:
            theory = request.POST.get(f'theory_{sid}') or None
            practical = request.POST.get(f'practical_{sid}') or None
            is_absent = bool(request.POST.get(f'absent_{sid}'))
            StudentMark.objects.update_or_create(
                student_id=sid, exam_id=exam_id, subject_id=subject_id,
                defaults={
                    'theory_marks': theory,
                    'practical_marks': practical,
                    'is_absent': is_absent,
                    'entered_by': request.user,
                }
            )
            saved += 1
        from django.contrib import messages
        messages.success(request, f'Marks saved for {saved} students.')
        return redirect(f'/examinations/marks/?exam_id={exam_id}&subject_id={subject_id}')


class ReportCardsView(LoginRequiredMixin, TemplateView):
    template_name = 'examinations/report_cards.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        exam_id = self.request.GET.get('exam_id')
        section_id = self.request.GET.get('section_id')
        student_id = self.request.GET.get('student_id')

        report_data = None
        if exam_id and student_id:
            student = Student.objects.get(pk=student_id)
            marks = StudentMark.objects.filter(
                exam_id=exam_id, student=student
            ).select_related('subject')
            total_obtained = sum(float(m.total_marks or 0) for m in marks)
            total_max = sum(m.subject.max_theory_marks + m.subject.max_practical_marks for m in marks)
            report_data = {
                'student': student,
                'marks': marks,
                'total_obtained': total_obtained,
                'total_max': total_max,
                'percentage': round(total_obtained / total_max * 100, 2) if total_max else 0,
            }

        ctx.update({
            'page_title': 'Report Cards',
            'exams': Exam.objects.all(),
            'sections': Section.objects.select_related('school_class').order_by(
                'school_class__order', 'name'
            ),
            'selected_exam': exam_id,
            'selected_section': section_id,
            'report_data': report_data,
            'students': Student.objects.filter(
                current_section_id=section_id, is_active=True
            ).order_by('roll_number') if section_id else [],
        })
        return ctx


class ResultsView(LoginRequiredMixin, TemplateView):
    template_name = 'examinations/results.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        exam_id = self.request.GET.get('exam_id')
        class_id = self.request.GET.get('class_id')

        results = []
        if exam_id and class_id:
            students = Student.objects.filter(
                current_class_id=class_id, is_active=True
            ).order_by('roll_number')
            for student in students:
                marks = StudentMark.objects.filter(student=student, exam_id=exam_id)
                total = sum(float(m.total_marks or 0) for m in marks)
                subjects_count = marks.count()
                results.append({
                    'student': student,
                    'total': total,
                    'subjects': subjects_count,
                    'percentage': round(total / (subjects_count * 100) * 100, 1) if subjects_count else 0,
                    'passed': all(float(m.total_marks or 0) >= m.subject.passing_marks for m in marks),
                })
            results.sort(key=lambda x: x['total'], reverse=True)
            for i, r in enumerate(results):
                r['rank'] = i + 1

        ctx.update({
            'page_title': 'Exam Results',
            'exams': Exam.objects.all(),
            'classes': Class.objects.all().order_by('order'),
            'results': results,
            'selected_exam': exam_id,
            'selected_class': class_id,
        })
        return ctx
