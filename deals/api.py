# deals/api.py
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Sum, Count, Avg, Q
from django.utils import timezone
from .models import Pipeline, PipelineStage, Deal, DealActivity, DealStageHistory
from .serializers import (
    PipelineSerializer, PipelineStageSerializer,
    DealSerializer, DealListSerializer, DealActivitySerializer,
    DealStageHistorySerializer
)


class PipelineViewSet(viewsets.ModelViewSet):
    serializer_class   = PipelineSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Pipeline.objects.filter(is_active=True).prefetch_related('stages')

    @action(detail=True, methods=['get'])
    def kanban(self, request, pk=None):
        """Return pipeline with deals grouped by stage for Kanban board"""
        pipeline = self.get_object()
        stages   = pipeline.stages.all()
        result   = []
        for stage in stages:
            deals = Deal.objects.filter(stage=stage).select_related(
                'contact', 'company', 'owner'
            ).order_by('-updated_at')
            result.append({
                'stage': PipelineStageSerializer(stage).data,
                'deals': DealListSerializer(deals, many=True).data,
                'total_value': deals.aggregate(v=Sum('value'))['v'] or 0,
                'count': deals.count(),
            })
        return Response(result)


class PipelineStageViewSet(viewsets.ModelViewSet):
    serializer_class   = PipelineStageSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = PipelineStage.objects.all()
        if self.request.query_params.get('pipeline'):
            qs = qs.filter(pipeline_id=self.request.query_params['pipeline'])
        return qs


class DealViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    filter_backends    = [filters.SearchFilter, filters.OrderingFilter]
    search_fields      = ['title', 'contact__first_name', 'contact__last_name', 'company__name']
    ordering_fields    = ['value', 'close_date', 'created_at', 'updated_at']
    ordering           = ['-updated_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return DealListSerializer
        return DealSerializer

    def get_queryset(self):
        qs = Deal.objects.select_related('pipeline', 'stage', 'contact', 'company', 'owner', 'created_by')
        p  = self.request.query_params
        if p.get('pipeline'):
            qs = qs.filter(pipeline_id=p['pipeline'])
        if p.get('stage'):
            qs = qs.filter(stage_id=p['stage'])
        if p.get('owner'):
            qs = qs.filter(owner_id=p['owner'])
        if p.get('priority'):
            qs = qs.filter(priority=p['priority'])
        if p.get('status') == 'won':
            qs = qs.filter(stage__is_won=True)
        elif p.get('status') == 'lost':
            qs = qs.filter(stage__is_lost=True)
        elif p.get('status') == 'open':
            qs = qs.filter(stage__is_won=False, stage__is_lost=False)
        return qs

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        old_stage = instance.stage_id
        response = super().update(request, *args, **kwargs)
        new_stage = instance.stage_id
        if old_stage != new_stage:
            DealStageHistory.objects.create(
                deal=instance,
                from_stage_id=old_stage,
                to_stage=instance.stage,
                changed_by=request.user,
            )
        return response

    @action(detail=True, methods=['post'])
    def move_stage(self, request, pk=None):
        deal = self.get_object()
        stage_id = request.data.get('stage_id')
        if not stage_id:
            return Response({'error': 'stage_id required'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            new_stage = PipelineStage.objects.get(id=stage_id, pipeline=deal.pipeline)
        except PipelineStage.DoesNotExist:
            return Response({'error': 'Stage not found in this pipeline'}, status=status.HTTP_404_NOT_FOUND)
        old_stage = deal.stage
        deal.stage = new_stage
        deal.save()
        DealStageHistory.objects.create(
            deal=deal, from_stage=old_stage, to_stage=new_stage, changed_by=request.user
        )
        return Response(DealSerializer(deal, context={'request': request}).data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        qs = Deal.objects.all()
        won = qs.filter(stage__is_won=True)
        lost = qs.filter(stage__is_lost=True)
        open_deals = qs.filter(stage__is_won=False, stage__is_lost=False)
        return Response({
            'total': qs.count(),
            'open': open_deals.count(),
            'won': won.count(),
            'lost': lost.count(),
            'total_value': qs.aggregate(v=Sum('value'))['v'] or 0,
            'won_value': won.aggregate(v=Sum('value'))['v'] or 0,
            'open_value': open_deals.aggregate(v=Sum('value'))['v'] or 0,
            'weighted_pipeline': open_deals.aggregate(v=Sum('weighted_value'))['v'] or 0,
            'avg_deal_size': qs.aggregate(v=Avg('value'))['v'] or 0,
            'win_rate': round((won.count() / max(won.count() + lost.count(), 1)) * 100, 1),
        })


class DealActivityViewSet(viewsets.ModelViewSet):
    serializer_class   = DealActivitySerializer
    permission_classes = [IsAuthenticated]
    ordering           = ['-performed_at']

    def get_queryset(self):
        qs = DealActivity.objects.select_related('deal', 'performed_by')
        if self.request.query_params.get('deal'):
            qs = qs.filter(deal_id=self.request.query_params['deal'])
        return qs
