from django.urls import path
from . import views

app_name = 'communication'

urlpatterns = [
    path('notices/', views.NoticesView.as_view(), name='notices'),
    path('notices/add/', views.NoticeCreateView.as_view(), name='notice_add'),
    path('announcements/', views.AnnouncementsView.as_view(), name='announcements'),
    path('messages/', views.MessagesView.as_view(), name='messages'),
]
