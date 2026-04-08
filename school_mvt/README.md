# EduManage Pro — Django MVT School Management System

A complete, production-ready school management web app built with **Django MVT** (no Flutter, no DRF API).

---

## 📁 Project Structure

```
school_mvt/
├── manage.py
├── requirements.txt
├── config/
│   ├── settings/base.py       ← All settings
│   ├── urls.py                ← Root URL config
│   └── wsgi.py
├── apps/
│   ├── authentication/        ← Custom User model, login, profile
│   ├── dashboard/             ← Home dashboard + context processor
│   ├── students/              ← Student CRUD, admissions, promotions
│   ├── academics/             ← Classes, sections, subjects, timetable, homework
│   ├── attendance/            ← Mark attendance, reports, defaulters
│   ├── fees/                  ← Fee collection, structure, defaulters, reports
│   ├── staff/                 ← Staff management, leave, payroll
│   ├── examinations/          ← Exams, marks entry, results, report cards
│   └── communication/         ← Notices, announcements, messages
└── templates/
    ├── base.html              ← Sidebar layout (Bootstrap 5)
    ├── authentication/        ← login, profile, users, change_password
    ├── dashboard/             ← home (stats + charts)
    ├── students/              ← list, detail, form, admissions, promotions
    ├── academics/             ← classes, subjects, timetable, homework
    ├── attendance/            ← mark, report, defaulters
    ├── fees/                  ← list, collect, structure, defaulters, reports
    ├── staff/                 ← list, detail, leave, payroll
    ├── examinations/          ← list, marks_entry, results, report_cards
    ├── communication/         ← notices, notice_form, announcements, messages
    └── partials/              ← detail_field.html (reusable snippet)
```

---

## 🚀 Quick Start

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Run migrations
```bash
python manage.py migrate
```

### 3. Load demo data (users, classes, students, fees, notices…)
```bash
python manage.py setup_demo
```

### 4. Start the development server
```bash
python manage.py runserver
```

Open → **http://127.0.0.1:8000/**

---

## 🔐 Demo Login Credentials

| Role           | Username       | Password     |
|----------------|---------------|--------------|
| Super Admin    | `admin`        | `admin123`   |
| School Admin   | `school_admin` | `admin123`   |
| Principal      | `principal`    | `admin123`   |
| Teacher        | `teacher1`     | `teacher123` |
| Accountant     | `accountant`   | `admin123`   |

---

## ✨ Features Implemented

### 🎛️ Dashboard
- Stats cards: students, staff, today's fee, attendance %
- Monthly fee bar chart (Chart.js)
- Today's attendance doughnut chart
- Recent notices feed
- Quick action buttons
- Dark mode toggle

### 👨‍🎓 Students
- Full CRUD (list, detail, add, edit, delete)
- Table & grid view toggle
- Search + filter by class/section/status/gender
- Pagination
- Guardian management (multiple guardians)
- Medical records
- Admission & promotion workflows

### 📚 Academics
- Class & section management with student counts
- Subject master (core/elective/activity)
- Timetable grid (day × period matrix)
- Homework assignment & listing

### ✅ Attendance
- Mark attendance by section & date (bulk actions: all present/absent)
- Live row colour highlighting per status
- Monthly attendance report with progress bars
- Defaulters list (configurable threshold %)

### 💰 Fee Management
- Fee collection with receipt generation
- Outstanding fee breakdown per student
- Fee structure configuration by class
- Defaulters list with outstanding amounts
- Reports: monthly chart, by mode, by fee type

### 👩‍🏫 Staff / HR
- Staff directory with search & department filter
- Staff detail with tabs (info, leaves, salary)
- Leave request management (approve/reject inline)
- Payroll / salary slip listing

### 📝 Examinations
- Exam scheduling (unit test, mid-term, final…)
- Marks entry (theory + practical per student)
- Auto grade calculation (A1–E)
- Class rank list with toppers highlighted
- Printable report cards with signature fields

### 📢 Communication
- Notice board (pinned + audience filtering)
- Post notice form
- Announcements with priority & channel badges (SMS/Email/Push)
- Internal messaging (inbox + compose)

### 👤 User Management
- User list with role badges
- Profile editing + photo upload
- Change password
- Dark mode / light mode
- Responsive sidebar (collapsible, mobile overlay)

---

## 🛠️ Tech Stack

| Layer      | Technology                         |
|------------|-----------------------------------|
| Backend    | Django 4.2 (MVT — no REST API)     |
| Auth       | Custom User model with roles       |
| Frontend   | Bootstrap 5.3 + Bootstrap Icons    |
| Charts     | Chart.js 4                        |
| Fonts      | Plus Jakarta Sans (Google Fonts)   |
| Static     | WhiteNoise                        |
| Database   | SQLite (dev) → PostgreSQL (prod)   |
| Forms      | django-crispy-forms + widget-tweaks|

---

## 🔧 Customisation

### Change school name
In `apps/dashboard/context_processors.py`:
```python
return {
    'SCHOOL_NAME': 'Your School Name',
    'ACADEMIC_YEAR': '2025-26',
    ...
}
```

### Switch to PostgreSQL
In `config/settings/base.py`:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'school_db',
        'USER': 'postgres',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

### Add a new role to sidebar
In `apps/dashboard/context_processors.py`, edit `NAV_ITEMS` and add the role string to the `roles` list.

---

## 📧 Email & SMS Setup
Set in `config/settings/base.py`:
```python
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST = 'smtp.gmail.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'your@email.com'
EMAIL_HOST_PASSWORD = 'app_password'
```

---

## 🚀 Production Checklist
- [ ] Set `DEBUG = False`
- [ ] Set a strong `SECRET_KEY` via environment variable
- [ ] Configure PostgreSQL
- [ ] Run `python manage.py collectstatic`
- [ ] Set up Gunicorn + Nginx
- [ ] Configure `ALLOWED_HOSTS`
- [ ] Set up SSL/HTTPS
