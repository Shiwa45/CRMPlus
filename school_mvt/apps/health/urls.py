from django.urls import path
from . import views
app_name = "health"
urlpatterns = [
    path("records/", views.HealthRecordListView.as_view(), name="records"),
    path("sick-room/", views.SickRoomView.as_view(), name="sick_room"),
]
