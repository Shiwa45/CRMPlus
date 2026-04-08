from django.urls import path
from . import views

app_name = 'fees'

urlpatterns = [
    path('', views.FeeListView.as_view(), name='list'),
    path('collect/', views.FeeCollectView.as_view(), name='collect'),
    path('structure/', views.FeeStructureView.as_view(), name='structure'),
    path('defaulters/', views.FeeDefaultersView.as_view(), name='defaulters'),
    path('reports/', views.FeeReportsView.as_view(), name='reports'),
]
