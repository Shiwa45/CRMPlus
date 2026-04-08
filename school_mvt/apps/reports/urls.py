from django.urls import path
from . import views
app_name = "reports"
urlpatterns = [
    path("", views.ReportsDashboardView.as_view(), name="dashboard"),
    path("academic/", views.AcademicReportView.as_view(), name="academic"),
    path("fee/", views.FeeReportView.as_view(), name="fee"),
    path("attendance/", views.AttendanceReportSummaryView.as_view(), name="attendance_report"),
    path("staff/", views.StaffReportView.as_view(), name="staff_report"),
]
