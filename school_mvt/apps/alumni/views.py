from django.views.generic import ListView, CreateView, DetailView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.db.models import Q
from .models import Alumni


class AlumniListView(LoginRequiredMixin, ListView):
    model = Alumni
    template_name = "alumni/list.html"
    context_object_name = "alumni_list"
    paginate_by = 20

    def get_queryset(self):
        qs = Alumni.objects.all()
        q = self.request.GET.get("q", "")
        year = self.request.GET.get("year", "")
        if q:
            qs = qs.filter(
                Q(first_name__icontains=q)|Q(last_name__icontains=q)|
                Q(company__icontains=q)|Q(occupation__icontains=q)
            )
        if year:
            qs = qs.filter(graduation_year=year)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from django.utils import timezone
        ctx.update({
            "page_title": "Alumni Directory",
            "years": Alumni.objects.values_list("graduation_year", flat=True).distinct().order_by("-graduation_year"),
            "total": Alumni.objects.count(),
            "q": self.request.GET.get("q", ""),
        })
        return ctx
