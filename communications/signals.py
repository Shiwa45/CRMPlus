# communications/signals.py
# Simplified for django-tenants compatibility — removed stale model field references
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model

User = get_user_model()


@receiver(post_save, sender=User)
def create_default_email_templates(sender, instance, created, **kwargs):
    """Create default email templates for new users."""
    if created:
        try:
            from .services import EmailTemplateService
            default_templates = EmailTemplateService.get_default_templates(instance)
            for template in default_templates:
                template.save()
        except Exception:
            # Non-critical; don't break user creation if template seeding fails
            pass
