from django.views.generic import ListView, TemplateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.shortcuts import redirect
from django.utils import timezone
from .models import Visitor


class VisitorListView(LoginRequiredMixin, ListView):
    model = Visitor
    template_name = "visitor/list.html"
    context_object_name = "visitors"
    paginate_by = 25

    def get_queryset(self):
        qs = Visitor.objects.all()
        date = self.request.GET.get("date", timezone.now().date().isoformat())
        if date:
            qs = qs.filter(check_in_time__date=date)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        today = timezone.now().date()
        ctx.update({
            "page_title": "Visitor Management",
            "today_count": Visitor.objects.filter(check_in_time__date=today).count(),
            "inside_count": Visitor.objects.filter(
                check_in_time__date=today, check_out_time__isnull=True
            ).count(),
            "purpose_choices": Visitor.PURPOSE_CHOICES,
            "selected_date": self.request.GET.get("date", today.isoformat()),
        })
        return ctx

    def post(self, request):
        action = request.POST.get("action")
        if action == "checkin":
            Visitor.objects.create(
                visitor_name=request.POST.get("visitor_name"),
                phone=request.POST.get("phone"),
                purpose=request.POST.get("purpose"),
                whom_to_meet=request.POST.get("whom_to_meet"),
                department=request.POST.get("department", ""),
                id_proof_type=request.POST.get("id_proof_type", ""),
                id_proof_number=request.POST.get("id_proof_number", ""),
                approved_by=request.user,
            )
            messages.success(request, "Visitor checked in successfully.")
        elif action == "checkout":
            v_id = request.POST.get("visitor_id")
            Visitor.objects.filter(pk=v_id).update(check_out_time=timezone.now())
            messages.success(request, "Visitor checked out.")
        return redirect("visitor:list")
