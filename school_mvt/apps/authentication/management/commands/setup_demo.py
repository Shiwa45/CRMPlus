"""
Management command to create demo data for first-time setup.
Run: python manage.py setup_demo
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
import datetime

User = get_user_model()


class Command(BaseCommand):
    help = 'Create demo users, classes, subjects and initial data'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.MIGRATE_HEADING('Setting up EduManage Pro demo data...'))

        # ── Super Admin ───────────────────────────────────────────
        if not User.objects.filter(username='admin').exists():
            User.objects.create_superuser(
                username='admin',
                email='admin@school.edu',
                password='admin123',
                first_name='Super',
                last_name='Admin',
                role='super_admin',
            )
            self.stdout.write(self.style.SUCCESS('  ✓ Superuser: admin / admin123'))

        # ── School Admin ──────────────────────────────────────────
        if not User.objects.filter(username='school_admin').exists():
            User.objects.create_user(
                username='school_admin',
                email='schooladmin@school.edu',
                password='admin123',
                first_name='Rajesh',
                last_name='Sharma',
                role='school_admin',
            )
            self.stdout.write(self.style.SUCCESS('  ✓ School Admin: school_admin / admin123'))

        # ── Principal ─────────────────────────────────────────────
        if not User.objects.filter(username='principal').exists():
            User.objects.create_user(
                username='principal',
                email='principal@school.edu',
                password='admin123',
                first_name='Dr. Anita',
                last_name='Verma',
                role='principal',
            )
            self.stdout.write(self.style.SUCCESS('  ✓ Principal: principal / admin123'))

        # ── Teachers ──────────────────────────────────────────────
        teachers_data = [
            ('teacher1', 'Priya', 'Gupta', 'priya@school.edu'),
            ('teacher2', 'Amit', 'Kumar', 'amit@school.edu'),
            ('teacher3', 'Sunita', 'Singh', 'sunita@school.edu'),
        ]
        for username, first, last, email in teachers_data:
            if not User.objects.filter(username=username).exists():
                User.objects.create_user(
                    username=username, email=email, password='teacher123',
                    first_name=first, last_name=last, role='teacher',
                )
        self.stdout.write(self.style.SUCCESS('  ✓ Teachers: teacher1, teacher2, teacher3 / teacher123'))

        # ── Accountant ────────────────────────────────────────────
        if not User.objects.filter(username='accountant').exists():
            User.objects.create_user(
                username='accountant', email='accounts@school.edu',
                password='admin123', first_name='Ravi', last_name='Mehta',
                role='accountant',
            )
            self.stdout.write(self.style.SUCCESS('  ✓ Accountant: accountant / admin123'))

        # ── Academic Year ─────────────────────────────────────────
        from apps.academics.models import AcademicYear, Class, Section, Subject, Period
        ay, _ = AcademicYear.objects.get_or_create(
            name='2024-25',
            defaults={
                'start_date': datetime.date(2024, 4, 1),
                'end_date': datetime.date(2025, 3, 31),
                'is_current': True,
            }
        )
        self.stdout.write(self.style.SUCCESS('  ✓ Academic Year 2024-25'))

        # ── Classes ───────────────────────────────────────────────
        class_names = [
            ('LKG', 0), ('UKG', 1), ('Class 1', 2), ('Class 2', 3),
            ('Class 3', 4), ('Class 4', 5), ('Class 5', 6),
            ('Class 6', 7), ('Class 7', 8), ('Class 8', 9),
            ('Class 9', 10), ('Class 10', 11), ('Class 11', 12), ('Class 12', 13),
        ]
        classes = {}
        for name, order in class_names:
            cls, _ = Class.objects.get_or_create(name=name, defaults={'order': order})
            classes[name] = cls

        self.stdout.write(self.style.SUCCESS(f'  ✓ {len(class_names)} classes created'))

        # ── Sections ─────────────────────────────────────────────
        teacher_users = list(User.objects.filter(role='teacher'))
        section_count = 0
        for class_name in ['Class 1', 'Class 2', 'Class 3', 'Class 5', 'Class 9', 'Class 10']:
            if class_name in classes:
                for sec_name, teacher_idx in [('A', 0), ('B', 1)]:
                    teacher = teacher_users[teacher_idx % len(teacher_users)] if teacher_users else None
                    sec, created = Section.objects.get_or_create(
                        school_class=classes[class_name],
                        name=sec_name,
                        defaults={'class_teacher': teacher, 'max_strength': 40}
                    )
                    if created:
                        section_count += 1

        self.stdout.write(self.style.SUCCESS(f'  ✓ {section_count} sections created'))

        # ── Subjects ─────────────────────────────────────────────
        subjects_data = [
            ('Mathematics', 'MATH', 'core', False),
            ('English', 'ENG', 'core', False),
            ('Hindi', 'HINDI', 'core', False),
            ('Science', 'SCI', 'core', True),
            ('Social Science', 'SST', 'core', False),
            ('Computer Science', 'CS', 'elective', True),
            ('Physical Education', 'PE', 'activity', False),
        ]
        for name, code, stype, has_prac in subjects_data:
            subj, _ = Subject.objects.get_or_create(
                code=code,
                defaults={
                    'name': name,
                    'subject_type': stype,
                    'has_practical': has_prac,
                    'max_practical_marks': 30 if has_prac else 0,
                    'passing_marks': 33,
                }
            )

        self.stdout.write(self.style.SUCCESS(f'  ✓ {len(subjects_data)} subjects created'))

        # ── Periods ───────────────────────────────────────────────
        periods_data = [
            ('Period 1', '08:00', '08:45', False, 0),
            ('Period 2', '08:45', '09:30', False, 1),
            ('Period 3', '09:30', '10:15', False, 2),
            ('Break', '10:15', '10:30', True, 3),
            ('Period 4', '10:30', '11:15', False, 4),
            ('Period 5', '11:15', '12:00', False, 5),
            ('Lunch', '12:00', '12:30', True, 6),
            ('Period 6', '12:30', '13:15', False, 7),
            ('Period 7', '13:15', '14:00', False, 8),
        ]
        for name, start, end, is_break, order in periods_data:
            Period.objects.get_or_create(
                name=name,
                defaults={
                    'start_time': start,
                    'end_time': end,
                    'is_break': is_break,
                    'order': order,
                }
            )
        self.stdout.write(self.style.SUCCESS(f'  ✓ {len(periods_data)} periods configured'))

        # ── Fee Types ─────────────────────────────────────────────
        from apps.fees.models import FeeType, FeeStructure
        fee_types_data = [
            ('Tuition Fee', 'TUITION'),
            ('Transport Fee', 'TRANSPORT'),
            ('Library Fee', 'LIBRARY'),
            ('Lab Fee', 'LAB'),
            ('Exam Fee', 'EXAM'),
            ('Annual Charges', 'ANNUAL'),
        ]
        fee_types = {}
        for name, code in fee_types_data:
            ft, _ = FeeType.objects.get_or_create(code=code, defaults={'name': name})
            fee_types[code] = ft

        self.stdout.write(self.style.SUCCESS(f'  ✓ {len(fee_types_data)} fee types created'))

        # ── Fee Structures ────────────────────────────────────────
        tuition_amounts = {
            'LKG': 800, 'UKG': 800, 'Class 1': 1000, 'Class 2': 1000,
            'Class 3': 1200, 'Class 4': 1200, 'Class 5': 1200,
            'Class 6': 1500, 'Class 7': 1500, 'Class 8': 1500,
            'Class 9': 2000, 'Class 10': 2000,
            'Class 11': 2500, 'Class 12': 2500,
        }
        fs_count = 0
        for class_name, amount in tuition_amounts.items():
            if class_name in classes:
                fs, created = FeeStructure.objects.get_or_create(
                    school_class=classes[class_name],
                    fee_type=fee_types['TUITION'],
                    academic_year='2024-25',
                    defaults={'amount': amount, 'late_fee_per_day': 5}
                )
                if created:
                    fs_count += 1

        self.stdout.write(self.style.SUCCESS(f'  ✓ {fs_count} fee structures created'))

        # ── Demo Students ─────────────────────────────────────────
        from apps.students.models import Student, Guardian
        students_data = [
            ('Arjun', 'Sharma', 'ADM2024001', 'M', 'Class 10', 'A'),
            ('Priya', 'Singh', 'ADM2024002', 'F', 'Class 10', 'A'),
            ('Rahul', 'Gupta', 'ADM2024003', 'M', 'Class 9', 'B'),
            ('Anjali', 'Kumar', 'ADM2024004', 'F', 'Class 9', 'A'),
            ('Vikram', 'Patel', 'ADM2024005', 'M', 'Class 5', 'B'),
            ('Sneha', 'Mehta', 'ADM2024006', 'F', 'Class 5', 'A'),
            ('Rohan', 'Verma', 'ADM2024007', 'M', 'Class 1', 'A'),
            ('Kavya', 'Agarwal', 'ADM2024008', 'F', 'Class 1', 'B'),
        ]
        student_count = 0
        for first, last, adm_no, gender, class_name, sec_name in students_data:
            if not Student.objects.filter(admission_number=adm_no).exists():
                cls = classes.get(class_name)
                sec = Section.objects.filter(school_class=cls, name=sec_name).first() if cls else None
                student = Student.objects.create(
                    first_name=first, last_name=last,
                    admission_number=adm_no,
                    date_of_birth=datetime.date(2010, 6, 15),
                    gender=gender,
                    current_class=cls,
                    current_section=sec,
                    academic_year='2024-25',
                    status='active',
                    roll_number=str(student_count + 1).zfill(2),
                )
                Guardian.objects.create(
                    name=f'{last} Parent',
                    relation='father',
                    phone=f'98{student_count:08d}',
                    is_primary=True,
                )
                student_count += 1

        self.stdout.write(self.style.SUCCESS(f'  ✓ {student_count} demo students created'))

        # ── Demo Staff ────────────────────────────────────────────
        from apps.staff.models import Staff, Department, Designation, LeaveType
        dept_academic, _ = Department.objects.get_or_create(name='Academic')
        dept_admin, _ = Department.objects.get_or_create(name='Administration')
        desig_teacher, _ = Designation.objects.get_or_create(name='Teacher', defaults={'department': dept_academic})
        desig_accountant, _ = Designation.objects.get_or_create(name='Accountant', defaults={'department': dept_admin})

        staff_count = 0
        for user in User.objects.filter(role='teacher'):
            if not Staff.objects.filter(user=user).exists():
                Staff.objects.create(
                    user=user,
                    employee_id=f'EMP{staff_count + 1001}',
                    department=dept_academic,
                    designation=desig_teacher,
                    employment_type='permanent',
                    joining_date=datetime.date(2020, 6, 1),
                    basic_salary=35000,
                    is_active=True,
                )
                staff_count += 1

        accountant_user = User.objects.filter(role='accountant').first()
        if accountant_user and not Staff.objects.filter(user=accountant_user).exists():
            Staff.objects.create(
                user=accountant_user,
                employee_id='EMP2001',
                department=dept_admin,
                designation=desig_accountant,
                employment_type='permanent',
                joining_date=datetime.date(2019, 4, 1),
                basic_salary=30000,
                is_active=True,
            )
            staff_count += 1

        self.stdout.write(self.style.SUCCESS(f'  ✓ {staff_count} staff profiles created'))

        # ── Leave Types ───────────────────────────────────────────
        for code, name, days in [('CL', 'Casual Leave', 12), ('EL', 'Earned Leave', 15),
                                   ('ML', 'Medical Leave', 10), ('SL', 'Special Leave', 5)]:
            LeaveType.objects.get_or_create(code=code, defaults={'name': name, 'days_allowed': days})
        self.stdout.write(self.style.SUCCESS('  ✓ Leave types configured'))

        # ── Notices ───────────────────────────────────────────────
        from apps.communication.models import Notice
        admin_user = User.objects.filter(username='admin').first()
        notices_data = [
            ('Annual Day Celebration', 'Annual Day will be celebrated on 15th March 2025. All students and parents are requested to attend.', 'all', True),
            ('Parent-Teacher Meeting', 'PTM is scheduled for 25th January 2025 from 9 AM to 1 PM.', 'parents', False),
            ('Mid-Term Examination Schedule', 'Mid-term examinations begin from 10th February 2025. Admit cards will be distributed next week.', 'students', False),
            ('Staff Meeting Notice', 'Monthly staff meeting on every last Saturday at 3 PM in the conference room.', 'staff', False),
            ('Holiday Notice - Republic Day', 'School will remain closed on 26th January 2025 on account of Republic Day.', 'all', True),
        ]
        notice_count = 0
        for title, content, audience, is_pinned in notices_data:
            if not Notice.objects.filter(title=title).exists():
                Notice.objects.create(
                    title=title, content=content,
                    audience=audience, is_pinned=is_pinned,
                    published_by=admin_user, is_active=True,
                )
                notice_count += 1
        self.stdout.write(self.style.SUCCESS(f'  ✓ {notice_count} sample notices created'))

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 55))
        self.stdout.write(self.style.SUCCESS('  EduManage Pro Demo Setup Complete!'))
        self.stdout.write(self.style.SUCCESS('=' * 55))
        self.stdout.write('')
        self.stdout.write(self.style.HTTP_INFO('  Login credentials:'))
        self.stdout.write('    Admin        → admin / admin123')
        self.stdout.write('    School Admin → school_admin / admin123')
        self.stdout.write('    Principal    → principal / admin123')
        self.stdout.write('    Teacher      → teacher1 / teacher123')
        self.stdout.write('    Accountant   → accountant / admin123')
        self.stdout.write('')
        self.stdout.write(self.style.HTTP_INFO('  Run the server:'))
        self.stdout.write('    python manage.py runserver')
        self.stdout.write('    Open → http://127.0.0.1:8000/')
        self.stdout.write('')
