"""Tenants app — school onboarding & management views (public schema)."""
from django.views.generic import ListView, CreateView, UpdateView, TemplateView, DetailView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.shortcuts import redirect
from .models import School, Domain, SubscriptionPlan


class SchoolListView(LoginRequiredMixin, ListView):
    model = School
    template_name = 'tenants/school_list.html'
    context_object_name = 'schools'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Schools — Platform Admin',
            'total': School.objects.count(),
            'active': School.objects.filter(is_active=True).count(),
            'trial': School.objects.filter(is_trial=True).count(),
        })
        return ctx


class SchoolCreateView(LoginRequiredMixin, CreateView):
    model = School
    template_name = 'tenants/school_form.html'
    fields = [
        'name', 'short_name', 'school_code', 'board', 'affiliation_number',
        'address', 'city', 'state', 'pincode', 'phone', 'email', 'website',
        'logo', 'subscription_plan', 'max_students', 'max_staff',
        'current_academic_year',
    ]
    success_url = reverse_lazy('tenants:school_list')

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = 'Onboard New School'
        return ctx

    def form_valid(self, form):
        school = form.save(commit=False)
        # schema_name auto-set from school_code
        school.schema_name = form.cleaned_data['school_code'].lower().replace(' ', '_')
        school.save()
        # Create default domain
        Domain.objects.create(
            domain=f"{school.schema_name}.localhost",
            tenant=school,
            is_primary=True,
        )
        messages.success(self.request, f'School "{school.name}" onboarded. Schema: {school.schema_name}')
        return redirect(self.success_url)


class SchoolDetailView(LoginRequiredMixin, DetailView):
    model = School
    template_name = 'tenants/school_detail.html'
    context_object_name = 'school'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = self.object.name
        ctx['domains'] = self.object.domains.all()
        return ctx


class SubscriptionPlansView(LoginRequiredMixin, ListView):
    model = SubscriptionPlan
    template_name = 'tenants/plans.html'
    context_object_name = 'plans'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = 'Subscription Plans'
        return ctx


class PlatformDashboardView(LoginRequiredMixin, TemplateView):
    """Super-admin platform-level dashboard (public schema)."""
    template_name = 'tenants/platform_dashboard.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Platform Dashboard',
            'total_schools': School.objects.count(),
            'active_schools': School.objects.filter(is_active=True).count(),
            'trial_schools': School.objects.filter(is_trial=True).count(),
            'recent_schools': School.objects.order_by('-created_at')[:10],
            'plan_breakdown': School.objects.values('subscription_plan').order_by('subscription_plan'),
        })
        return ctx
