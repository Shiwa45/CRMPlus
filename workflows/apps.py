from django.apps import AppConfig


class WorkflowsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'workflows'
    verbose_name = 'Automation & Workflows'

    def ready(self):
        from .signals import (
            connect_lead_signals,
            connect_deal_signals,
            connect_ticket_signals,
            connect_contact_signals,
        )
        connect_lead_signals()
        connect_deal_signals()
        connect_ticket_signals()
        connect_contact_signals()
