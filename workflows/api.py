# workflows/api.py
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count
from django.utils import timezone
from .models import Workflow, WorkflowCondition, WorkflowAction, WorkflowExecution, Notification, Task
from .serializers import (
    WorkflowSerializer, WorkflowConditionSerializer, WorkflowActionSerializer,
    WorkflowExecutionSerializer, NotificationSerializer, TaskSerializer,
)


class WorkflowViewSet(viewsets.ModelViewSet):
    serializer_class   = WorkflowSerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter]
    search_fields      = ['name', 'description']

    def get_queryset(self):
        qs = Workflow.objects.all()
        if self.request.query_params.get('active') == 'true':
            qs = qs.filter(is_active=True)
        if self.request.query_params.get('trigger'):
            qs = qs.filter(trigger=self.request.query_params['trigger'])
        return qs

    @action(detail=True, methods=['post'])
    def toggle_active(self, request, pk=None):
        wf = self.get_object()
        wf.is_active = not wf.is_active
        wf.save()
        return Response({'is_active': wf.is_active})

    @action(detail=True, methods=['get'])
    def executions(self, request, pk=None):
        wf = self.get_object()
        execs = wf.executions.all()[:50]
        return Response(WorkflowExecutionSerializer(execs, many=True).data)

    @action(detail=True, methods=['post'])
    def set_conditions(self, request, pk=None):
        wf = self.get_object()
        wf.conditions.all().delete()
        for cond_data in request.data.get('conditions', []):
            WorkflowCondition.objects.create(workflow=wf, **cond_data)
        return Response(WorkflowSerializer(wf, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def set_actions(self, request, pk=None):
        wf = self.get_object()
        wf.actions.all().delete()
        for action_data in request.data.get('actions', []):
            WorkflowAction.objects.create(workflow=wf, **action_data)
        return Response(WorkflowSerializer(wf, context={'request': request}).data)


class WorkflowConditionViewSet(viewsets.ModelViewSet):
    serializer_class   = WorkflowConditionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = WorkflowCondition.objects.all()
        if self.request.query_params.get('workflow'):
            qs = qs.filter(workflow_id=self.request.query_params['workflow'])
        return qs


class WorkflowActionViewSet(viewsets.ModelViewSet):
    serializer_class   = WorkflowActionSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = WorkflowAction.objects.all()
        if self.request.query_params.get('workflow'):
            qs = qs.filter(workflow_id=self.request.query_params['workflow'])
        return qs


class WorkflowExecutionViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class   = WorkflowExecutionSerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.OrderingFilter]
    ordering           = ['-started_at']

    def get_queryset(self):
        qs = WorkflowExecution.objects.select_related('workflow')
        if self.request.query_params.get('workflow'):
            qs = qs.filter(workflow_id=self.request.query_params['workflow'])
        if self.request.query_params.get('status'):
            qs = qs.filter(status=self.request.query_params['status'])
        return qs


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class   = NotificationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)

    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        Notification.objects.filter(user=request.user, is_read=False).update(is_read=True)
        return Response({'status': 'all marked read'})

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        notif = self.get_object()
        notif.is_read = True
        notif.save()
        return Response({'status': 'marked read'})

    @action(detail=False, methods=['get'])
    def unread_count(self, request):
        count = Notification.objects.filter(user=request.user, is_read=False).count()
        return Response({'count': count})


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class   = TaskSerializer
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['title', 'description']
    ordering_fields    = ['due_date', 'created_at', 'priority']
    ordering           = ['due_date']

    def get_queryset(self):
        qs = Task.objects.select_related('assigned_to', 'created_by')
        p  = self.request.query_params
        if p.get('assigned_to'):
            qs = qs.filter(assigned_to_id=p['assigned_to'])
        if p.get('my_tasks') == 'true':
            qs = qs.filter(assigned_to=self.request.user)
        if p.get('status'):
            qs = qs.filter(status=p['status'])
        if p.get('lead_id'):
            qs = qs.filter(lead_id=p['lead_id'])
        if p.get('deal_id'):
            qs = qs.filter(deal_id=p['deal_id'])
        if p.get('contact_id'):
            qs = qs.filter(contact_id=p['contact_id'])
        if p.get('ticket_id'):
            qs = qs.filter(ticket_id=p['ticket_id'])
        if p.get('overdue') == 'true':
            qs = qs.filter(due_date__lt=timezone.now(), status__in=['todo', 'in_progress'])
        return qs

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        task = self.get_object()
        task.status = 'done'
        task.completed_at = timezone.now()
        task.save()
        return Response(TaskSerializer(task).data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = Task.objects.filter(assigned_to=request.user)
        return Response({
            'total': qs.count(),
            'todo': qs.filter(status='todo').count(),
            'in_progress': qs.filter(status='in_progress').count(),
            'done': qs.filter(status='done').count(),
            'overdue': qs.filter(due_date__lt=timezone.now(), status__in=['todo','in_progress']).count(),
        })
