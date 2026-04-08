# views.py
from django.views.generic import ListView, CreateView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.shortcuts import redirect
from .models import Notice, Announcement, Message
from apps.authentication.models import User


class NoticesView(LoginRequiredMixin, ListView):
    model = Notice
    template_name = 'communication/notices.html'
    context_object_name = 'notices'
    paginate_by = 15

    def get_queryset(self):
        return Notice.objects.filter(is_active=True).select_related('published_by')

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Notice Board',
            'pinned': Notice.objects.filter(is_active=True, is_pinned=True),
            'audience_choices': Notice.AUDIENCE_CHOICES,
        })
        return ctx


class NoticeCreateView(LoginRequiredMixin, CreateView):
    model = Notice
    template_name = 'communication/notice_form.html'
    fields = ['title', 'content', 'audience', 'attachment', 'is_pinned', 'expires_at']
    success_url = reverse_lazy('communication:notices')

    def form_valid(self, form):
        form.instance.published_by = self.request.user
        response = super().form_valid(form)
        messages.success(self.request, 'Notice published successfully.')
        return response

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['page_title'] = 'Post Notice'
        return ctx


class AnnouncementsView(LoginRequiredMixin, ListView):
    model = Announcement
    template_name = 'communication/announcements.html'
    context_object_name = 'announcements'
    paginate_by = 10

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            'page_title': 'Announcements',
            'priority_choices': Announcement.PRIORITY_CHOICES,
        })
        return ctx


class MessagesView(LoginRequiredMixin, TemplateView):
    template_name = 'communication/messages.html'

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        user = self.request.user
        inbox = Message.objects.filter(receiver=user).select_related('sender').order_by('-created_at')
        sent = Message.objects.filter(sender=user).select_related('receiver').order_by('-created_at')
        ctx.update({
            'page_title': 'Messages',
            'inbox': inbox[:20],
            'sent': sent[:20],
            'unread_count': inbox.filter(is_read=False).count(),
            'users': User.objects.filter(is_active=True).exclude(pk=user.pk),
        })
        return ctx

    def post(self, request):
        receiver_id = request.POST.get('receiver_id')
        subject = request.POST.get('subject', '')
        body = request.POST.get('body', '')
        Message.objects.create(
            sender=request.user,
            receiver_id=receiver_id,
            subject=subject,
            body=body,
        )
        messages.success(request, 'Message sent.')
        return redirect('communication:messages')
