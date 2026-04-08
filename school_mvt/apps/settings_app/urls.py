from django.urls import path
from . import views
app_name = "settings_app"
urlpatterns = [
    path("", views.SettingsDashboardView.as_view(), name="dashboard"),
    path("tenant/", views.TenantSettingsView.as_view(), name="tenant"),
]
