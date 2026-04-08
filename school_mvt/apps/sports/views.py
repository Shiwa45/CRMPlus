from django.views.generic import ListView, TemplateView, CreateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from .models import Sport, Activity, StudentAchievement, HouseTeam


class SportsDashboardView(LoginRequiredMixin, TemplateView):
    template_name = "sports/dashboard.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Sports & Activities",
            "sports": Sport.objects.filter(is_active=True),
            "activities": Activity.objects.filter(is_active=True),
            "house_teams": HouseTeam.objects.filter(is_active=True),
            "recent_achievements": StudentAchievement.objects.select_related(
                "student"
            ).order_by("-date")[:10],
            "total_achievements": StudentAchievement.objects.count(),
        })
        return ctx


class AchievementListView(LoginRequiredMixin, ListView):
    model = StudentAchievement
    template_name = "sports/achievements.html"
    context_object_name = "achievements"
    paginate_by = 20

    def get_queryset(self):
        qs = StudentAchievement.objects.select_related("student")
        level = self.request.GET.get("level", "")
        atype = self.request.GET.get("type", "")
        if level:
            qs = qs.filter(level=level)
        if atype:
            qs = qs.filter(achievement_type=atype)
        return qs.order_by("-date")

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Student Achievements",
            "level_choices": StudentAchievement.LEVEL_CHOICES,
            "type_choices": StudentAchievement._meta.get_field("achievement_type").choices,
        })
        return ctx
