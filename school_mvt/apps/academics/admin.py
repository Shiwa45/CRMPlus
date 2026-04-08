from django.contrib import admin
from .models import Class, Section, Subject, Period, AcademicYear

admin.site.register(Class)
admin.site.register(Section)
admin.site.register(Subject)
admin.site.register(Period)
admin.site.register(AcademicYear)
