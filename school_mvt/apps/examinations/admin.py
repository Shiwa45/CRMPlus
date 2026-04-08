from django.contrib import admin
from .models import Exam, ExamSchedule, StudentMark

@admin.register(Exam)
class ExamAdmin(admin.ModelAdmin):
    list_display = ["name", "exam_type", "start_date", "status"]

admin.site.register(ExamSchedule)
admin.site.register(StudentMark)
