from django.contrib import admin
from .models import Notice, Announcement, Message

@admin.register(Notice)
class NoticeAdmin(admin.ModelAdmin):
    list_display = ["title", "audience", "is_pinned", "is_active", "created_at"]

admin.site.register(Announcement)
admin.site.register(Message)
