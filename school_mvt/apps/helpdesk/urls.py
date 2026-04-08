from django.urls import path
from . import views
app_name = "helpdesk"
urlpatterns = [
    path("", views.TicketListView.as_view(), name="tickets"),
    path("<int:pk>/", views.TicketDetailView.as_view(), name="ticket_detail"),
]
