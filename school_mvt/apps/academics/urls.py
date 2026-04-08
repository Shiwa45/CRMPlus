from django.urls import path
from . import views

app_name = 'academics'

urlpatterns = [
    path('classes/', views.ClassListView.as_view(), name='classes'),
    path('subjects/', views.SubjectListView.as_view(), name='subjects'),
    path('timetable/', views.TimetableView.as_view(), name='timetable'),
    path('homework/', views.HomeworkListView.as_view(), name='homework'),
]
