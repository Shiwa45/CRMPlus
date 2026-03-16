# integrations/api.py
from rest_framework import viewsets, serializers, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import Integration, WhatsAppTemplate, WhatsAppLog
from .services import WhatsAppService, GeminiService, SarvamService
from tenants.models import Tenant


def _get_tenant(request):
    tid = request.headers.get('X-Tenant-ID') or request.query_params.get('tenant')
    if not tid:
        return None
    try:
        return Tenant.objects.get(id=tid)
    except Tenant.DoesNotExist:
        return None


# ── Serializers ───────────────────────────────────────────────────────────────
class IntegrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Integration
        fields = '__all__'
        extra_kwargs = {'api_key': {'write_only': True}, 'api_secret': {'write_only': True}}


class IntegrationReadSerializer(serializers.ModelSerializer):
    """Returned to client — hides keys, shows masked version."""
    api_key_masked = serializers.SerializerMethodField()

    class Meta:
        model = Integration
        exclude = ['api_key', 'api_secret']

    def get_api_key_masked(self, obj):
        if not obj.api_key:
            return ''
        k = obj.api_key
        return k[:4] + '****' + k[-4:] if len(k) > 8 else '****'


class WATemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = WhatsAppTemplate
        fields = '__all__'


class WALogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WhatsAppLog
        fields = '__all__'


