from django.urls import path
from . import views

app_name = 'examinations'

urlpatterns = [
    path('', views.ExamListView.as_view(), name='list'),
    path('marks/', views.MarksEntryView.as_view(), name='marks_entry'),
    path('report-cards/', views.ReportCardsView.as_view(), name='report_cards'),
    path('results/', views.ResultsView.as_view(), name='results'),
]
