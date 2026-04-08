from django.urls import path
from . import views
app_name = "discipline"
urlpatterns = [
    path("incidents/", views.IncidentListView.as_view(), name="incidents"),
    path("counselling/", views.CounsellingView.as_view(), name="counselling"),
]
