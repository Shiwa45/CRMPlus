# forms.py
from django import forms
from .models import Student, Guardian
from apps.academics.models import Class, Section


class StudentForm(forms.ModelForm):
    class Meta:
        model = Student
        exclude = ['guardians', 'created_at', 'updated_at']
        widgets = {
            'admission_number': forms.TextInput(attrs={'class': 'form-control'}),
            'roll_number': forms.TextInput(attrs={'class': 'form-control'}),
            'first_name': forms.TextInput(attrs={'class': 'form-control'}),
            'last_name': forms.TextInput(attrs={'class': 'form-control'}),
            'date_of_birth': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'gender': forms.Select(attrs={'class': 'form-select'}),
            'blood_group': forms.Select(attrs={'class': 'form-select'}),
            'category': forms.Select(attrs={'class': 'form-select'}),
            'aadhar_number': forms.TextInput(attrs={'class': 'form-control'}),
            'photo': forms.FileInput(attrs={'class': 'form-control'}),
            'current_class': forms.Select(attrs={'class': 'form-select'}),
            'current_section': forms.Select(attrs={'class': 'form-select'}),
            'admission_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'academic_year': forms.TextInput(attrs={'class': 'form-control'}),
            'address': forms.Textarea(attrs={'class': 'form-control', 'rows': 3}),
            'city': forms.TextInput(attrs={'class': 'form-control'}),
            'state': forms.TextInput(attrs={'class': 'form-control'}),
            'pincode': forms.TextInput(attrs={'class': 'form-control'}),
            'medical_conditions': forms.Textarea(attrs={'class': 'form-control', 'rows': 2}),
            'allergies': forms.Textarea(attrs={'class': 'form-control', 'rows': 2}),
            'emergency_contact': forms.TextInput(attrs={'class': 'form-control'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
            'requires_transport': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'requires_hostel': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }


class GuardianForm(forms.ModelForm):
    class Meta:
        model = Guardian
        fields = '__all__'
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'relation': forms.Select(attrs={'class': 'form-select'}),
            'phone': forms.TextInput(attrs={'class': 'form-control'}),
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
            'occupation': forms.TextInput(attrs={'class': 'form-control'}),
            'annual_income': forms.NumberInput(attrs={'class': 'form-control'}),
            'aadhar_number': forms.TextInput(attrs={'class': 'form-control'}),
            'is_primary': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }
