# workflows/signals.py
"""
Central signal handlers that fire WorkflowExecutor.trigger() whenever
key CRM objects change. Connect these in workflows/apps.py ready().
"""
from django.db.models.signals import post_save
from django.dispatch import receiver


# ── Lead Signals ──────────────────────────────────────────────────────────────

def _lead_context(lead):
    return {
        'id': lead.id, 'status': lead.status, 'priority': lead.priority,
        'assigned_to_id': lead.assigned_to_id,
        'source_id': lead.source_id,
        'budget': str(lead.budget or 0),
    }


def connect_lead_signals():
    from leads.models import Lead

    @receiver(post_save, sender=Lead, dispatch_uid='wf_lead_created')
    def on_lead_save(sender, instance, created, **kwargs):
        from .executor import WorkflowExecutor
        ctx = _lead_context(instance)
        if created:
            WorkflowExecutor.trigger('lead_created', 'lead', instance.id, ctx)
        else:
            # Compare with previous state stored in __original
            original = getattr(instance, '_original', {})
            if original.get('status') != instance.status:
                WorkflowExecutor.trigger('lead_status_changed', 'lead', instance.id,
                                         {**ctx, 'old_status': original.get('status')})
            if original.get('assigned_to_id') != instance.assigned_to_id:
                WorkflowExecutor.trigger('lead_assigned', 'lead', instance.id, ctx)
            if original.get('priority') != instance.priority:
                WorkflowExecutor.trigger('lead_priority_changed', 'lead', instance.id, ctx)

    from django.db.models.signals import pre_save

    @receiver(pre_save, sender=Lead, dispatch_uid='wf_lead_presave')
    def capture_lead_original(sender, instance, **kwargs):
        if instance.pk:
            try:
                old = Lead.objects.get(pk=instance.pk)
                instance._original = {
                    'status': old.status,
                    'priority': old.priority,
                    'assigned_to_id': old.assigned_to_id,
                }
            except Lead.DoesNotExist:
                instance._original = {}


# ── Deal Signals ──────────────────────────────────────────────────────────────

def connect_deal_signals():
    from deals.models import Deal
    from django.db.models.signals import pre_save

    @receiver(pre_save, sender=Deal, dispatch_uid='wf_deal_presave')
    def capture_deal_original(sender, instance, **kwargs):
        if instance.pk:
            try:
                old = Deal.objects.get(pk=instance.pk)
                instance._original = {
                    'stage_id': old.stage_id,
                    'stage_is_won': old.stage.is_won if old.stage else False,
                    'stage_is_lost': old.stage.is_lost if old.stage else False,
                }
            except Deal.DoesNotExist:
                instance._original = {}

    @receiver(post_save, sender=Deal, dispatch_uid='wf_deal_saved')
    def on_deal_save(sender, instance, created, **kwargs):
        from .executor import WorkflowExecutor
        ctx = {
            'id': instance.id, 'stage_id': instance.stage_id,
            'pipeline_id': instance.pipeline_id,
            'owner_id': instance.owner_id,
            'value': str(instance.value),
        }
        if created:
            WorkflowExecutor.trigger('deal_created', 'deal', instance.id, ctx)
        else:
            original = getattr(instance, '_original', {})
            if original.get('stage_id') != instance.stage_id:
                WorkflowExecutor.trigger('deal_stage_changed', 'deal', instance.id, ctx)
                if instance.stage and instance.stage.is_won and not original.get('stage_is_won'):
                    WorkflowExecutor.trigger('deal_won', 'deal', instance.id, ctx)
                if instance.stage and instance.stage.is_lost and not original.get('stage_is_lost'):
                    WorkflowExecutor.trigger('deal_lost', 'deal', instance.id, ctx)


# ── Ticket Signals ────────────────────────────────────────────────────────────

def connect_ticket_signals():
    from tickets.models import Ticket
    from django.db.models.signals import pre_save

    @receiver(pre_save, sender=Ticket, dispatch_uid='wf_ticket_presave')
    def capture_ticket_original(sender, instance, **kwargs):
        if instance.pk:
            try:
                old = Ticket.objects.get(pk=instance.pk)
                instance._original = {'status': old.status}
            except Ticket.DoesNotExist:
                instance._original = {}

    @receiver(post_save, sender=Ticket, dispatch_uid='wf_ticket_saved')
    def on_ticket_save(sender, instance, created, **kwargs):
        from .executor import WorkflowExecutor
        ctx = {
            'id': instance.id, 'status': instance.status,
            'priority': instance.priority, 'assigned_to_id': instance.assigned_to_id,
        }
        if created:
            WorkflowExecutor.trigger('ticket_created', 'ticket', instance.id, ctx)
        else:
            original = getattr(instance, '_original', {})
            if original.get('status') != instance.status:
                WorkflowExecutor.trigger('ticket_status_changed', 'ticket', instance.id, ctx)
                if instance.status == 'resolved':
                    WorkflowExecutor.trigger('ticket_resolved', 'ticket', instance.id, ctx)


# ── Contact Signals ───────────────────────────────────────────────────────────

def connect_contact_signals():
    from contacts.models import Contact

    @receiver(post_save, sender=Contact, dispatch_uid='wf_contact_created')
    def on_contact_save(sender, instance, created, **kwargs):
        if created:
            from .executor import WorkflowExecutor
            WorkflowExecutor.trigger('contact_created', 'contact', instance.id, {
                'id': instance.id, 'owner_id': instance.owner_id,
            })
