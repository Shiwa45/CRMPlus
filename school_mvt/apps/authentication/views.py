"""
Authentication Views - MVT (no DRF/API)
"""
from django.shortcuts import render, redirect
from django.contrib.auth import login, logout, authenticate, update_session_auth_hash
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.views.generic import View, UpdateView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from .models import User
from .forms import LoginForm, UserProfileForm, ChangePasswordForm


class LoginView(View):
    template_name = 'authentication/login.html'

    def get(self, request):
        if request.user.is_authenticated:
            return redirect('dashboard:home')
        form = LoginForm()
        return render(request, self.template_name, {'form': form})

    def post(self, request):
        form = LoginForm(data=request.POST)
        if form.is_valid():
            username = form.cleaned_data['username']
            password = form.cleaned_data['password']
            user = authenticate(request, username=username, password=password)
            if user:
                login(request, user)
                # Save login IP
                ip = request.META.get('REMOTE_ADDR')
                User.objects.filter(pk=user.pk).update(last_login_ip=ip)
                messages.success(request, f'Welcome back, {user.first_name or user.username}!')
                next_url = request.GET.get('next', 'dashboard:home')
                return redirect(next_url)
            else:
                messages.error(request, 'Invalid username or password.')
        return render(request, self.template_name, {'form': form})


class LogoutView(View):
    def get(self, request):
        logout(request)
        messages.info(request, 'You have been logged out.')
        return redirect('auth:login')


class ProfileView(LoginRequiredMixin, TemplateView):
    template_name = 'authentication/profile.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = 'My Profile'
        ctx['form'] = UserProfileForm(instance=self.request.user)
        return ctx

    def post(self, request):
        form = UserProfileForm(request.POST, request.FILES, instance=request.user)
        if form.is_valid():
            form.save()
            messages.success(request, 'Profile updated successfully.')
            return redirect('auth:profile')
        return render(request, self.template_name, {'form': form, 'page_title': 'My Profile'})


class ChangePasswordView(LoginRequiredMixin, View):
    template_name = 'authentication/change_password.html'

    def get(self, request):
        form = ChangePasswordForm(request.user)
        return render(request, self.template_name, {'form': form, 'page_title': 'Change Password'})

    def post(self, request):
        form = ChangePasswordForm(request.user, request.POST)
        if form.is_valid():
            user = form.save()
            update_session_auth_hash(request, user)
            messages.success(request, 'Password changed successfully.')
            return redirect('auth:profile')
        return render(request, self.template_name, {'form': form, 'page_title': 'Change Password'})


class UserListView(LoginRequiredMixin, TemplateView):
    template_name = 'authentication/users.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        role_filter = self.request.GET.get('role', '')
        search = self.request.GET.get('search', '')
        users = User.objects.all().order_by('role', 'first_name')
        if role_filter:
            users = users.filter(role=role_filter)
        if search:
            users = users.filter(
                first_name__icontains=search
            ) | users.filter(
                last_name__icontains=search
            ) | users.filter(
                username__icontains=search
            )
        ctx.update({
            'users': users,
            'role_choices': User.ROLE_CHOICES,
            'selected_role': role_filter,
            'search': search,
            'page_title': 'User Management',
            'total_users': users.count(),
        })
        return ctx
