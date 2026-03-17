# tickets/api.py
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Avg, Q
from django.utils import timezone
from .models import TicketCategory, SLAPolicy, Ticket, TicketReply, TicketActivity
from .serializers import (
    TicketCategorySerializer, SLAPolicySerializer,
    TicketSerializer, TicketListSerializer,
    TicketReplySerializer,
    TicketActivitySerializer,
)


class TicketCategoryViewSet(viewsets.ModelViewSet):
    queryset           = TicketCategory.objects.filter(is_active=True)
    serializer_class   = TicketCategorySerializer
    permission_classes = [IsAuthenticated]


class SLAPolicyViewSet(viewsets.ModelViewSet):
    queryset           = SLAPolicy.objects.filter(is_active=True)
    serializer_class   = SLAPolicySerializer
    permission_classes = [IsAuthenticated]


class TicketViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['ticket_number', 'subject', 'description',
                          'contact__first_name', 'contact__last_name',
                          'company__name']
    ordering_fields    = ['created_at', 'updated_at', 'priority', 'status', 'resolution_due']
    ordering           = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return TicketListSerializer
        return TicketSerializer

    def get_queryset(self):
        qs = Ticket.objects.select_related(
            'contact', 'company', 'category', 'sla_policy',
            'assigned_to', 'created_by'
        )
        p = self.request.query_params
        if p.get('status'):
            qs = qs.filter(status=p['status'])
        if p.get('priority'):
            qs = qs.filter(priority=p['priority'])
        if p.get('assigned_to'):
            qs = qs.filter(assigned_to_id=p['assigned_to'])
        if p.get('category'):
            qs = qs.filter(category_id=p['category'])
        if p.get('overdue') == 'true':
            qs = qs.filter(
                resolution_due__lt=timezone.now(),
                status__in=['open', 'in_progress', 'waiting']
            )
        if p.get('unassigned') == 'true':
            qs = qs.filter(assigned_to__isnull=True)
        if p.get('my_tickets') == 'true':
            qs = qs.filter(assigned_to=self.request.user)
        if p.get('contact'):
            qs = qs.filter(contact_id=p['contact'])
        return qs

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        old_status = instance.status
        old_priority = instance.priority
        old_assigned = instance.assigned_to_id

        response = super().update(request, *args, **kwargs)
        instance.refresh_from_db()

        # Log changes
        if old_status != instance.status:
            TicketActivity.objects.create(
                ticket=instance, action='status_changed',
                description=f'Status changed from {old_status} to {instance.status}',
                old_value=old_status, new_value=instance.status,
                performed_by=request.user
            )
        if old_priority != instance.priority:
            TicketActivity.objects.create(
                ticket=instance, action='priority_changed',
                description=f'Priority changed from {old_priority} to {instance.priority}',
                old_value=old_priority, new_value=instance.priority,
                performed_by=request.user
            )
        if old_assigned != instance.assigned_to_id:
            TicketActivity.objects.create(
                ticket=instance, action='assigned',
                description=f'Assigned to {instance.assigned_to.get_full_name() if instance.assigned_to else "Unassigned"}',
                new_value=str(instance.assigned_to_id),
                performed_by=request.user
            )
        return response

    @action(detail=True, methods=['post'])
    def reply(self, request, pk=None):
        ticket = self.get_object()
        serializer = TicketReplySerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        reply = serializer.save(ticket=ticket)
        TicketActivity.objects.create(
            ticket=ticket,
            action='replied' if reply.is_public else 'note_added',
            description=f'{"Reply sent" if reply.is_public else "Internal note added"}',
            performed_by=request.user
        )
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def resolve(self, request, pk=None):
        ticket = self.get_object()
        ticket.status = 'resolved'
        ticket.resolved_at = timezone.now()
        ticket.save()
        TicketActivity.objects.create(
            ticket=ticket, action='resolved',
            description='Ticket resolved', performed_by=request.user
        )
        return Response(TicketSerializer(ticket, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def reopen(self, request, pk=None):
        ticket = self.get_object()
        ticket.status = 'open'
        ticket.resolved_at = None
        ticket.save()
        TicketActivity.objects.create(
            ticket=ticket, action='reopened',
            description='Ticket reopened', performed_by=request.user
        )
        return Response(TicketSerializer(ticket, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def csat(self, request, pk=None):
        """Record CSAT feedback"""
        ticket = self.get_object()
        score = request.data.get('score')
        comment = request.data.get('comment', '')
        if not score or int(score) not in range(1, 6):
            return Response({'error': 'score must be 1-5'}, status=status.HTTP_400_BAD_REQUEST)
        ticket.csat_score = int(score)
        ticket.csat_comment = comment
        ticket.csat_received_at = timezone.now()
        ticket.save()
        TicketActivity.objects.create(
            ticket=ticket, action='csat_received',
            description=f'CSAT score: {score}/5',
            new_value=str(score), performed_by=request.user
        )
        return Response({'status': 'csat recorded', 'score': score})

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = Ticket.objects.all()
        now = timezone.now()
        open_qs = qs.filter(status__in=['open', 'in_progress', 'waiting'])
        return Response({
            'total': qs.count(),
            'open': open_qs.count(),
            'in_progress': qs.filter(status='in_progress').count(),
            'resolved': qs.filter(status='resolved').count(),
            'closed': qs.filter(status='closed').count(),
            'overdue': open_qs.filter(resolution_due__lt=now).count(),
            'response_overdue': open_qs.filter(
                first_response_due__lt=now, first_response_at__isnull=True).count(),
            'unassigned': open_qs.filter(assigned_to__isnull=True).count(),
            'avg_csat': qs.filter(csat_score__isnull=False).aggregate(a=Avg('csat_score'))['a'] or 0,
            'by_priority': {
                'critical': open_qs.filter(priority='critical').count(),
                'high': open_qs.filter(priority='high').count(),
                'medium': open_qs.filter(priority='medium').count(),
                'low': open_qs.filter(priority='low').count(),
            },
            'by_channel': list(
                qs.values('channel').annotate(count=Count('id')).order_by('-count')
            ),
        })


class TicketReplyViewSet(viewsets.ModelViewSet):
    serializer_class   = TicketReplySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = TicketReply.objects.select_related('ticket', 'author')
        if self.request.query_params.get('ticket'):
            qs = qs.filter(ticket_id=self.request.query_params['ticket'])
        return qs
