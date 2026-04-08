# integrations/api.py  (django-tenants version — no tenant FK, no WhatsAppLog)
from rest_framework import viewsets, serializers, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Integration, WhatsAppTemplate, LeadImportLog
from .services import GeminiService


# ── Serializers ───────────────────────────────────────────────────────────────

class IntegrationSerializer(serializers.ModelSerializer):
    # Write-only helpers used by the frontend form
    api_key = serializers.CharField(write_only=True, required=False, allow_blank=True)
    api_secret = serializers.CharField(write_only=True, required=False, allow_blank=True)
    extra = serializers.CharField(write_only=True, required=False, allow_blank=True)
    is_enabled = serializers.BooleanField(required=False)

    # Expose webhook URLs for IndiaMART & Meta (read-only convenience)
    webhook_url = serializers.SerializerMethodField()

    class Meta:
        model = Integration
        fields = [
            'id', 'service', 'display_name', 'status', 'is_active', 'is_enabled',
            'credentials', 'config', 'last_sync', 'last_error', 'sync_count',
            'error_count', 'created_by', 'created_at', 'updated_at',
            'api_key', 'api_secret', 'extra', 'webhook_url',
        ]
        read_only_fields = ['credentials', 'config', 'created_by', 'created_at', 'updated_at']

    def get_webhook_url(self, obj):
        """Return the webhook URL for services that use webhooks."""
        request = self.context.get('request')
        if not request:
            return None

        # Get tenant slug from the current tenant
        from django.db import connection
        tenant = getattr(connection, 'tenant', None)
        if not tenant or not hasattr(tenant, 'slug'):
            return None

        base = request.build_absolute_uri('/').rstrip('/')

        if obj.service == Integration.SERVICE_INDIAMART:
            return f"{base}/api/webhooks/indiamart/{tenant.slug}/"
        elif obj.service == Integration.SERVICE_META_LEADS:
            return f"{base}/api/webhooks/meta-leads/{tenant.slug}/"
        return None

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # Keep frontend compatibility while hiding secrets
        data['is_enabled'] = instance.is_active
        data.pop('credentials', None)

        # For IndiaMART/Meta — show config keys (not secrets) so frontend can display them
        if instance.service in (Integration.SERVICE_INDIAMART, Integration.SERVICE_META_LEADS):
            config = instance.config or {}
            data['config_display'] = {
                k: v for k, v in config.items()
                if k not in ('app_secret',)  # hide secrets
            }
            data['has_api_key'] = bool(instance.api_key)
        return data

    def _apply_credentials(self, instance, validated_data):
        creds = dict(instance.credentials or {})
        api_key = validated_data.pop('api_key', None)
        api_secret = validated_data.pop('api_secret', None)
        extra = validated_data.pop('extra', None)
        if api_key:
            creds['api_key'] = api_key
        if api_secret:
            creds['api_secret'] = api_secret
        if extra:
            cfg = dict(instance.config or {})
            if instance.service == 'whatsapp':
                cfg['phone_number_id'] = extra
            elif instance.service == Integration.SERVICE_META_LEADS:
                # For Meta: extra can be JSON with verify_token, page_id, app_secret
                import json
                try:
                    extra_data = json.loads(extra)
                    cfg.update(extra_data)
                except (json.JSONDecodeError, TypeError):
                    cfg['page_id'] = extra
            elif instance.service == Integration.SERVICE_INDIAMART:
                # For IndiaMART: extra can hold additional config
                cfg['extra'] = extra
            else:
                cfg['extra'] = extra
            instance.config = cfg
        if creds:
            instance.credentials = creds

    def create(self, validated_data):
        is_enabled = validated_data.pop('is_enabled', None)
        # Remove non-model fields before creating instance
        api_key = validated_data.pop('api_key', None)
        api_secret = validated_data.pop('api_secret', None)
        extra = validated_data.pop('extra', None)
        instance = Integration.objects.create(**validated_data)
        # Re-attach temp fields for helper
        validated_data['api_key'] = api_key
        validated_data['api_secret'] = api_secret
        validated_data['extra'] = extra
        if is_enabled is not None:
            instance.is_active = bool(is_enabled)
            instance.status = 'active' if instance.is_active else 'inactive'
        self._apply_credentials(instance, validated_data)
        instance.save()
        return instance

    def update(self, instance, validated_data):
        is_enabled = validated_data.pop('is_enabled', None)
        api_key = validated_data.pop('api_key', None)
        api_secret = validated_data.pop('api_secret', None)
        extra = validated_data.pop('extra', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if is_enabled is not None:
            instance.is_active = bool(is_enabled)
            instance.status = 'active' if instance.is_active else 'inactive'
        validated_data['api_key'] = api_key
        validated_data['api_secret'] = api_secret
        validated_data['extra'] = extra
        self._apply_credentials(instance, validated_data)
        instance.save()
        return instance


class WATemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = WhatsAppTemplate
        fields = '__all__'


class LeadImportLogSerializer(serializers.ModelSerializer):
    source_display = serializers.CharField(source='get_source_display', read_only=True)
    method_display = serializers.CharField(source='get_method_display', read_only=True)

    class Meta:
        model = LeadImportLog
        fields = [
            'id', 'source', 'source_display', 'method', 'method_display',
            'leads_received', 'leads_created', 'leads_skipped',
            'error_message', 'created_at',
        ]
        read_only_fields = fields


# ── Permissions ───────────────────────────────────────────────────────────────

class IsTenantAdminOrReadOnly(permissions.BasePermission):
    """
    Allow any authenticated user to READ integrations,
    but only tenant_admin / superadmin can CREATE, UPDATE, DELETE,
    or trigger sensitive actions (toggle, test, sync_leads).
    """
    ADMIN_ROLES = ('superadmin', 'admin', 'tenant_admin')

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        # Safe methods (GET, HEAD, OPTIONS) — any authenticated user
        if request.method in permissions.SAFE_METHODS:
            return True
        # Write methods — tenant admin or superadmin only
        return getattr(request.user, 'role', '') in self.ADMIN_ROLES


# ── ViewSets ──────────────────────────────────────────────────────────────────

class IntegrationViewSet(viewsets.ModelViewSet):
    """
    Manages per-tenant integration configs. Schema isolation ensures privacy.

    Permissions:
      - GET (list/detail): any authenticated user in the tenant
      - POST/PUT/PATCH/DELETE + toggle/test/sync: tenant_admin or superadmin only
    """
    serializer_class = IntegrationSerializer
    permission_classes = [permissions.IsAuthenticated, IsTenantAdminOrReadOnly]

    def get_queryset(self):
        return Integration.objects.all()

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def toggle(self, request, pk=None):
        intg = self.get_object()
        intg.status = 'active' if intg.status != 'active' else 'inactive'
        intg.is_active = intg.status == 'active'
        intg.save(update_fields=['status', 'is_active'])
        return Response({'status': intg.status, 'is_active': intg.is_active})

    @action(detail=True, methods=['post'])
    def test(self, request, pk=None):
        intg = self.get_object()

        if intg.service == Integration.SERVICE_GEMINI:
            if not intg.api_key:
                return Response({'success': False, 'message': 'API key not set.'},
                                status=status.HTTP_400_BAD_REQUEST)
            svc = GeminiService(intg.api_key)
            reply = svc.chat(history=[], message='Ping', crm_context='')
            ok = bool(reply)
            return Response({
                'success': ok,
                'message': 'Connection OK!' if ok else 'Test failed',
            })

        elif intg.service == Integration.SERVICE_INDIAMART:
            if not intg.api_key:
                return Response({'success': False, 'message': 'IndiaMART CRM key not set.'},
                                status=status.HTTP_400_BAD_REQUEST)
            from .services import IndiaMartService
            svc = IndiaMartService(intg)
            result = svc.pull_leads()
            if result['success']:
                return Response({
                    'success': True,
                    'message': f"Connection OK! Found {result['total']} recent leads.",
                })
            return Response({
                'success': False,
                'message': f"Connection failed: {result['error']}",
            }, status=status.HTTP_400_BAD_REQUEST)

        elif intg.service == Integration.SERVICE_META_LEADS:
            if not intg.api_key:
                return Response({'success': False, 'message': 'Page access token not set.'},
                                status=status.HTTP_400_BAD_REQUEST)
            # Test by calling Graph API /me endpoint
            import requests as req
            try:
                r = req.get(
                    'https://graph.facebook.com/v19.0/me',
                    params={'access_token': intg.api_key},
                    timeout=10
                )
                if r.ok:
                    data = r.json()
                    return Response({
                        'success': True,
                        'message': f"Connected to page: {data.get('name', 'Unknown')}",
                    })
                return Response({
                    'success': False,
                    'message': f"Connection failed: {r.json().get('error', {}).get('message', 'Unknown error')}",
                }, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response({
                    'success': False,
                    'message': f"Connection failed: {str(e)}",
                }, status=status.HTTP_400_BAD_REQUEST)

        return Response({'success': True, 'message': 'Connection OK!'})

    @action(detail=True, methods=['post'])
    def sync_leads(self, request, pk=None):
        """
        Manual sync trigger for IndiaMART or Meta Lead Ads.
        Pulls leads immediately rather than waiting for Celery schedule.
        """
        intg = self.get_object()

        if intg.service == Integration.SERVICE_INDIAMART:
            if not intg.api_key:
                return Response({'error': 'IndiaMART CRM key not configured'},
                                status=status.HTTP_400_BAD_REQUEST)
            from .services import IndiaMartService
            svc = IndiaMartService(intg)

            # Allow custom time range from request
            start_time = request.data.get('start_time')
            end_time = request.data.get('end_time')

            result = svc.pull_leads(start_time=start_time, end_time=end_time)
            if not result['success']:
                return Response({
                    'error': result['error'],
                    'leads_found': 0,
                }, status=status.HTTP_400_BAD_REQUEST)

            if result['leads']:
                import_result = svc.import_leads(
                    result['leads'],
                    method='manual',
                    created_by=request.user,
                )
                return Response({
                    'success': True,
                    'message': (f"Synced {import_result['leads_created']} leads "
                                f"({import_result['leads_skipped']} skipped)"),
                    **import_result,
                })
            return Response({
                'success': True,
                'message': 'No new leads found.',
                'leads_received': 0,
                'leads_created': 0,
                'leads_skipped': 0,
            })

        elif intg.service == Integration.SERVICE_META_LEADS:
            # For Meta, trigger the catchup task synchronously
            if not intg.api_key:
                return Response({'error': 'Page access token not configured'},
                                status=status.HTTP_400_BAD_REQUEST)
            page_id = (intg.config or {}).get('page_id', '')
            if not page_id:
                return Response({'error': 'Facebook Page ID not configured'},
                                status=status.HTTP_400_BAD_REQUEST)

            # Run catchup inline
            from .services import MetaLeadAdsService
            import requests as req

            svc = MetaLeadAdsService(intg)
            url = f"{svc.GRAPH_API_BASE}/{page_id}/leadgen_forms"
            params = {
                'access_token': svc.page_access_token,
                'fields': 'id,name,leads.limit(50){created_time,id,field_data}',
            }

            try:
                r = req.get(url, params=params, timeout=30)
                r.raise_for_status()
                forms_data = r.json()

                total_created = 0
                total_skipped = 0

                for form in forms_data.get('data', []):
                    leads_data = form.get('leads', {}).get('data', [])
                    for meta_lead in leads_data:
                        entry = {'changes': [{'field': 'leadgen', 'value': {
                            'leadgen_id': meta_lead.get('id'),
                        }}]}
                        result = svc.process_webhook_entry(entry, created_by=request.user)
                        total_created += result.get('leads_created', 0)
                        total_skipped += result.get('leads_skipped', 0)

                return Response({
                    'success': True,
                    'message': f"Synced {total_created} leads ({total_skipped} skipped)",
                    'leads_created': total_created,
                    'leads_skipped': total_skipped,
                })
            except Exception as e:
                return Response({
                    'error': f"Meta API error: {str(e)}",
                }, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            'error': f'Sync not supported for {intg.get_service_display()}',
        }, status=status.HTTP_400_BAD_REQUEST)


class WATemplateViewSet(viewsets.ModelViewSet):
    """Manages WhatsApp message templates. Schema isolation ensures privacy."""
    serializer_class = WATemplateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return WhatsAppTemplate.objects.all()


class WALogViewSet(viewsets.ReadOnlyModelViewSet):
    """Stub — WALog removed from models; returns empty queryset."""
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        from django.db.models.query import QuerySet
        return Integration.objects.none()

    def list(self, request, *args, **kwargs):
        return Response([])

    def retrieve(self, request, *args, **kwargs):
        return Response({'detail': 'Not found.'}, status=404)


class LeadImportLogViewSet(viewsets.ReadOnlyModelViewSet):
    """Read-only view of lead import history. Schema isolation ensures privacy."""
    serializer_class = LeadImportLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = LeadImportLog.objects.all()
        source = self.request.query_params.get('source')
        if source:
            qs = qs.filter(source=source)
        return qs


class AIViewSet(viewsets.ViewSet):
    """General AI endpoints. Reads from DB Integration record for API keys."""
    permission_classes = [permissions.IsAuthenticated]

    def _get_gemini(self):
        try:
            intg = Integration.objects.get(
                service=Integration.SERVICE_GEMINI,
                is_active=True,
            )
            if not intg.api_key:
                return None, Response(
                    {'message': 'Gemini API key not configured.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            return GeminiService(intg.api_key), None
        except Integration.DoesNotExist:
            return None, Response(
                {'message': 'Gemini integration not configured.'},
                status=status.HTTP_400_BAD_REQUEST
            )

    @action(detail=False, methods=['post'])
    def score_lead(self, request):
        svc, err = self._get_gemini()
        if err:
            return err
        lead_data = request.data.get('lead') or request.data
        result = svc.score_lead(lead_data)
        return Response(result)

    @action(detail=False, methods=['post'])
    def draft_email(self, request):
        svc, err = self._get_gemini()
        if err:
            return err
        to_name = request.data.get('to_name') or request.data.get('name') or 'there'
        context = request.data.get('context') or ''
        tone = request.data.get('tone') or 'professional'
        result = svc.draft_email(to_name=to_name, context=context, tone=tone)
        return Response(result)

    @action(detail=False, methods=['post'])
    def marketing_copy(self, request):
        svc, err = self._get_gemini()
        if err:
            return err
        product = request.data.get('product') or request.data.get('topic') or ''
        target = request.data.get('target') or request.data.get('audience') or ''
        style = request.data.get('style') or 'short'
        text = svc.marketing_copy(product=product, target=target, style=style)
        return Response({'text': text})

    @action(detail=False, methods=['post'])
    def chat(self, request):
        svc, err = self._get_gemini()
        if err:
            return err
        history = request.data.get('history') or []
        message = request.data.get('message') or request.data.get('prompt') or ''
        crm_context = request.data.get('crm_context') or ''
        reply = svc.chat(history=history, message=message, crm_context=crm_context)
        return Response({'reply': reply})

    @action(detail=False, methods=['post'])
    def translate(self, request):
        return Response({'message': 'Translation not configured yet.'},
                        status=status.HTTP_501_NOT_IMPLEMENTED)

    @action(detail=False, methods=['post'])
    def bulk_score_leads(self, request):
        return Response({'message': 'Bulk scoring not configured yet.'},
                        status=status.HTTP_501_NOT_IMPLEMENTED)
