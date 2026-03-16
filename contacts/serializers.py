# contacts/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import Company, Contact, ContactDocument, ContactActivity

User = get_user_model()


class CompanySerializer(serializers.ModelSerializer):
    contacts_count = serializers.SerializerMethodField()
    owner_name     = serializers.CharField(source='owner.get_full_name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model  = Company
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def get_contacts_count(self, obj):
        return obj.contacts.count()

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ContactDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model  = ContactDocument
        fields = '__all__'
        read_only_fields = ['uploaded_by', 'uploaded_at']

    def create(self, validated_data):
        validated_data['uploaded_by'] = self.context['request'].user
        return super().create(validated_data)


class ContactActivitySerializer(serializers.ModelSerializer):
    performed_by_name = serializers.CharField(source='performed_by.get_full_name', read_only=True)

    class Meta:
        model  = ContactActivity
        fields = '__all__'
        read_only_fields = ['performed_by', 'created_at']

    def create(self, validated_data):
        validated_data['performed_by'] = self.context['request'].user
        return super().create(validated_data)


class ContactSerializer(serializers.ModelSerializer):
    full_name      = serializers.ReadOnlyField()
    company_name   = serializers.CharField(source='company.name', read_only=True)
    owner_name     = serializers.CharField(source='owner.get_full_name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    documents      = ContactDocumentSerializer(many=True, read_only=True)
    activities     = ContactActivitySerializer(many=True, read_only=True)

    class Meta:
        model  = Contact
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class ContactListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list views"""
    full_name    = serializers.ReadOnlyField()
    company_name = serializers.CharField(source='company.name', read_only=True)
    owner_name   = serializers.CharField(source='owner.get_full_name', read_only=True)

    class Meta:
        model  = Contact
        fields = ['id', 'full_name', 'first_name', 'last_name', 'email', 'phone',
                  'mobile', 'whatsapp', 'job_title', 'company', 'company_name',
                  'owner_name', 'tags', 'is_active', 'do_not_contact', 'created_at', 'last_contacted']
