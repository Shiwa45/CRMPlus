from django.db import models
from django.conf import settings
from django.utils import timezone


class BookCategory(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)

    def __str__(self): return self.name
    class Meta: db_table = 'library_book_category'; verbose_name_plural = 'Book Categories'


class Book(models.Model):
    isbn = models.CharField(max_length=20, unique=True, blank=True)
    title = models.CharField(max_length=300)
    author = models.CharField(max_length=200)
    publisher = models.CharField(max_length=200, blank=True)
    edition = models.CharField(max_length=50, blank=True)
    year_published = models.PositiveSmallIntegerField(null=True, blank=True)
    category = models.ForeignKey(BookCategory, on_delete=models.SET_NULL, null=True, blank=True)
    subject = models.ForeignKey('academics.Subject', on_delete=models.SET_NULL, null=True, blank=True)
    total_copies = models.PositiveSmallIntegerField(default=1)
    available_copies = models.PositiveSmallIntegerField(default=1)
    rack_number = models.CharField(max_length=20, blank=True)
    shelf_number = models.CharField(max_length=20, blank=True)
    barcode = models.CharField(max_length=50, unique=True, blank=True)
    cover_image = models.ImageField(upload_to='books/', null=True, blank=True)
    is_ebook = models.BooleanField(default=False)
    ebook_url = models.URLField(blank=True)
    description = models.TextField(blank=True)
    tags = models.JSONField(default=list, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.title} by {self.author}"
    class Meta: db_table = 'library_book'; ordering = ['title']


class LibraryMember(models.Model):
    MEMBER_TYPE_CHOICES = [('student', 'Student'), ('staff', 'Staff')]
    student = models.OneToOneField(
        'students.Student', on_delete=models.CASCADE,
        null=True, blank=True, related_name='library_membership'
    )
    staff = models.OneToOneField(
        'staff.Staff', on_delete=models.CASCADE,
        null=True, blank=True, related_name='library_membership'
    )
    member_type = models.CharField(max_length=10, choices=MEMBER_TYPE_CHOICES)
    membership_id = models.CharField(max_length=20, unique=True)
    membership_valid_till = models.DateField(null=True, blank=True)
    max_books_allowed = models.PositiveSmallIntegerField(default=3)
    is_active = models.BooleanField(default=True)
    joined_date = models.DateField(auto_now_add=True)

    def __str__(self):
        if self.student:
            return f"{self.student.full_name} (Student)"
        return f"{self.staff.full_name} (Staff)"

    class Meta: db_table = 'library_member'


class BookIssue(models.Model):
    STATUS_CHOICES = [
        ('issued', 'Issued'), ('returned', 'Returned'),
        ('overdue', 'Overdue'), ('lost', 'Lost'), ('damaged', 'Damaged'),
    ]
    book = models.ForeignKey(Book, on_delete=models.CASCADE, related_name='issues')
    member = models.ForeignKey(LibraryMember, on_delete=models.CASCADE, related_name='issues')
    issue_date = models.DateField(default=timezone.now)
    due_date = models.DateField()
    return_date = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='issued')
    fine_per_day = models.DecimalField(max_digits=5, decimal_places=2, default=1)
    fine_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    fine_paid = models.BooleanField(default=False)
    issued_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='issued_books'
    )
    remarks = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self): return f"{self.book.title} → {self.member}"

    def calculate_fine(self):
        if self.status == 'returned' and self.return_date and self.return_date > self.due_date:
            days_late = (self.return_date - self.due_date).days
            self.fine_amount = days_late * float(self.fine_per_day)
        elif self.status == 'issued' and timezone.now().date() > self.due_date:
            days_late = (timezone.now().date() - self.due_date).days
            self.fine_amount = days_late * float(self.fine_per_day)
            self.status = 'overdue'
        return self.fine_amount

    class Meta: db_table = 'library_book_issue'; ordering = ['-issue_date']
