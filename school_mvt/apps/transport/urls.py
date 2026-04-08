from django.urls import path
from . import views
app_name = "transport"
urlpatterns = [
    path("", views.TransportDashboardView.as_view(), name="dashboard"),
    path("routes/", views.RouteListView.as_view(), name="routes"),
    path("vehicles/", views.VehicleListView.as_view(), name="vehicles"),
    path("allocation/", views.StudentTransportView.as_view(), name="allocation"),
]
