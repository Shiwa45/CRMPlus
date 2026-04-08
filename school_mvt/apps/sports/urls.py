from django.urls import path
from . import views
app_name = "sports"
urlpatterns = [
    path("", views.SportsDashboardView.as_view(), name="dashboard"),
    path("achievements/", views.AchievementListView.as_view(), name="achievements"),
]
