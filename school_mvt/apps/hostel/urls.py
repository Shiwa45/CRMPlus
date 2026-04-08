from django.urls import path
from . import views
app_name = "hostel"
urlpatterns = [
    path("", views.HostelDashboardView.as_view(), name="dashboard"),
    path("rooms/", views.RoomListView.as_view(), name="rooms"),
    path("allocations/", views.AllocationView.as_view(), name="allocations"),
]
