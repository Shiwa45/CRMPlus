def school_context(request):
    nav_items = [
        {'label': 'Dashboard', 'icon': 'bi-speedometer2', 'url_name': 'dashboard:home', 'roles': '__all__'},
        {
            'label': 'Students', 'icon': 'bi-people-fill', 'url_name': 'students:list', 'roles': '__all__',
            'children': [
                {'label': 'All Students', 'url_name': 'students:list'},
                {'label': 'Admissions', 'url_name': 'students:admissions'},
                {'label': 'Promotions', 'url_name': 'students:promotions'},
            ],
        },
        {
            'label': 'Academics', 'icon': 'bi-book-fill', 'url_name': 'academics:classes', 'roles': '__all__',
            'children': [
                {'label': 'Classes & Sections', 'url_name': 'academics:classes'},
                {'label': 'Subjects', 'url_name': 'academics:subjects'},
                {'label': 'Timetable', 'url_name': 'academics:timetable'},
                {'label': 'Homework', 'url_name': 'academics:homework'},
            ],
        },
        {
            'label': 'Attendance', 'icon': 'bi-calendar-check-fill', 'url_name': 'attendance:mark', 'roles': '__all__',
            'children': [
                {'label': 'Mark Attendance', 'url_name': 'attendance:mark'},
                {'label': 'Reports', 'url_name': 'attendance:report'},
                {'label': 'Defaulters', 'url_name': 'attendance:defaulters'},
            ],
        },
        {
            'label': 'Examinations', 'icon': 'bi-file-earmark-text-fill', 'url_name': 'examinations:list', 'roles': '__all__',
            'children': [
                {'label': 'Exam Schedule', 'url_name': 'examinations:list'},
                {'label': 'Marks Entry', 'url_name': 'examinations:marks_entry'},
                {'label': 'Report Cards', 'url_name': 'examinations:report_cards'},
                {'label': 'Results', 'url_name': 'examinations:results'},
            ],
        },
        {
            'label': 'Fee Management', 'icon': 'bi-cash-coin', 'url_name': 'fees:list',
            'roles': ['super_admin', 'school_admin', 'principal', 'accountant'],
            'children': [
                {'label': 'Fee Collection', 'url_name': 'fees:collect'},
                {'label': 'Fee Structure', 'url_name': 'fees:structure'},
                {'label': 'Defaulters', 'url_name': 'fees:defaulters'},
                {'label': 'Reports', 'url_name': 'fees:reports'},
            ],
        },
        {
            'label': 'Staff / HR', 'icon': 'bi-person-badge-fill', 'url_name': 'staff:list',
            'roles': ['super_admin', 'school_admin', 'principal'],
            'children': [
                {'label': 'All Staff', 'url_name': 'staff:list'},
                {'label': 'Leave Requests', 'url_name': 'staff:leave'},
                {'label': 'Payroll', 'url_name': 'staff:payroll'},
            ],
        },
        {
            'label': 'Library', 'icon': 'bi-journal-bookmark-fill', 'url_name': 'library:book_list', 'roles': '__all__',
            'children': [
                {'label': 'Books Catalog', 'url_name': 'library:book_list'},
                {'label': 'Issue / Return', 'url_name': 'library:issue_return'},
                {'label': 'Reports', 'url_name': 'library:report'},
            ],
        },
        {
            'label': 'Transport', 'icon': 'bi-bus-front-fill', 'url_name': 'transport:dashboard',
            'roles': ['super_admin', 'school_admin', 'principal', 'transport_manager'],
            'children': [
                {'label': 'Dashboard', 'url_name': 'transport:dashboard'},
                {'label': 'Routes', 'url_name': 'transport:routes'},
                {'label': 'Vehicles', 'url_name': 'transport:vehicles'},
                {'label': 'Student Allocation', 'url_name': 'transport:allocation'},
            ],
        },
        {
            'label': 'Hostel', 'icon': 'bi-building-fill', 'url_name': 'hostel:dashboard',
            'roles': ['super_admin', 'school_admin', 'principal'],
            'children': [
                {'label': 'Dashboard', 'url_name': 'hostel:dashboard'},
                {'label': 'Rooms', 'url_name': 'hostel:rooms'},
                {'label': 'Allocations', 'url_name': 'hostel:allocations'},
            ],
        },
        {
            'label': 'Inventory', 'icon': 'bi-box-seam-fill', 'url_name': 'inventory:dashboard',
            'roles': ['super_admin', 'school_admin'],
            'children': [
                {'label': 'Dashboard', 'url_name': 'inventory:dashboard'},
                {'label': 'Assets', 'url_name': 'inventory:assets'},
                {'label': 'Inventory Items', 'url_name': 'inventory:items'},
                {'label': 'Stock Transactions', 'url_name': 'inventory:stock_transactions'},
            ],
        },
        {
            'label': 'Health', 'icon': 'bi-heart-pulse-fill', 'url_name': 'health:records', 'roles': '__all__',
            'children': [
                {'label': 'Health Records', 'url_name': 'health:records'},
                {'label': 'Sick Room', 'url_name': 'health:sick_room'},
            ],
        },
        {
            'label': 'Sports', 'icon': 'bi-trophy-fill', 'url_name': 'sports:dashboard', 'roles': '__all__',
            'children': [
                {'label': 'Overview', 'url_name': 'sports:dashboard'},
                {'label': 'Achievements', 'url_name': 'sports:achievements'},
            ],
        },
        {
            'label': 'Communication', 'icon': 'bi-chat-dots-fill', 'url_name': 'communication:notices', 'roles': '__all__',
            'children': [
                {'label': 'Notice Board', 'url_name': 'communication:notices'},
                {'label': 'Announcements', 'url_name': 'communication:announcements'},
                {'label': 'Messages', 'url_name': 'communication:messages'},
            ],
        },
        {
            'label': 'Visitors', 'icon': 'bi-person-check-fill', 'url_name': 'visitor:list',
            'roles': ['super_admin', 'school_admin', 'principal', 'support_staff'],
        },
        {
            'label': 'Alumni', 'icon': 'bi-mortarboard-fill', 'url_name': 'alumni:list',
            'roles': ['super_admin', 'school_admin', 'principal'],
        },
        {
            'label': 'Discipline', 'icon': 'bi-shield-fill-exclamation', 'url_name': 'discipline:incidents',
            'roles': ['super_admin', 'school_admin', 'principal'],
            'children': [
                {'label': 'Incidents', 'url_name': 'discipline:incidents'},
                {'label': 'Counselling', 'url_name': 'discipline:counselling'},
            ],
        },
        {
            'label': 'Reports', 'icon': 'bi-graph-up-arrow', 'url_name': 'reports:dashboard',
            'roles': ['super_admin', 'school_admin', 'principal', 'accountant'],
            'children': [
                {'label': 'Overview', 'url_name': 'reports:dashboard'},
                {'label': 'Academic', 'url_name': 'reports:academic'},
                {'label': 'Fee Reports', 'url_name': 'reports:fee'},
                {'label': 'Attendance', 'url_name': 'reports:attendance_report'},
                {'label': 'Staff Reports', 'url_name': 'reports:staff_report'},
            ],
        },
        {'label': 'Help Desk', 'icon': 'bi-ticket-fill', 'url_name': 'helpdesk:tickets', 'roles': '__all__'},
        {
            'label': 'User Mgmt', 'icon': 'bi-shield-lock-fill', 'url_name': 'auth:users',
            'roles': ['super_admin', 'school_admin'],
        },
        {
            'label': 'Settings', 'icon': 'bi-gear-fill', 'url_name': 'settings_app:dashboard',
            'roles': ['super_admin', 'school_admin'],
        },
    ]

    # Try to get tenant-specific school name
    try:
        from apps.tenants.models import School
        from django.db import connection
        if connection.schema_name != 'public':
            school = School.objects.filter(schema_name=connection.schema_name).first()
            school_name = school.name if school else 'EduManage Pro'
            academic_year = school.current_academic_year if school else '2024-25'
        else:
            school_name = 'EduManage Pro'
            academic_year = '2024-25'
    except Exception:
        school_name = 'EduManage Pro'
        academic_year = '2024-25'

    return {
        'SCHOOL_NAME': school_name,
        'SCHOOL_SHORT': school_name[:3].upper(),
        'ACADEMIC_YEAR': academic_year,
        'NAV_ITEMS': nav_items,
    }
