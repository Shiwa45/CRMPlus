# workflows/serializers.py
from rest_framework import serializers
from .models import Workflow, WorkflowCondition, WorkflowAction, WorkflowExecution, Notification, Task


class WorkflowConditionSerializer(serializers.ModelSerializer):
    class Meta:
        model  = WorkflowCondition
        fields = '__all__'


class WorkflowActionSerializer(serializers.ModelSerializer):
    class Meta:
        model  = WorkflowAction
        fields = '__all__'


class WorkflowSerializer(serializers.ModelSerializer):
    conditions    = WorkflowConditionSerializer(many=True, read_only=True)
    actions       = WorkflowActionSerializer(many=True, read_only=True)
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model  = Workflow
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at', 'last_run_at', 'run_count']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)


class WorkflowExecutionSerializer(serializers.ModelSerializer):
    workflow_name = serializers.CharField(source='workflow.name', read_only=True)

    class Meta:
        model  = WorkflowExecution
        fields = '__all__'


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model  = Notification
        fields = '__all__'
        read_only_fields = ['user', 'created_at']


class TaskSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.CharField(source='assigned_to.get_full_name', read_only=True)
    created_by_name  = serializers.CharField(source='created_by.get_full_name', read_only=True)
    is_overdue       = serializers.BooleanField(read_only=True)

    class Meta:
        model  = Task
        fields = '__all__'
        read_only_fields = ['created_by', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['created_by'] = self.context['request'].user
        return super().create(validated_data)
