from django.views.generic import ListView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.shortcuts import redirect
from django.utils import timezone
from .models import Notification, SMSLog, EmailLog


class NotificationsView(LoginRequiredMixin, ListView):
    model = Notification
    template_name = "notifications/list.html"
    context_object_name = "notifications"
    paginate_by = 20

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user).order_by("-created_at")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Notifications",
            "unread_count": Notification.objects.filter(
                recipient=self.request.user, is_read=False
            ).count(),
        })
        return ctx

    def post(self, request):
        action = request.POST.get("action")
        if action == "mark_all_read":
            Notification.objects.filter(
                recipient=request.user, is_read=False
            ).update(is_read=True, read_at=timezone.now())
            messages.success(request, "All notifications marked as read.")
        return redirect("notifications:list")


class SMSLogView(LoginRequiredMixin, ListView):
    model = SMSLog
    template_name = "notifications/sms_log.html"
    context_object_name = "sms_logs"
    paginate_by = 25

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "SMS Log",
            "sent_today": SMSLog.objects.filter(
                created_at__date=timezone.now().date(), status="sent"
            ).count(),
            "failed_today": SMSLog.objects.filter(
                created_at__date=timezone.now().date(), status="failed"
            ).count(),
        })
        return ctx
