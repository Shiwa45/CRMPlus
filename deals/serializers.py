# deals/serializers.py
from rest_framework import serializers
from .models import Pipeline, PipelineStage, Deal, DealActivity, DealStageHistory


class PipelineStageSerializer(serializers.ModelSerializer):
    deals_count  = serializers.SerializerMethodField()
    deals_value  = serializers.SerializerMethodField()

    class Meta:
        model  = PipelineStage
        fields = '__all__'

    def get_deals_count(self, obj):
        return obj.deals.count()

    def get_deals_value(self, obj):
        from django.db.models import Sum
        return obj.deals.aggregate(v=Sum('value'))['v'] or 0


class PipelineSerializer(serializers.ModelSerializer):
    stages      = PipelineStageSerializer(many=True, read_only=True)
    deals_count = serializers.SerializerMethodField()
    total_value = serializers.SerializerMethodField()

    class Meta:
        model  = Pipeline
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def get_deals_count(self, obj):
        return obj.deals.count()

    def get_total_value(self, obj):
        from django.db.models import Sum
        return obj.deals.aggregate(v=Sum('value'))['v'] or 0

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class DealActivitySerializer(serializers.ModelSerializer):
    performed_by_name = serializers.CharField(source='performed_by.get_full_name', read_only=True)

    class Meta:
        model  = DealActivity
        fields = '__all__'
        read_only_fields = ['performed_by', 'created_at']

    def create(self, validated_data):
        validated_data['performed_by'] = self.context['request'].user
        return super().create(validated_data)


class DealSerializer(serializers.ModelSerializer):
    stage_name    = serializers.CharField(source='stage.name', read_only=True)
    pipeline_name = serializers.CharField(source='pipeline.name', read_only=True)
    contact_name  = serializers.SerializerMethodField()
    company_name  = serializers.CharField(source='company.name', read_only=True)
    owner_name    = serializers.CharField(source='owner.get_full_name', read_only=True)
    activities    = DealActivitySerializer(many=True, read_only=True)
    stage_history = serializers.SerializerMethodField()

    class Meta:
        model  = Deal
        fields = '__all__'
        read_only_fields = ['created_by', 'weighted_value', 'won_at', 'lost_at', 'created_at', 'updated_at']

    def get_contact_name(self, obj):
        return obj.contact.get_full_name() if obj.contact else None

    def get_stage_history(self, obj):
        return DealStageHistorySerializer(obj.stage_history.all()[:10], many=True).data

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class DealListSerializer(serializers.ModelSerializer):
    stage_name   = serializers.CharField(source='stage.name', read_only=True)
    pipeline_name = serializers.CharField(source='pipeline.name', read_only=True)
    contact_name = serializers.SerializerMethodField()
    company_name = serializers.CharField(source='company.name', read_only=True)
    owner_name   = serializers.CharField(source='owner.get_full_name', read_only=True)
    stage_probability = serializers.IntegerField(source='stage.probability', read_only=True)
    stage_color  = serializers.CharField(source='stage.color', read_only=True)

    class Meta:
        model  = Deal
        fields = ['id', 'title', 'pipeline', 'pipeline_name', 'stage', 'stage_name',
                  'stage_probability', 'stage_color', 'priority', 'value', 'currency',
                  'weighted_value', 'contact', 'contact_name', 'company', 'company_name',
                  'owner', 'owner_name', 'close_date', 'won_at', 'lost_at', 'tags',
                  'created_at', 'updated_at']

    def get_contact_name(self, obj):
        return obj.contact.get_full_name() if obj.contact else None


class DealStageHistorySerializer(serializers.ModelSerializer):
    from_stage_name = serializers.CharField(source='from_stage.name', read_only=True)
    to_stage_name   = serializers.CharField(source='to_stage.name', read_only=True)
    changed_by_name = serializers.CharField(source='changed_by.get_full_name', read_only=True)

    class Meta:
        model  = DealStageHistory
        fields = '__all__'