# ── ViewSets ──────────────────────────────────────────────────────────────────
class IntegrationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method in ('POST', 'PUT', 'PATCH'):
            return IntegrationSerializer
        return IntegrationReadSerializer

    def get_queryset(self):
        tenant = _get_tenant(self.request)
        if not tenant:
            return Integration.objects.none()
        return Integration.objects.filter(tenant=tenant)

    def perform_create(self, serializer):
        tenant = _get_tenant(self.request)
        serializer.save(tenant=tenant, created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def test(self, request, pk=None):
        intg = self.get_object()
        result = {'success': False, 'message': 'Unknown service'}
        if intg.service == Integration.SERVICE_WHATSAPP:
            svc = WhatsAppService(intg)
            # Just verify token exists
            result = {'success': bool(intg.api_key), 'message': 'WhatsApp key stored'}
        elif intg.service == Integration.SERVICE_GEMINI:
            svc = GeminiService(intg.api_key)
            txt = svc.generate('Say "CRM test OK" only.')
            result = {'success': bool(txt), 'message': txt or 'No response from Gemini'}
        elif intg.service == Integration.SERVICE_SARVAM:
            result = {'success': bool(intg.api_key), 'message': 'Sarvam key stored'}
        intg.last_tested = timezone.now()
        intg.test_ok = result['success']
        intg.save(update_fields=['last_tested', 'test_ok'])
        return Response(result)

    @action(detail=True, methods=['post'])
    def toggle(self, request, pk=None):
        intg = self.get_object()
        intg.is_enabled = not intg.is_enabled
        intg.save(update_fields=['is_enabled'])
        return Response({'is_enabled': intg.is_enabled})


class WATemplateViewSet(viewsets.ModelViewSet):
    serializer_class = WATemplateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        tenant = _get_tenant(self.request)
        if not tenant:
            return WhatsAppTemplate.objects.none()
        return WhatsAppTemplate.objects.filter(tenant=tenant)

    def perform_create(self, serializer):
        tenant = _get_tenant(self.request)
        serializer.save(tenant=tenant, created_by=self.request.user)

    @action(detail=False, methods=['post'])
    def send_to_lead(self, request):
        """
        One-click WhatsApp send to a lead.
        Body: { template_id, lead_id }
        """
        tenant = _get_tenant(request)
        if not tenant:
            return Response({'error': 'Tenant required'}, status=400)
        if not tenant.has_feature('whatsapp'):
            return Response({'error': 'WhatsApp not available on your plan'}, status=403)
        if not tenant.within_limit('whatsapp'):
            return Response({'error': 'Monthly WhatsApp limit reached'}, status=429)

        template_id = request.data.get('template_id')
        lead_id = request.data.get('lead_id')
        custom_vars = request.data.get('variables', {})

        try:
            template = WhatsAppTemplate.objects.get(id=template_id, tenant=tenant)
        except WhatsAppTemplate.DoesNotExist:
            return Response({'error': 'Template not found'}, status=404)

        from leads.models import Lead
        try:
            lead = Lead.objects.get(id=lead_id)
        except Lead.DoesNotExist:
            return Response({'error': 'Lead not found'}, status=404)

        # Build context from lead + any custom overrides
        ctx = {
            'name': lead.get_full_name(),
            'first_name': lead.first_name,
            'last_name': lead.last_name,
            'company': lead.company or '',
            'phone': lead.phone or '',
            'email': lead.email,
            'lead_status': lead.status,
            'budget': str(lead.budget or ''),
            **custom_vars,
        }
        rendered = template.render(ctx)

        phone = (lead.phone or '').replace(' ', '').replace('-', '').replace('+', '')
        if phone.startswith('0'):
            phone = '91' + phone[1:]
        elif not phone.startswith('91') and len(phone) == 10:
            phone = '91' + phone

        try:
            intg = Integration.objects.get(tenant=tenant, service='whatsapp', is_enabled=True)
            svc = WhatsAppService(intg)
            result = svc.send_text(phone, rendered)
        except Integration.DoesNotExist:
            result = {'success': False, 'error': 'WhatsApp not configured'}

        log = WhatsAppLog.objects.create(
            tenant=tenant, template=template, to_phone=phone,
            to_name=lead.get_full_name(), message=rendered,
            status='sent' if result.get('success') else 'failed',
            error=result.get('error', ''),
            sent_by=request.user, lead_id=lead_id,
        )
        if result.get('success'):
            tenant.wa_sent += 1
            tenant.save(update_fields=['wa_sent'])

        return Response({
            'success': result.get('success', False),
            'message': rendered,
            'phone': phone,
            'log_id': log.id,
            'error': result.get('error', ''),
        })

    @action(detail=False, methods=['post'])
    def preview(self, request):
        """Preview a rendered template without sending."""
        tenant = _get_tenant(request)
        template_id = request.data.get('template_id')
        variables = request.data.get('variables', {})
        try:
            template = WhatsAppTemplate.objects.get(id=template_id, tenant=tenant)
            rendered = template.render(variables)
            return Response({'preview': rendered, 'variables': template.variables})
        except WhatsAppTemplate.DoesNotExist:
            return Response({'error': 'Template not found'}, status=404)


class WALogViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = WALogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        tenant = _get_tenant(self.request)
        if not tenant:
            return WhatsAppLog.objects.none()
        qs = WhatsAppLog.objects.filter(tenant=tenant)
        lead_id = self.request.query_params.get('lead_id')
        if lead_id:
            qs = qs.filter(lead_id=lead_id)
        return qs


# ── AI ViewSet ────────────────────────────────────────────────────────────────
class AIViewSet(viewsets.ViewSet):
    """General AI endpoints powered by Gemini + Sarvam."""
    permission_classes = [permissions.IsAuthenticated]

    def _gemini(self, request):
        tenant = _get_tenant(request)
        if not tenant or not tenant.has_feature('ai_assistant'):
            return None, Response({'error': 'AI not available on your plan'}, status=403)
        try:
            intg = Integration.objects.get(tenant=tenant, service='gemini', is_enabled=True)
            return GeminiService(intg.api_key), None
        except Integration.DoesNotExist:
            return None, Response({'error': 'Gemini not configured'}, status=400)

    @action(detail=False, methods=['post'])
    def score_lead(self, request):
        svc, err = self._gemini(request)
        if err:
            return err
        lead_id = request.data.get('lead_id')
        if lead_id:
            from leads.models import Lead
            try:
                lead = Lead.objects.get(id=lead_id)
                data = {
                    'name': lead.get_full_name(), 'company': lead.company,
                    'status': lead.status, 'priority': lead.priority,
                    'budget': str(lead.budget or ''), 'source': str(lead.source or ''),
                    'requirements': lead.requirements or '',
                }
            except Lead.DoesNotExist:
                data = request.data.get('lead_data', {})
        else:
            data = request.data.get('lead_data', {})
        result = svc.score_lead(data)
        return Response(result)

    @action(detail=False, methods=['post'])
    def draft_email(self, request):
        svc, err = self._gemini(request)
        if err:
            return err
        result = svc.draft_email(
            request.data.get('to_name', ''),
            request.data.get('context', ''),
            request.data.get('tone', 'professional'),
        )
        return Response(result)

    @action(detail=False, methods=['post'])
    def marketing_copy(self, request):
        svc, err = self._gemini(request)
        if err:
            return err
        copy = svc.marketing_copy(
            request.data.get('product', ''),
            request.data.get('target_audience', 'Indian SMBs'),
            request.data.get('style', 'persuasive'),
        )
        return Response({'copy': copy})

    @action(detail=False, methods=['post'])
    def chat(self, request):
        svc, err = self._gemini(request)
        if err:
            return err
        reply = svc.chat(
            request.data.get('history', []),
            request.data.get('message', ''),
            request.data.get('crm_context', ''),
        )
        return Response({'reply': reply})

    @action(detail=False, methods=['post'])
    def translate(self, request):
        tenant = _get_tenant(request)
        if not tenant:
            return Response({'error': 'Tenant required'}, status=400)
        try:
            intg = Integration.objects.get(tenant=tenant, service='sarvam', is_enabled=True)
            svc = SarvamService(intg.api_key)
            translated = svc.translate(
                request.data.get('text', ''),
                source=request.data.get('source', 'en-IN'),
                target=request.data.get('target', 'hi-IN'),
            )
            return Response({'translated': translated})
        except Integration.DoesNotExist:
            return Response({'error': 'Sarvam not configured'}, status=400)

    @action(detail=False, methods=['post'])
    def bulk_score_leads(self, request):
        """Score multiple leads at once (batch)."""
        svc, err = self._gemini(request)
        if err:
            return err
        from leads.models import Lead
        tenant = _get_tenant(request)
        leads = Lead.objects.filter(status__in=['new', 'contacted', 'qualified'])
        if tenant:
            pass  # Add tenant filter when tenancy is fully wired
        results = []
        for lead in leads[:20]:  # cap at 20 per call
            score = svc.score_lead({
                'name': lead.get_full_name(), 'company': lead.company,
                'status': lead.status, 'priority': lead.priority,
                'budget': str(lead.budget or ''),
            })
            results.append({'lead_id': lead.id, 'lead_name': lead.get_full_name(), **score})
        return Response({'results': results})
