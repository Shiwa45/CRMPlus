from django.urls import path
from . import views
app_name = "library"
urlpatterns = [
    path("", views.BookListView.as_view(), name="book_list"),
    path("issue-return/", views.BookIssueView.as_view(), name="issue_return"),
    path("report/", views.LibraryReportView.as_view(), name="report"),
]
