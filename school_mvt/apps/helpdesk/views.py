from django.views.generic import ListView, DetailView, CreateView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.shortcuts import redirect, get_object_or_404
from django.utils import timezone
import random, string
from .models import Ticket, TicketReply, TicketCategory


class TicketListView(LoginRequiredMixin, ListView):
    model = Ticket
    template_name = "helpdesk/tickets.html"
    context_object_name = "tickets"
    paginate_by = 20

    def get_queryset(self):
        qs = Ticket.objects.select_related("raised_by", "assigned_to", "category")
        if not self.request.user.is_admin:
            qs = qs.filter(raised_by=self.request.user)
        status = self.request.GET.get("status", "")
        priority = self.request.GET.get("priority", "")
        if status:
            qs = qs.filter(status=status)
        if priority:
            qs = qs.filter(priority=priority)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Help Desk",
            "open_tickets": Ticket.objects.filter(status__in=["open","in_progress"]).count(),
            "status_choices": Ticket.STATUS_CHOICES,
            "priority_choices": Ticket.PRIORITY_CHOICES,
            "categories": TicketCategory.objects.all(),
        })
        return ctx

    def post(self, request):
        ticket_no = "TKT" + "".join(random.choices(string.digits, k=7))
        Ticket.objects.create(
            ticket_number=ticket_no,
            title=request.POST.get("title"),
            description=request.POST.get("description"),
            category_id=request.POST.get("category_id") or None,
            priority=request.POST.get("priority", "medium"),
            raised_by=request.user,
        )
        messages.success(request, f"Ticket #{ticket_no} raised successfully.")
        return redirect("helpdesk:tickets")


class TicketDetailView(LoginRequiredMixin, DetailView):
    model = Ticket
    template_name = "helpdesk/ticket_detail.html"
    context_object_name = "ticket"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": f"Ticket #{self.object.ticket_number}",
            "replies": self.object.replies.select_related("replied_by"),
            "status_choices": Ticket.STATUS_CHOICES,
        })
        return ctx

    def post(self, request, pk):
        ticket = get_object_or_404(Ticket, pk=pk)
        action = request.POST.get("action")
        if action == "reply":
            TicketReply.objects.create(
                ticket=ticket,
                replied_by=request.user,
                message=request.POST.get("message"),
                is_internal=bool(request.POST.get("is_internal")),
            )
            messages.success(request, "Reply added.")
        elif action == "update_status":
            new_status = request.POST.get("status")
            ticket.status = new_status
            if new_status == "resolved":
                ticket.resolved_at = timezone.now()
                ticket.resolution_note = request.POST.get("resolution_note", "")
            ticket.save()
            messages.success(request, f"Ticket status updated to {new_status}.")
        return redirect("helpdesk:ticket_detail", pk=pk)
