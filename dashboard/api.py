# dashboard/api.py  (updated to include all new modules)
from rest_framework import viewsets, serializers, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Sum, Count, Avg, Q
from django.utils import timezone
from datetime import timedelta, datetime
from calendar import monthrange

from .models import DashboardWidget, DashboardPreference, KPITarget, NotificationPreference


# ── Existing model serializers (unchanged) ────────────────────────────────────

class DashboardWidgetSerializer(serializers.ModelSerializer):
    class Meta:
        model  = DashboardWidget
        fields = '__all__'


class DashboardPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model  = DashboardPreference
        fields = '__all__'


class KPITargetSerializer(serializers.ModelSerializer):
    class Meta:
        model  = KPITarget
        fields = '__all__'


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model  = NotificationPreference
        fields = '__all__'


class DashboardWidgetViewSet(viewsets.ModelViewSet):
    serializer_class   = DashboardWidgetSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return DashboardWidget.objects.filter(user=self.request.user)


class DashboardPreferenceViewSet(viewsets.ModelViewSet):
    serializer_class   = DashboardPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return DashboardPreference.objects.filter(user=self.request.user)


class KPITargetViewSet(viewsets.ModelViewSet):
    serializer_class   = KPITargetSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return KPITarget.objects.filter(user=self.request.user)


class NotificationPreferenceViewSet(viewsets.ModelViewSet):
    serializer_class   = NotificationPreferenceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return NotificationPreference.objects.filter(user=self.request.user)


# ── Enhanced Dashboard Stats ──────────────────────────────────────────────────

class DashboardStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        date_range = request.query_params.get('date_range', 'month')
        now = timezone.now()

        range_map = {
            'today':   now - timedelta(days=1),
            'week':    now - timedelta(weeks=1),
            'month':   now - timedelta(days=30),
            'quarter': now - timedelta(days=90),
            'year':    now - timedelta(days=365),
        }
        since = range_map.get(date_range, range_map['month'])

        user = request.user
        is_admin = user.role in ('admin', 'superadmin', 'sales_manager')

        from leads.models import Lead
        leads_qs = Lead.objects.all() if is_admin else Lead.objects.filter(assigned_to=user)
        leads_period = leads_qs.filter(created_at__gte=since)

        # ── Leads stats ───────────────────────────────────────────────────
        total_leads = leads_qs.count()
        new_leads = leads_qs.filter(status='new').count()
        won_leads = leads_qs.filter(status='won').count()
        lost_leads = leads_qs.filter(status='lost').count()
        overdue_leads = leads_qs.filter(
            last_contacted__lt=now - timedelta(days=7),
            status__in=['new', 'contacted', 'qualified']
        ).count()
        total_closed = won_leads + lost_leads
        conversion_rate = round(won_leads / total_closed * 100, 1) if total_closed > 0 else 0

        # ── leads_by_status & leads_by_priority (list format for Flutter parseMap) ──
        leads_by_status = list(
            leads_qs.values('status').annotate(count=Count('id')).order_by('status')
        )
        leads_by_priority = list(
            leads_qs.values('priority').annotate(count=Count('id')).order_by('priority')
        )

        # ── Contacts & Companies ──────────────────────────────────────────
        contacts_stats = {}
        try:
            from contacts.models import Contact, Company
            contacts_stats = {
                'total_contacts': Contact.objects.count(),
                'total_companies': Company.objects.count(),
                'new_contacts_period': Contact.objects.filter(created_at__gte=since).count(),
            }
        except Exception:
            pass

        # ── Deals stats ───────────────────────────────────────────────────
        deals_stats = {}
        avg_deal_size = 0
        total_revenue = 0
        try:
            from deals.models import Deal
            deals_qs   = Deal.objects.all() if is_admin else Deal.objects.filter(owner=user)
            open_deals = deals_qs.filter(stage__is_won=False, stage__is_lost=False)
            won_deals  = deals_qs.filter(stage__is_won=True).filter(won_at__gte=since)
            avg_deal_size = deals_qs.aggregate(v=Avg('value'))['v'] or 0
            total_revenue = won_deals.aggregate(v=Sum('value'))['v'] or 0
            deals_stats = {
                'total': deals_qs.count(),
                'open': open_deals.count(),
                'won_period': won_deals.count(),
                'won_value_period': won_deals.aggregate(v=Sum('value'))['v'] or 0,
                'pipeline_value': open_deals.aggregate(v=Sum('value'))['v'] or 0,
                'weighted_pipeline': open_deals.aggregate(v=Sum('weighted_value'))['v'] or 0,
                'avg_deal_size': float(avg_deal_size),
                'by_pipeline': list(
                    deals_qs.values('pipeline__name').annotate(
                        count=Count('id'), value=Sum('value')
                    ).order_by('-value')
                ),
            }
        except Exception:
            pass

        # If no deals data, try getting revenue from lead budgets
        if total_revenue == 0:
            total_revenue = leads_qs.filter(status='won').aggregate(
                total=Sum('budget')
            )['total'] or 0
        if avg_deal_size == 0:
            avg_deal_size = leads_qs.filter(status='won').aggregate(
                avg=Avg('budget')
            )['avg'] or 0

        # ── Invoice & Revenue ─────────────────────────────────────────────
        revenue_stats = {}
        try:
            from quotes.models import Invoice
            inv_qs = Invoice.objects.all()
            revenue_stats = {
                'total_invoiced': inv_qs.aggregate(v=Sum('grand_total'))['v'] or 0,
                'total_collected': inv_qs.aggregate(v=Sum('amount_paid'))['v'] or 0,
                'outstanding': inv_qs.aggregate(v=Sum('amount_due'))['v'] or 0,
                'overdue_invoices': inv_qs.filter(
                    due_date__lt=now.date(),
                    status__in=['sent', 'partial']
                ).count(),
                'period_invoiced': inv_qs.filter(created_at__gte=since).aggregate(
                    v=Sum('grand_total'))['v'] or 0,
            }
        except Exception:
            pass

        # ── Tickets stats ─────────────────────────────────────────────────
        tickets_stats = {}
        try:
            from tickets.models import Ticket
            t_qs = Ticket.objects.all()
            open_tickets = t_qs.filter(status__in=['open', 'in_progress', 'waiting'])
            tickets_stats = {
                'total': t_qs.count(),
                'open': open_tickets.count(),
                'overdue': open_tickets.filter(resolution_due__lt=now).count(),
                'resolved_period': t_qs.filter(resolved_at__gte=since).count(),
                'avg_csat': t_qs.filter(csat_score__isnull=False).aggregate(
                    a=Avg('csat_score'))['a'] or 0,
                'unassigned': open_tickets.filter(assigned_to__isnull=True).count(),
            }
        except Exception:
            pass

        # ── Tasks ─────────────────────────────────────────────────────────
        tasks_stats = {}
        try:
            from workflows.models import Task
            my_tasks = Task.objects.filter(assigned_to=user)
            tasks_stats = {
                'total': my_tasks.count(),
                'todo': my_tasks.filter(status='todo').count(),
                'overdue': my_tasks.filter(
                    due_date__lt=now, status__in=['todo', 'in_progress']).count(),
            }
        except Exception:
            pass

        # ── Users / Campaigns / Emails counts ─────────────────────────────
        total_users = 0
        total_campaigns = 0
        total_emails = 0
        try:
            from django.contrib.auth import get_user_model
            User = get_user_model()
            total_users = User.objects.filter(is_active=True).count()
        except Exception:
            pass
        try:
            from communications.models import EmailCampaign, Email
            total_campaigns = EmailCampaign.objects.count()
            total_emails = Email.objects.count()
        except Exception:
            pass

        # ── Funnel data ───────────────────────────────────────────────────
        funnel_stages = ['new', 'contacted', 'qualified', 'proposal', 'negotiation', 'won']
        funnel_data = []
        for s in funnel_stages:
            c = leads_qs.filter(status=s).count()
            funnel_data.append({
                'stage': s,
                'count': c,
                'percentage': round(c / total_leads * 100, 1) if total_leads > 0 else 0,
            })

        # ── Source performance ────────────────────────────────────────────
        source_performance_raw = list(
            leads_qs.values('source__name')
            .annotate(total=Count('id'), won=Count('id', filter=Q(status='won')))
            .order_by('-total')[:8]
        )
        source_performance = []
        for sp in source_performance_raw:
            name = sp.get('source__name') or 'Direct'
            total = sp.get('total', 0)
            won = sp.get('won', 0)
            source_performance.append({
                'source__name': name,
                'name': name,
                'total': total,
                'total_leads': total,
                'won': won,
                'won_leads': won,
                'conversion_rate': round(won / total * 100, 1) if total > 0 else 0,
            })

        # ── Monthly data (full stats for charts) ─────────────────────────
        monthly_data = self._monthly_lead_data(leads_qs, 6)

        return Response({
            'date_range': date_range,
            'leads': {
                'total': total_leads,
                'new': new_leads,
                'qualified': leads_qs.filter(status='qualified').count(),
                'won': won_leads,
                'lost': lost_leads,
                'period_count': leads_period.count(),
                'overdue': overdue_leads,
                'conversion_rate': conversion_rate,
                'by_status': leads_by_status,
                'by_source': list(leads_qs.values('source__name').annotate(
                    count=Count('id')).order_by('-count')[:8]),
                'monthly': self._monthly_counts(leads_qs, 6),
            },
            'contacts': contacts_stats,
            'deals': deals_stats,
            'revenue': revenue_stats,
            'tickets': tickets_stats,
            'tasks': tasks_stats,
            'funnel_data': funnel_data,
            'source_performance': source_performance,

            # Legacy flat fields (for Flutter DashboardStats.fromJson)
            'total_leads': total_leads,
            'new_leads': new_leads,
            'qualified_leads': leads_qs.filter(status='qualified').count(),
            'won_leads': won_leads,
            'lost_leads': lost_leads,
            'overdue_leads': overdue_leads,
            'conversion_rate': conversion_rate,
            'total_revenue': float(total_revenue),
            'avg_deal_size': float(avg_deal_size),
            'pipeline_value': deals_stats.get('pipeline_value', 0),
            'total_users': total_users,
            'total_campaigns': total_campaigns,
            'total_emails': total_emails,
            'leads_by_status': leads_by_status,
            'leads_by_priority': leads_by_priority,
            'monthly_data': monthly_data,
        })

    def _monthly_counts(self, qs, months: int) -> list:
        from django.db.models.functions import TruncMonth
        result = (
            qs.filter(created_at__gte=timezone.now() - timedelta(days=months * 30))
            .annotate(month=TruncMonth('created_at'))
            .values('month')
            .annotate(count=Count('id'))
            .order_by('month')
        )
        return [{'month': r['month'].strftime('%b %Y'), 'count': r['count']} for r in result]

    def _monthly_lead_data(self, qs, months: int) -> list:
        """Build full monthly data matching Flutter MonthlyData.fromJson format."""
        monthly_data = []
        now = timezone.now()

        for i in range(months):
            if i == 0:
                month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
                month_end = now
            else:
                year = now.year
                month = now.month - i
                if month <= 0:
                    month += 12
                    year -= 1
                month_start = datetime(year, month, 1)
                month_start = timezone.make_aware(month_start)
                last_day = monthrange(year, month)[1]
                month_end = datetime(year, month, last_day, 23, 59, 59)
                month_end = timezone.make_aware(month_end)

            month_leads = qs.filter(
                created_at__gte=month_start,
                created_at__lte=month_end
            )
            total_count = month_leads.count()
            won_count = month_leads.filter(status='won').count()
            lost_count = month_leads.filter(status='lost').count()
            revenue = month_leads.filter(status='won').aggregate(
                total=Sum('budget'))['total'] or 0

            monthly_data.append({
                'month': month_start.strftime('%B %Y'),
                'month_short': month_start.strftime('%b %Y'),
                'total': total_count,
                'won': won_count,
                'lost': lost_count,
                'conversion_rate': round(won_count / total_count * 100, 1) if total_count > 0 else 0,
                'revenue': float(revenue),
            })

        return list(reversed(monthly_data))


class ChatbotView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        message = request.data.get('message', '').strip()
        if not message:
            return Response({'error': 'Message is required'}, status=400)
            
        # Placeholder logic: return a hardcoded response.
        # This is where the real AI integration will go later.
        response_text = "I'm your AI assistant! AI features haven't been fully activated yet, but I'll be ready soon."
        
        return Response({
            'response': response_text,
            'status': 'success'
        })

