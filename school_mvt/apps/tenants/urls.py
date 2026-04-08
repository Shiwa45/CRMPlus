from django.urls import path
from . import views
app_name = "tenants"
urlpatterns = [
    path("", views.PlatformDashboardView.as_view(), name="platform_dashboard"),
    path("schools/", views.SchoolListView.as_view(), name="school_list"),
    path("schools/add/", views.SchoolCreateView.as_view(), name="school_add"),
    path("schools/<int:pk>/", views.SchoolDetailView.as_view(), name="school_detail"),
    path("plans/", views.SubscriptionPlansView.as_view(), name="plans"),
]
