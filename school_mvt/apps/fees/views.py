# views.py
from django.views.generic import TemplateView, ListView, CreateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.db.models import Sum, Count, Q
from django.utils import timezone
from django.urls import reverse_lazy
from .models import FeePayment, FeeStructure, FeeType, Concession
from apps.students.models import Student
from apps.academics.models import Class


class FeeListView(LoginRequiredMixin, TemplateView):
    template_name = 'fees/list.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        today = timezone.now().date()
        month = today.month
        year = today.year

        today_collection = FeePayment.objects.filter(payment_date=today).aggregate(
            total=Sum('amount_paid')
        )['total'] or 0
        month_collection = FeePayment.objects.filter(
            payment_date__month=month, payment_date__year=year
        ).aggregate(total=Sum('amount_paid'))['total'] or 0
        recent_payments = FeePayment.objects.select_related(
            'student', 'fee_type', 'collected_by'
        ).order_by('-payment_date', '-created_at')[:10]

        ctx.update({
            'page_title': 'Fee Management',
            'today_collection': today_collection,
            'month_collection': month_collection,
            'recent_payments': recent_payments,
        })
        return ctx


class FeeCollectView(LoginRequiredMixin, TemplateView):
    template_name = 'fees/collect.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        student_id = self.request.GET.get('student_id')
        student = None
        due_amounts = []

        if student_id:
            student = Student.objects.filter(pk=student_id).select_related(
                'current_class'
            ).first()
            if student and student.current_class:
                structures = FeeStructure.objects.filter(
                    school_class=student.current_class
                ).select_related('fee_type')
                for s in structures:
                    paid = FeePayment.objects.filter(
                        student=student,
                        fee_type=s.fee_type,
                        academic_year=s.academic_year,
                        status__in=['paid', 'partial'],
                    ).aggregate(total=Sum('amount_paid'))['total'] or 0
                    due = float(s.amount) - float(paid)
                    due_amounts.append({
                        'fee_type': s.fee_type,
                        'due_amount': max(due, 0),
                        'total_amount': s.amount,
                        'paid': paid,
                        'overdue': s.due_date and s.due_date < timezone.now().date() and due > 0,
                    })

        ctx.update({
            'page_title': 'Collect Fee',
            'student': student,
            'due_amounts': due_amounts,
            'students': Student.objects.filter(is_active=True).order_by('first_name'),
            'payment_modes': FeePayment.PAYMENT_MODE_CHOICES,
            'fee_types': FeeType.objects.filter(is_active=True),
        })
        return ctx

    def post(self, request):
        student_id = request.POST.get('student_id')
        fee_type_id = request.POST.get('fee_type_id')
        amount_paid = request.POST.get('amount_paid')
        payment_mode = request.POST.get('payment_mode', 'cash')
        transaction_id = request.POST.get('transaction_id', '')
        remarks = request.POST.get('remarks', '')

        import random, string
        receipt_no = 'RCP' + ''.join(random.choices(string.digits, k=8))

        payment = FeePayment.objects.create(
            receipt_number=receipt_no,
            student_id=student_id,
            fee_type_id=fee_type_id,
            academic_year='2024-25',
            amount_due=amount_paid,
            amount_paid=amount_paid,
            payment_date=timezone.now().date(),
            payment_mode=payment_mode,
            transaction_id=transaction_id,
            status='paid',
            collected_by=request.user,
            remarks=remarks,
        )
        messages.success(request, f'Payment collected. Receipt: {receipt_no}')
        return FeeCollectView.as_view()(request)


class FeeStructureView(LoginRequiredMixin, ListView):
    model = FeeStructure
    template_name = 'fees/structure.html'
    context_object_name = 'structures'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Fee Structure',
            'classes': Class.objects.all().order_by('order'),
            'fee_types': FeeType.objects.filter(is_active=True),
        })
        return ctx


class FeeDefaultersView(LoginRequiredMixin, TemplateView):
    template_name = 'fees/defaulters.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        class_id = self.request.GET.get('class_id')
        academic_year = '2024-25'

        students = Student.objects.filter(is_active=True)
        if class_id:
            students = students.filter(current_class_id=class_id)

        defaulters = []
        for student in students.select_related('current_class', 'current_section')[:100]:
            total_due = FeeStructure.objects.filter(
                school_class=student.current_class, academic_year=academic_year
            ).aggregate(total=Sum('amount'))['total'] or 0
            total_paid = FeePayment.objects.filter(
                student=student, academic_year=academic_year, status='paid'
            ).aggregate(total=Sum('amount_paid'))['total'] or 0
            outstanding = float(total_due) - float(total_paid)
            if outstanding > 0:
                defaulters.append({
                    'student': student,
                    'total_due': total_due,
                    'total_paid': total_paid,
                    'outstanding': outstanding,
                })

        defaulters.sort(key=lambda x: x['outstanding'], reverse=True)

        ctx.update({
            'page_title': 'Fee Defaulters',
            'defaulters': defaulters,
            'classes': Class.objects.all().order_by('order'),
            'selected_class': class_id,
            'total_outstanding': sum(d['outstanding'] for d in defaulters),
        })
        return ctx


class FeeReportsView(LoginRequiredMixin, TemplateView):
    template_name = 'fees/reports.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        today = timezone.now().date()

        # Monthly collection for last 12 months
        import datetime
        monthly = []
        for i in range(11, -1, -1):
            d = today.replace(day=1) - datetime.timedelta(days=30 * i)
            total = FeePayment.objects.filter(
                payment_date__year=d.year, payment_date__month=d.month
            ).aggregate(t=Sum('amount_paid'))['t'] or 0
            monthly.append({'month': d.strftime('%b %Y'), 'total': float(total)})

        # By payment mode
        by_mode = FeePayment.objects.values('payment_mode').annotate(
            total=Sum('amount_paid'), count=Count('id')
        ).order_by('-total')

        # By fee type
        by_type = FeePayment.objects.values('fee_type__name').annotate(
            total=Sum('amount_paid'), count=Count('id')
        ).order_by('-total')

        ctx.update({
            'page_title': 'Fee Reports',
            'monthly_data': monthly,
            'by_mode': by_mode,
            'by_type': by_type,
            'total_collected': FeePayment.objects.aggregate(t=Sum('amount_paid'))['t'] or 0,
        })
        return ctx
