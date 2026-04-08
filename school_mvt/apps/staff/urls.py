from django.urls import path
from . import views

app_name = 'staff'

urlpatterns = [
    path('', views.StaffListView.as_view(), name='list'),
    path('<int:pk>/', views.StaffDetailView.as_view(), name='detail'),
    path('leave/', views.LeaveRequestView.as_view(), name='leave'),
    path('payroll/', views.PayrollView.as_view(), name='payroll'),
]
