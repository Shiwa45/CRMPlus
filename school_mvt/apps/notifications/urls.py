from django.urls import path
from . import views
app_name = "notifications"
urlpatterns = [
    path("", views.NotificationsView.as_view(), name="list"),
    path("sms/", views.SMSLogView.as_view(), name="sms_log"),
]
