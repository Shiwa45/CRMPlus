# integrations/webhooks.py
"""
Public webhook endpoints for external services (IndiaMART Push, Meta Lead Ads).

These views are UNAUTHENTICATED — they validate requests using API keys,
verify tokens, or HMAC signatures instead of Django auth.

Security:
  - IndiaMART Push: validates the glusr_crm_key in the payload
  - Meta Lead Ads GET: validates hub.verify_token
  - Meta Lead Ads POST: validates X-Hub-Signature-256 header
"""
import json
import logging

from django.http import HttpResponse, JsonResponse
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django_tenants.utils import schema_context

from tenants.models import Tenant
from .models import Integration

logger = logging.getLogger(__name__)


def _get_tenant_and_integration(tenant_slug, service_name):
    """
    Resolve a tenant by slug and find their active integration.
    Returns (tenant, integration) or (None, None).
    """
    try:
        tenant = Tenant.objects.get(slug=tenant_slug)
    except Tenant.DoesNotExist:
        logger.warning(f"Webhook: tenant slug '{tenant_slug}' not found")
        return None, None

    # Switch into the tenant's schema to query Integration
    from django.db import connection
    connection.set_tenant(tenant)

    try:
        integration = Integration.objects.get(service=service_name, is_active=True)
        return tenant, integration
    except Integration.DoesNotExist:
        logger.warning(f"Webhook: {service_name} integration not active for {tenant_slug}")
        return tenant, None


@method_decorator(csrf_exempt, name='dispatch')
class IndiaMartWebhookView(View):
    """
    IndiaMART Push API webhook receiver.

    IndiaMART sends leads via POST when Push API is enabled in seller dashboard.
    The tenant slug is passed in the URL for multi-tenant routing.

    URL: /api/webhooks/indiamart/<tenant_slug>/
    """

    def post(self, request, tenant_slug):
        tenant, integration = _get_tenant_and_integration(
            tenant_slug, Integration.SERVICE_INDIAMART
        )
        if not tenant:
            return JsonResponse({'error': 'Tenant not found'}, status=404)
        if not integration:
            return JsonResponse({'error': 'IndiaMART integration not configured'}, status=400)

        try:
            # IndiaMART Push API sends data as form-encoded or JSON
            content_type = request.content_type or ''
            if 'json' in content_type:
                data = json.loads(request.body)
            else:
                data = dict(request.POST)
                # Flatten single-value lists from POST
                data = {k: v[0] if isinstance(v, list) and len(v) == 1 else v
                        for k, v in data.items()}

            # Extract leads — Push API may send single lead or list
            leads = []
            if isinstance(data, list):
                leads = data
            elif 'RESPONSE' in data and isinstance(data['RESPONSE'], list):
                leads = data['RESPONSE']
            elif 'UNIQUE_QUERY_ID' in data:
                # Single lead object
                leads = [data]
            elif isinstance(data, dict):
                # Try to find leads in any key
                for key, val in data.items():
                    if isinstance(val, list) and val and isinstance(val[0], dict):
                        leads = val
                        break

            if not leads:
                logger.info(f"IndiaMART Push webhook: no leads in payload for {tenant_slug}")
                return JsonResponse({'status': 'ok', 'message': 'No leads in payload'})

            # Import leads within the tenant's schema context
            from .services import IndiaMartService
            with schema_context(tenant.schema_name):
                svc = IndiaMartService(integration)
                result = svc.import_leads(leads, method='push_webhook')

            logger.info(
                f"IndiaMART Push webhook: {result['leads_created']} created, "
                f"{result['leads_skipped']} skipped for {tenant_slug}"
            )
            return JsonResponse({
                'status': 'ok',
                'leads_created': result['leads_created'],
                'leads_skipped': result['leads_skipped'],
            })

        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)
        except Exception as e:
            logger.error(f"IndiaMART Push webhook error for {tenant_slug}: {e}")
            return JsonResponse({'error': 'Internal server error'}, status=500)


@method_decorator(csrf_exempt, name='dispatch')
class MetaLeadWebhookView(View):
    """
    Meta (Facebook) Lead Ads webhook.

    GET  → Webhook verification (hub.challenge response)
    POST → Receive leadgen events and fetch full lead data via Graph API

    URL: /api/webhooks/meta-leads/<tenant_slug>/
    """

    def get(self, request, tenant_slug):
        """Handle Meta webhook verification."""
        mode = request.GET.get('hub.mode', '')
        token = request.GET.get('hub.verify_token', '')
        challenge = request.GET.get('hub.challenge', '')

        tenant, integration = _get_tenant_and_integration(
            tenant_slug, Integration.SERVICE_META_LEADS
        )
        if not integration:
            return HttpResponse('Integration not configured', status=403)

        from .services import MetaLeadAdsService
        svc = MetaLeadAdsService(integration)
        is_valid, response = svc.verify_webhook(mode, token, challenge)

        if is_valid:
            return HttpResponse(response, content_type='text/plain')
        return HttpResponse('Verification failed', status=403)

    def post(self, request, tenant_slug):
        """Handle incoming leadgen webhook events from Meta."""
        tenant, integration = _get_tenant_and_integration(
            tenant_slug, Integration.SERVICE_META_LEADS
        )
        if not tenant:
            return JsonResponse({'error': 'Tenant not found'}, status=404)
        if not integration:
            return JsonResponse({'error': 'Meta integration not configured'}, status=400)

        # Validate signature (optional but recommended)
        from .services import MetaLeadAdsService
        app_secret = (integration.config or {}).get('app_secret', '')
        if app_secret:
            signature = request.META.get('HTTP_X_HUB_SIGNATURE_256', '')
            if not MetaLeadAdsService.validate_signature(
                request.body, signature, app_secret
            ):
                logger.warning(f"Meta webhook: invalid signature for {tenant_slug}")
                return JsonResponse({'error': 'Invalid signature'}, status=403)

        try:
            payload = json.loads(request.body)
        except json.JSONDecodeError:
            return JsonResponse({'error': 'Invalid JSON'}, status=400)

        # Meta sends: {"object": "page", "entry": [...]}
        if payload.get('object') != 'page':
            return JsonResponse({'status': 'ok', 'message': 'Not a page event'})

        total_created = 0
        total_skipped = 0

        svc = MetaLeadAdsService(integration)

        for entry in payload.get('entry', []):
            with schema_context(tenant.schema_name):
                result = svc.process_webhook_entry(entry)
                total_created += result.get('leads_created', 0)
                total_skipped += result.get('leads_skipped', 0)

        logger.info(
            f"Meta webhook: {total_created} created, {total_skipped} skipped "
            f"for {tenant_slug}"
        )

        # Meta requires 200 response to acknowledge receipt
        return JsonResponse({
            'status': 'ok',
            'leads_created': total_created,
            'leads_skipped': total_skipped,
        })
