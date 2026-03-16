# tickets/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import TicketCategory, SLAPolicy, Ticket, TicketReply, TicketAttachment, TicketActivity

User = get_user_model()


class TicketCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model  = TicketCategory
        fields = '__all__'


class SLAPolicySerializer(serializers.ModelSerializer):
    escalate_to_name = serializers.CharField(source='escalate_to.get_full_name', read_only=True)

    class Meta:
        model  = SLAPolicy
        fields = '__all__'


class TicketReplySerializer(serializers.ModelSerializer):
    author_name  = serializers.CharField(source='author.get_full_name', read_only=True)

    class Meta:
        model  = TicketReply
        fields = '__all__'
        read_only_fields = ['author', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        return super().create(validated_data)


class TicketAttachmentSerializer(serializers.ModelSerializer):
    class Meta:
        model  = TicketAttachment
        fields = '__all__'
        read_only_fields = ['uploaded_by', 'uploaded_at']

    def create(self, validated_data):
        validated_data['uploaded_by'] = self.context['request'].user
        return super().create(validated_data)


class TicketActivitySerializer(serializers.ModelSerializer):
    performed_by_name = serializers.CharField(source='performed_by.get_full_name', read_only=True)

    class Meta:
        model  = TicketActivity
        fields = '__all__'


class TicketSerializer(serializers.ModelSerializer):
    contact_name    = serializers.SerializerMethodField()
    company_name    = serializers.CharField(source='company.name', read_only=True)
    category_name   = serializers.CharField(source='category.name', read_only=True)
    category_color  = serializers.CharField(source='category.color', read_only=True)
    assigned_to_name = serializers.CharField(source='assigned_to.get_full_name', read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)
    sla_policy_name = serializers.CharField(source='sla_policy.name', read_only=True)
    replies         = TicketReplySerializer(many=True, read_only=True)
    activities      = TicketActivitySerializer(many=True, read_only=True)
    attachments     = TicketAttachmentSerializer(many=True, read_only=True)
    is_overdue      = serializers.BooleanField(read_only=True)
    response_overdue = serializers.BooleanField(read_only=True)
    time_to_resolution = serializers.FloatField(read_only=True)

    class Meta:
        model  = Ticket
        fields = '__all__'
        read_only_fields = ['ticket_number', 'created_by', 'first_response_at',
                            'first_response_due', 'resolution_due', 'sla_breached',
                            'resolved_at', 'closed_at', 'created_at', 'updated_at']

    def get_contact_name(self, obj):
        return obj.contact.full_name if obj.contact else None

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        ticket = super().create(validated_data)
        # Log creation
        TicketActivity.objects.create(
            ticket=ticket, action='created',
            description=f'Ticket created via {ticket.get_channel_display()}',
            performed_by=self.context['request'].user
        )
        return ticket


class TicketListSerializer(serializers.ModelSerializer):
    contact_name    = serializers.SerializerMethodField()
    company_name    = serializers.CharField(source='company.name', read_only=True)
    category_name   = serializers.CharField(source='category.name', read_only=True)
    category_color  = serializers.CharField(source='category.color', read_only=True)
    assigned_to_name = serializers.CharField(source='assigned_to.get_full_name', read_only=True)
    is_overdue      = serializers.BooleanField(read_only=True)
    response_overdue = serializers.BooleanField(read_only=True)
    replies_count   = serializers.SerializerMethodField()

    class Meta:
        model  = Ticket
        fields = ['id', 'ticket_number', 'subject', 'status', 'priority', 'channel',
                  'contact_name', 'company_name', 'category_name', 'category_color',
                  'assigned_to_name', 'sla_due_date', 'first_response_due', 'resolution_due',
                  'sla_breached', 'is_overdue', 'response_overdue', 'csat_score',
                  'replies_count', 'created_at', 'updated_at', 'resolved_at']

    def get_contact_name(self, obj):
        return obj.contact.full_name if obj.contact else None

    def get_replies_count(self, obj):
        return obj.replies.filter(is_public=True).count()
