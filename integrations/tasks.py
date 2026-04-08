# integrations/tasks.py
"""
Celery tasks for periodic lead imports from external platforms.

Uses django_tenants.utils.schema_context() to iterate across tenant schemas
and pull leads for each tenant that has an active integration configured.
"""
import logging
from celery import shared_task
from django.utils import timezone
from django_tenants.utils import schema_context, get_tenant_model

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def sync_indiamart_leads(self):
    """
    Periodic task: pull new leads from IndiaMART for every tenant
    that has an active IndiaMART integration.

    Runs every 5 minutes via Celery Beat.
    Iterates all tenant schemas and checks for active 'indiamart' integration.
    """
    TenantModel = get_tenant_model()
    tenants = TenantModel.objects.exclude(schema_name='public')

    total_created = 0
    total_errors = 0

    for tenant in tenants:
        try:
            with schema_context(tenant.schema_name):
                from integrations.models import Integration
                try:
                    integration = Integration.objects.get(
                        service=Integration.SERVICE_INDIAMART,
                        is_active=True,
                    )
                except Integration.DoesNotExist:
                    continue  # This tenant doesn't use IndiaMART

                if not integration.api_key:
                    logger.warning(
                        f"IndiaMART: no API key for tenant {tenant.schema_name}"
                    )
                    continue

                from integrations.services import IndiaMartService
                svc = IndiaMartService(integration)

                # Pull leads from the last sync time (or last 5 min)
                start_time = None
                if integration.last_sync:
                    start_time = integration.last_sync.strftime('%d-%b-%Y %H:%M:%S')

                result = svc.pull_leads(start_time=start_time)

                if result['success'] and result['leads']:
                    import_result = svc.import_leads(
                        result['leads'], method='pull_api'
                    )
                    total_created += import_result['leads_created']
                    logger.info(
                        f"IndiaMART sync for {tenant.schema_name}: "
                        f"{import_result['leads_created']} created, "
                        f"{import_result['leads_skipped']} skipped"
                    )
                elif not result['success']:
                    logger.error(
                        f"IndiaMART pull failed for {tenant.schema_name}: "
                        f"{result['error']}"
                    )
                    integration.last_error = result['error']
                    integration.error_count += 1
                    integration.save(update_fields=['last_error', 'error_count'])
                    total_errors += 1

        except Exception as e:
            logger.error(
                f"IndiaMART sync task error for {tenant.schema_name}: {e}",
                exc_info=True
            )
            total_errors += 1

    logger.info(
        f"IndiaMART sync complete: {total_created} leads created, "
        f"{total_errors} errors across {tenants.count()} tenants"
    )
    return {
        'total_created': total_created,
        'total_errors': total_errors,
        'tenants_checked': tenants.count(),
    }


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def sync_meta_leads_catchup(self):
    """
    Optional periodic task: catch up on any missed Meta webhook deliveries.

    Meta webhooks are real-time, but this task can run less frequently
    (e.g., every 30 minutes) to catch any leads that were missed.
    It uses the Graph API to list recent leads for each configured page.

    This is a safety net — the primary ingestion is via webhooks.
    """
    TenantModel = get_tenant_model()
    tenants = TenantModel.objects.exclude(schema_name='public')

    total_created = 0

    for tenant in tenants:
        try:
            with schema_context(tenant.schema_name):
                from integrations.models import Integration
                try:
                    integration = Integration.objects.get(
                        service=Integration.SERVICE_META_LEADS,
                        is_active=True,
                    )
                except Integration.DoesNotExist:
                    continue

                if not integration.api_key:
                    continue

                page_id = (integration.config or {}).get('page_id', '')
                if not page_id:
                    continue

                # Fetch recent leads from the page's leadgen_forms
                import requests
                from integrations.services import MetaLeadAdsService

                svc = MetaLeadAdsService(integration)
                url = f"{svc.GRAPH_API_BASE}/{page_id}/leadgen_forms"
                params = {
                    'access_token': svc.page_access_token,
                    'fields': 'id,name,leads.limit(50){created_time,id,field_data}',
                }

                try:
                    r = requests.get(url, params=params, timeout=30)
                    r.raise_for_status()
                    forms_data = r.json()

                    for form in forms_data.get('data', []):
                        leads_data = form.get('leads', {}).get('data', [])
                        if not leads_data:
                            continue

                        from integrations.models import LeadImportLog
                        from leads.models import Lead, LeadSource

                        source, _ = LeadSource.objects.get_or_create(
                            name='Meta Lead Ads',
                            defaults={
                                'description': 'Leads from Meta Lead Ad forms'
                            }
                        )

                        for meta_lead in leads_data:
                            leadgen_id = meta_lead.get('id', '')
                            if not leadgen_id:
                                continue

                            # Skip if already imported
                            if LeadImportLog.objects.filter(
                                source='meta_leads',
                                external_ids__contains=leadgen_id,
                            ).exists():
                                continue

                            mapped = svc.map_lead_data(meta_lead)

                            # Dedup by email/phone
                            dup_filter = {}
                            if mapped.get('email'):
                                dup_filter['email'] = mapped['email']
                            if mapped.get('phone'):
                                dup_filter['phone'] = mapped['phone']
                            if dup_filter and Lead.objects.filter(**dup_filter).exists():
                                continue

                            try:
                                from django.contrib.auth import get_user_model
                                User = get_user_model()
                                admin_user = User.objects.filter(
                                    is_staff=True, is_active=True
                                ).first()
                                if not admin_user:
                                    continue

                                Lead.objects.create(
                                    **mapped,
                                    source=source,
                                    status='new',
                                    priority='warm',
                                    created_by=admin_user,
                                )
                                total_created += 1

                                # Log it
                                LeadImportLog.objects.create(
                                    source='meta_leads',
                                    method='pull_api',
                                    leads_received=1,
                                    leads_created=1,
                                    leads_skipped=0,
                                    external_ids=[leadgen_id],
                                )
                            except Exception as e:
                                logger.error(f"Meta catchup lead create error: {e}")

                except requests.exceptions.RequestException as e:
                    logger.error(
                        f"Meta catchup API error for {tenant.schema_name}: {e}"
                    )

        except Exception as e:
            logger.error(
                f"Meta catchup task error for {tenant.schema_name}: {e}",
                exc_info=True
            )

    logger.info(f"Meta lead catchup complete: {total_created} new leads created")
    return {'total_created': total_created}
