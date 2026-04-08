from django.views.generic import ListView, TemplateView, CreateView, UpdateView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib import messages
from django.urls import reverse_lazy
from django.db.models import Q
from django.shortcuts import redirect
from .models import Book, BookIssue, LibraryMember, BookCategory


class BookListView(LoginRequiredMixin, ListView):
    model = Book
    template_name = "library/book_list.html"
    context_object_name = "books"
    paginate_by = 20

    def get_queryset(self):
        qs = Book.objects.filter(is_active=True).select_related("category")
        q = self.request.GET.get("q", "")
        cat = self.request.GET.get("category", "")
        avail = self.request.GET.get("available", "")
        if q:
            qs = qs.filter(Q(title__icontains=q)|Q(author__icontains=q)|Q(isbn__icontains=q))
        if cat:
            qs = qs.filter(category_id=cat)
        if avail:
            qs = qs.filter(available_copies__gt=0)
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Library — Books",
            "categories": BookCategory.objects.all(),
            "total_books": Book.objects.filter(is_active=True).count(),
            "total_issued": BookIssue.objects.filter(status="issued").count(),
            "overdue": BookIssue.objects.filter(status="overdue").count(),
            "q": self.request.GET.get("q", ""),
        })
        return ctx


class BookIssueView(LoginRequiredMixin, TemplateView):
    template_name = "library/issue_return.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx.update({
            "page_title": "Issue / Return Book",
            "recent_issues": BookIssue.objects.select_related(
                "book", "member"
            ).order_by("-created_at")[:20],
            "books": Book.objects.filter(is_active=True, available_copies__gt=0),
            "members": LibraryMember.objects.filter(is_active=True).select_related(
                "student", "staff"
            ),
            "overdue_list": BookIssue.objects.filter(status__in=["issued","overdue"]).select_related(
                "book", "member"
            ).order_by("due_date")[:10],
        })
        return ctx

    def post(self, request):
        action = request.POST.get("action")
        if action == "issue":
            book_id = request.POST.get("book_id")
            member_id = request.POST.get("member_id")
            due_date = request.POST.get("due_date")
            book = Book.objects.get(pk=book_id)
            if book.available_copies <= 0:
                messages.error(request, "No copies available.")
            else:
                BookIssue.objects.create(
                    book=book, member_id=member_id, due_date=due_date,
                    issued_by=request.user
                )
                book.available_copies -= 1
                book.save()
                messages.success(request, f"Book issued: {book.title}")
        elif action == "return":
            issue_id = request.POST.get("issue_id")
            issue = BookIssue.objects.get(pk=issue_id)
            from django.utils import timezone
            issue.return_date = timezone.now().date()
            issue.status = "returned"
            issue.calculate_fine()
            issue.save()
            issue.book.available_copies += 1
            issue.book.save()
            messages.success(request, f"Book returned. Fine: ₹{issue.fine_amount}")
        return redirect("library:issue_return")


class LibraryReportView(LoginRequiredMixin, TemplateView):
    template_name = "library/report.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        from django.db.models import Count
        ctx.update({
            "page_title": "Library Reports",
            "popular_books": Book.objects.annotate(
                issue_count=Count("issues")
            ).order_by("-issue_count")[:10],
            "overdue": BookIssue.objects.filter(
                status="overdue"
            ).select_related("book", "member").order_by("due_date"),
            "category_stats": BookCategory.objects.annotate(
                book_count=Count("book")
            ),
        })
        return ctx
