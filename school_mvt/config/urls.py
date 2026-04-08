from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.shortcuts import redirect

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', lambda request: redirect('dashboard:home'), name='root'),
    path('auth/', include('apps.authentication.urls', namespace='auth')),
    path('dashboard/', include('apps.dashboard.urls', namespace='dashboard')),
    path('students/', include('apps.students.urls', namespace='students')),
    path('academics/', include('apps.academics.urls', namespace='academics')),
    path('attendance/', include('apps.attendance.urls', namespace='attendance')),
    path('examinations/', include('apps.examinations.urls', namespace='examinations')),
    path('fees/', include('apps.fees.urls', namespace='fees')),
    path('staff/', include('apps.staff.urls', namespace='staff')),
    path('communication/', include('apps.communication.urls', namespace='communication')),
    path('library/', include('apps.library.urls', namespace='library')),
    path('transport/', include('apps.transport.urls', namespace='transport')),
    path('hostel/', include('apps.hostel.urls', namespace='hostel')),
    path('inventory/', include('apps.inventory.urls', namespace='inventory')),
    path('health/', include('apps.health.urls', namespace='health')),
    path('sports/', include('apps.sports.urls', namespace='sports')),
    path('visitors/', include('apps.visitor.urls', namespace='visitor')),
    path('alumni/', include('apps.alumni.urls', namespace='alumni')),
    path('discipline/', include('apps.discipline.urls', namespace='discipline')),
    path('helpdesk/', include('apps.helpdesk.urls', namespace='helpdesk')),
    path('reports/', include('apps.reports.urls', namespace='reports')),
    path('notifications/', include('apps.notifications.urls', namespace='notifications')),
    path('settings/', include('apps.settings_app.urls', namespace='settings_app')),
    path('platform/', include('apps.tenants.urls', namespace='tenants')),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT) \
  + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
