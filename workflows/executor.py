# workflows/executor.py
"""
Workflow Execution Engine
-------------------------
Call WorkflowExecutor.trigger(event, object_type, object_id, context)
from signals/post_save hooks to fire matching workflows.
"""
import logging
from django.utils import timezone
from .models import Workflow, WorkflowExecution, Notification, Task

logger = logging.getLogger(__name__)


class WorkflowExecutor:

    @classmethod
    def trigger(cls, event: str, object_type: str, object_id: int, context: dict = None):
        """
        Find all active workflows for this event and execute them.
        context: dict with the object's current field values for condition evaluation.
        """
        context = context or {}
        workflows = Workflow.objects.filter(trigger=event, is_active=True).prefetch_related('conditions', 'actions')

        for wf in workflows:
            # Prevent duplicate execution
            if wf.run_once_per_object:
                already_ran = WorkflowExecution.objects.filter(
                    workflow=wf, object_type=object_type, object_id=object_id,
                    status='completed'
                ).exists()
                if already_ran:
                    continue

            # Check trigger_config filter (simple field matching)
            if wf.trigger_config:
                if not cls._matches_config(wf.trigger_config, context):
                    continue

            # Check conditions
            if not cls._evaluate_conditions(wf.conditions.all(), context):
                execution = WorkflowExecution.objects.create(
                    workflow=wf, status='skipped',
                    triggered_by=event, object_type=object_type, object_id=object_id,
                )
                continue

            execution = WorkflowExecution.objects.create(
                workflow=wf, status='running',
                triggered_by=event, object_type=object_type, object_id=object_id,
            )
            try:
                executed = cls._execute_actions(wf.actions.all().order_by('order'), context, object_type, object_id)
                execution.status = 'completed'
                execution.actions_executed = executed
                execution.completed_at = timezone.now()
                execution.save()
                wf.run_count += 1
                wf.last_run_at = timezone.now()
                wf.save(update_fields=['run_count', 'last_run_at'])
            except Exception as e:
                logger.error(f"Workflow {wf.id} execution failed: {e}")
                execution.status = 'failed'
                execution.error_message = str(e)
                execution.completed_at = timezone.now()
                execution.save()

    @classmethod
    def _matches_config(cls, config: dict, context: dict) -> bool:
        for key, value in config.items():
            if str(context.get(key, '')) != str(value):
                return False
        return True

    @classmethod
    def _evaluate_conditions(cls, conditions, context: dict) -> bool:
        if not conditions:
            return True
        results = []
        for cond in conditions:
            field_val = str(context.get(cond.field, ''))
            cond_val  = str(cond.value)
            op = cond.operator

            if op == 'equals':
                result = field_val == cond_val
            elif op == 'not_equals':
                result = field_val != cond_val
            elif op == 'contains':
                result = cond_val.lower() in field_val.lower()
            elif op == 'not_contains':
                result = cond_val.lower() not in field_val.lower()
            elif op == 'greater_than':
                try:
                    result = float(field_val) > float(cond_val)
                except (ValueError, TypeError):
                    result = False
            elif op == 'less_than':
                try:
                    result = float(field_val) < float(cond_val)
                except (ValueError, TypeError):
                    result = False
            elif op == 'is_empty':
                result = not field_val
            elif op == 'is_not_empty':
                result = bool(field_val)
            elif op == 'in':
                result = field_val in [v.strip() for v in cond_val.split(',')]
            elif op == 'not_in':
                result = field_val not in [v.strip() for v in cond_val.split(',')]
            else:
                result = True

            results.append((cond.logic, result))

        # Combine with AND/OR
        final = results[0][1]
        for logic, val in results[1:]:
            if logic == 'and':
                final = final and val
            else:
                final = final or val
        return final

    @classmethod
    def _execute_actions(cls, actions, context: dict, object_type: str, object_id: int) -> list:
        executed = []
        for action in actions:
            try:
                handler = getattr(cls, f'_action_{action.action_type}', cls._action_unknown)
                handler(action.config, context, object_type, object_id)
                executed.append({'action': action.action_type, 'status': 'ok'})
            except Exception as e:
                logger.warning(f"Action {action.action_type} failed: {e}")
                executed.append({'action': action.action_type, 'status': 'failed', 'error': str(e)})
        return executed

    # ── Action Handlers ──────────────────────────────────────────────────────

    @classmethod
    def _action_unknown(cls, config, context, object_type, object_id):
        pass

    @classmethod
    def _action_assign_owner(cls, config, context, object_type, object_id):
        user_id = config.get('user_id')
        if not user_id:
            return
        model_class = cls._get_model(object_type)
        if model_class:
            model_class.objects.filter(id=object_id).update(assigned_to_id=user_id)

    @classmethod
    def _action_assign_round_robin(cls, config, context, object_type, object_id):
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user_ids = config.get('user_ids', [])
        if not user_ids:
            return
        # Pick user with least open leads/deals
        min_count = None
        chosen_id = user_ids[0]
        for uid in user_ids:
            count = User.objects.filter(id=uid).annotate(
                open=__import__('django.db.models', fromlist=['Count']).Count('assigned_leads')
            ).values_list('open', flat=True).first() or 0
            if min_count is None or count < min_count:
                min_count = count
                chosen_id = uid
        model_class = cls._get_model(object_type)
        if model_class:
            model_class.objects.filter(id=object_id).update(assigned_to_id=chosen_id)

    @classmethod
    def _action_update_lead_status(cls, config, context, object_type, object_id):
        if object_type == 'lead':
            from leads.models import Lead
            Lead.objects.filter(id=object_id).update(status=config.get('status', 'contacted'))

    @classmethod
    def _action_update_deal_stage(cls, config, context, object_type, object_id):
        if object_type == 'deal':
            from deals.models import Deal
            stage_id = config.get('stage_id')
            if stage_id:
                Deal.objects.filter(id=object_id).update(stage_id=stage_id)

    @classmethod
    def _action_update_ticket_status(cls, config, context, object_type, object_id):
        if object_type == 'ticket':
            from tickets.models import Ticket
            Ticket.objects.filter(id=object_id).update(status=config.get('status', 'in_progress'))

    @classmethod
    def _action_create_notification(cls, config, context, object_type, object_id):
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user_id = config.get('user_id') or context.get('assigned_to_id')
        if not user_id:
            return
        try:
            user = User.objects.get(id=user_id)
            Notification.objects.create(
                user=user,
                notif_type='workflow_alert',
                title=config.get('title', 'Workflow Alert'),
                body=config.get('body', ''),
                object_type=object_type,
                object_id=object_id,
            )
        except User.DoesNotExist:
            pass

    @classmethod
    def _action_create_task(cls, config, context, object_type, object_id):
        from django.contrib.auth import get_user_model
        User = get_user_model()
        assigned_id = config.get('assigned_to_id') or context.get('assigned_to_id')
        created_by_id = config.get('created_by_id', 1)
        kwargs = {
            'title': config.get('title', 'Auto-created Task'),
            'description': config.get('description', ''),
            'task_type': config.get('task_type', 'follow_up'),
            'priority': config.get('priority', 'medium'),
            'created_by_id': created_by_id,
        }
        if assigned_id:
            kwargs['assigned_to_id'] = assigned_id
        if config.get('due_hours'):
            from datetime import timedelta
            kwargs['due_date'] = timezone.now() + timedelta(hours=int(config['due_hours']))
        kwargs[f'{object_type}_id'] = object_id
        Task.objects.create(**kwargs)

    @classmethod
    def _action_add_note(cls, config, context, object_type, object_id):
        note_text = config.get('note', '')
        if object_type == 'lead':
            from leads.models import LeadActivity, Lead
            try:
                lead = Lead.objects.get(id=object_id)
                LeadActivity.objects.create(
                    lead=lead, activity_type='note', subject='Automated Note',
                    description=note_text, user_id=config.get('user_id', 1)
                )
            except Exception:
                pass

    @classmethod
    def _action_add_tag(cls, config, context, object_type, object_id):
        tag = config.get('tag')
        if not tag:
            return
        model_class = cls._get_model(object_type)
        if model_class and hasattr(model_class, 'tags'):
            obj = model_class.objects.filter(id=object_id).first()
            if obj and isinstance(obj.tags, list) and tag not in obj.tags:
                obj.tags.append(tag)
                obj.save(update_fields=['tags'])

    @classmethod
    def _action_webhook(cls, config, context, object_type, object_id):
        import requests
        url = config.get('url')
        if not url:
            return
        payload = {
            'event': context.get('event'),
            'object_type': object_type,
            'object_id': object_id,
            'data': context,
        }
        try:
            requests.post(url, json=payload, timeout=10)
        except Exception as e:
            raise Exception(f"Webhook failed: {e}")

    @classmethod
    def _get_model(cls, object_type: str):
        mapping = {
            'lead': 'leads.models.Lead',
            'deal': 'deals.models.Deal',
            'contact': 'contacts.models.Contact',
            'ticket': 'tickets.models.Ticket',
        }
        path = mapping.get(object_type)
        if not path:
            return None
        module_path, class_name = path.rsplit('.', 1)
        import importlib
        module = importlib.import_module(module_path)
        return getattr(module, class_name, None)
