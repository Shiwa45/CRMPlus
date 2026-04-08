from django.urls import path
from . import views
app_name = "visitor"
urlpatterns = [
    path("", views.VisitorListView.as_view(), name="list"),
]
