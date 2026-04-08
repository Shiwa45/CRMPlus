from django.urls import path
from . import views
app_name = "alumni"
urlpatterns = [
    path("", views.AlumniListView.as_view(), name="list"),
]
