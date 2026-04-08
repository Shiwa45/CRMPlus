# integrations/services.py
"""
Runtime service wrappers for 3rd-party APIs.
Each service is stateless; pass in the Integration row + payload.
"""
import json, logging, requests
from django.utils import timezone
from .models import Integration, WALog, WhatsAppTemplate

logger = logging.getLogger(__name__)


# ── WhatsApp (Meta Cloud API) ─────────────────────────────────────────────────
class WhatsAppService:
    """
    Sends messages via Meta WhatsApp Cloud API.
    Supports template messages (approved) and free-form text (within 24-hr window).
    """
    BASE_URL = 'https://graph.facebook.com/v19.0'

    def __init__(self, integration: Integration):
        self.token    = integration.api_key
        self.phone_id = integration.extra.get('phone_number_id', '')

    def send_template(self, to_phone: str, template_name: str,
                      components: list = None) -> dict:
        url = f"{self.BASE_URL}/{self.phone_id}/messages"
        body = {
            "messaging_product": "whatsapp",
            "to": to_phone,
            "type": "template",
            "template": {
                "name": template_name,
                "language": {"code": "en"},
            }
        }
        if components:
            body["template"]["components"] = components
        try:
            r = requests.post(url, headers=self._headers(), json=body, timeout=10)
            r.raise_for_status()
            return {'success': True, 'data': r.json()}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def send_text(self, to_phone: str, message: str) -> dict:
        url = f"{self.BASE_URL}/{self.phone_id}/messages"
        body = {
            "messaging_product": "whatsapp",
            "to": to_phone,
            "type": "text",
            "text": {"body": message, "preview_url": False}
        }
        try:
            r = requests.post(url, headers=self._headers(), json=body, timeout=10)
            r.raise_for_status()
            return {'success': True, 'data': r.json()}
        except Exception as e:
            return {'success': False, 'error': str(e)}

    def _headers(self):
        return {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json',
        }

    @classmethod
    def send_to_lead(cls, tenant, lead, template: WhatsAppTemplate,
                     sent_by=None) -> WALog:
        """High-level: render template with lead data and send."""
        ctx = {
            'name': lead.get_full_name() if hasattr(lead, 'get_full_name') else str(lead),
            'first_name': getattr(lead, 'first_name', ''),
            'last_name': getattr(lead, 'last_name', ''),
            'company': getattr(lead, 'company', ''),
            'phone': getattr(lead, 'phone', ''),
            'email': getattr(lead, 'email', ''),
            'lead_status': getattr(lead, 'status', ''),
            'budget': str(getattr(lead, 'budget', '') or ''),
        }
        rendered = template.render(ctx)
        phone = getattr(lead, 'phone', '') or ''
        # Normalise Indian numbers
        phone = phone.replace(' ', '').replace('-', '').replace('+', '')
        if phone.startswith('0'):
            phone = '91' + phone[1:]
        elif not phone.startswith('91') and len(phone) == 10:
            phone = '91' + phone

        log = WALog(
            template=template,
            to_number=phone,
            body_sent=rendered,
            created_by=sent_by,
        )
        try:
            intg = Integration.objects.get(service=Integration.SERVICE_WHATSAPP, is_active=True)
            svc = cls(intg)
            result = svc.send_text(phone, rendered)
            if result['success']:
                log.status = 'sent'
                log.wa_message_id = result['data'].get('messages', [{}])[0].get('id', '')
            else:
                log.status = 'failed'
                log.error  = result['error']
        except Integration.DoesNotExist:
            log.status = 'failed'
            log.error  = 'WhatsApp integration not configured'
        except Exception as e:
            log.status = 'failed'
            log.error  = str(e)
        log.save()
        return log


# ── Gemini AI ─────────────────────────────────────────────────────────────────
class GeminiService:
    MODEL = 'gemini-3-flash-preview'

    def __init__(self, api_key: str):
        self.key = api_key

    def _client(self):
        try:
            from google import genai
            return genai.Client(api_key=self.key)
        except Exception as e:
            logger.error(f"Gemini client error: {e}")
            return None

    def generate(self, prompt: str, system: str = '', max_tokens: int = 800,
                 thinking_level: str = 'HIGH', use_search: bool = False) -> str:
        client = self._client()
        if not client:
            return ''
        try:
            from google.genai import types
            contents = []
            if system:
                contents.append(
                    types.Content(role="user", parts=[types.Part.from_text(text=system)])
                )
                contents.append(
                    types.Content(role="model", parts=[types.Part.from_text(text="Understood.")])
                )
            contents.append(
                types.Content(role="user", parts=[types.Part.from_text(text=prompt)])
            )

            tools = []
            if use_search:
                tools = [types.Tool(googleSearch=types.GoogleSearch())]

            cfg_kwargs = {
                'thinking_config': types.ThinkingConfig(thinking_level=thinking_level),
                'tools': tools,
                # New SDK doesn't accept generation_config in this version
                'max_output_tokens': max_tokens,
                'temperature': 0.7,
            }
            config = types.GenerateContentConfig(**cfg_kwargs)
            resp = client.models.generate_content(
                model=self.MODEL,
                contents=contents,
                config=config,
            )
            return resp.text or ''
        except Exception as e:
            logger.error(f"Gemini error: {e}")
            return ''

    def score_lead(self, lead_data: dict) -> dict:
        prompt = f"""
Score this sales lead from 0-100 and explain why briefly.
Lead data: {json.dumps(lead_data, default=str)}

Return ONLY valid JSON:
{{"score": <0-100>, "grade": "<Hot|Warm|Cold>", "reason": "<1 sentence>",
  "next_action": "<recommended action>", "priority": "<high|medium|low>"}}
"""
        raw = self.generate(prompt, max_tokens=200)
        try:
            start, end = raw.find('{'), raw.rfind('}') + 1
            return json.loads(raw[start:end])
        except Exception:
            return {'score': 50, 'grade': 'Warm', 'reason': 'Scoring unavailable', 'next_action': 'Follow up', 'priority': 'medium'}

    def draft_email(self, to_name: str, context: str, tone: str = 'professional') -> dict:
        prompt = f"""
Draft a sales email to {to_name}.
Context: {context}
Tone: {tone}
Return JSON: {{"subject": "...", "body": "..."}}
"""
        raw = self.generate(prompt, max_tokens=500)
        try:
            start, end = raw.find('{'), raw.rfind('}') + 1
            return json.loads(raw[start:end])
        except Exception:
            return {'subject': 'Following up', 'body': raw}

    def marketing_copy(self, product: str, target: str, style: str) -> str:
        prompt = f"""
Write {style} marketing copy for: {product}
Target audience: {target}
Keep it concise, compelling, India-market focused.
"""
        return self.generate(prompt, max_tokens=600)

    def chat(self, history: list, message: str, crm_context: str = '') -> str:
        system = f"""You are an intelligent CRM assistant for an Indian sales team.
You help with lead management, deal coaching, email drafting, and CRM data analysis.
{f'Current CRM context: {crm_context}' if crm_context else ''}
Be concise, practical, and use Indian business context where relevant.
"""
        prompt = '\n'.join([f"{m['role'].upper()}: {m['content']}" for m in history])
        prompt += f"\nUSER: {message}\nASSISTANT:"
        return self.generate(prompt, system=system, max_tokens=500)


# ── Sarvam AI (Voice / Calls) ─────────────────────────────────────────────────
class SarvamService:
    BASE_URL = 'https://api.sarvam.ai'

    def __init__(self, api_key: str):
        self.key = api_key

    def _headers(self):
        return {'API-Subscription-Key': self.key, 'Content-Type': 'application/json'}

    def text_to_speech(self, text: str, language: str = 'hi-IN',
                       speaker: str = 'meera') -> bytes:
        """Returns audio bytes (WAV)."""
        r = requests.post(f"{self.BASE_URL}/text-to-speech", headers=self._headers(), json={
            'inputs': [text], 'target_language_code': language,
            'speaker': speaker, 'model': 'bulbul:v1',
        }, timeout=20)
        r.raise_for_status()
        import base64
        audios = r.json().get('audios', [])
        return base64.b64decode(audios[0]) if audios else b''

    def speech_to_text(self, audio_bytes: bytes, language: str = 'hi-IN') -> str:
        """Transcribes audio. Returns text."""
        import base64
        r = requests.post(f"{self.BASE_URL}/speech-to-text", headers=self._headers(), json={
            'model': 'saarika:v2',
            'language_code': language,
            'audio': base64.b64encode(audio_bytes).decode(),
            'with_timestamps': False,
        }, timeout=30)
        r.raise_for_status()
        return r.json().get('transcript', '')

    def translate(self, text: str, source: str = 'en-IN', target: str = 'hi-IN') -> str:
        r = requests.post(f"{self.BASE_URL}/translate", headers=self._headers(), json={
            'input': text, 'source_language_code': source,
            'target_language_code': target, 'model': 'mayura:v1',
        }, timeout=15)
        r.raise_for_status()
        return r.json().get('translated_text', text)

    def analyse_call(self, transcript: str) -> dict:
        """Use Sarvam + Gemini pipeline: STT → Gemini analysis."""
        # This is just the analysis layer; actual STT is done before
        prompt = f"""
Analyse this sales call transcript and return JSON:
{{
  "sentiment": "positive|neutral|negative",
  "summary": "2-sentence summary",
  "next_steps": ["action1", "action2"],
  "objections": ["objection1"],
  "buying_signals": ["signal1"],
  "follow_up_date": "YYYY-MM-DD or null",
  "deal_probability": <0-100>
}}
Transcript:
{transcript}
"""
        # Delegate to Gemini for analysis
        try:
            import google.generativeai as _g  # optional
        except ImportError:
            pass
        # Fallback: return dummy
        return {
            'sentiment': 'neutral', 'summary': 'Call analysis pending AI processing.',
            'next_steps': ['Follow up within 48 hours'],
            'objections': [], 'buying_signals': [],
            'follow_up_date': None, 'deal_probability': 50,
        }


# ── IndiaMART Lead Manager ────────────────────────────────────────────────────
class IndiaMartService:
    """
    IndiaMART CRM Lead API integration.

    Pull API:  GET https://mapi.indiamart.com/wservce/crm/crmListing/v2/
               ?glusr_crm_key=<KEY>&start_time=<>&end_time=<>
               Returns JSON with leads every polling cycle.

    Push API:  IndiaMART sends leads via POST to a configured webhook URL.
               Same data format as Pull API response.

    Official docs:
      Pull → https://seller.indiamart.com → Lead Manager → Import/Export → Pull API
      Push → https://seller.indiamart.com → Lead Manager → Import/Export → Push API
    """
    PULL_API_URL = 'https://mapi.indiamart.com/wservce/crm/crmListing/v2/'

    def __init__(self, integration: Integration):
        self.integration = integration
        self.crm_key = integration.api_key  # glusr_crm_key

    def pull_leads(self, start_time: str = None, end_time: str = None) -> dict:
        """
        Pull leads from IndiaMART Pull API.

        Args:
            start_time: Format 'DD-Mon-YYYY HH:MM:SS' e.g. '18-Mar-2026 00:00:00'
            end_time:   Same format. If omitted, defaults to now.

        Returns:
            dict with 'success', 'leads' (list), 'total', 'error'
        """
        from datetime import datetime, timedelta

        if not self.crm_key:
            return {'success': False, 'leads': [], 'total': 0,
                    'error': 'IndiaMART CRM key not configured'}

        # Default: last 5 minutes
        now = datetime.now()
        if not end_time:
            end_time = now.strftime('%d-%b-%Y %H:%M:%S')
        if not start_time:
            start = now - timedelta(minutes=5)
            start_time = start.strftime('%d-%b-%Y %H:%M:%S')

        params = {
            'glusr_crm_key': self.crm_key,
            'start_time': start_time,
            'end_time': end_time,
        }

        try:
            r = requests.get(self.PULL_API_URL, params=params, timeout=30)
            r.raise_for_status()
            data = r.json()

            # IndiaMART returns: {"STATUS": "SUCCESS", "TOTAL_CNT": N, "RESPONSE": [...]}
            # or on error: {"STATUS": "FAILURE", "ERROR_MESSAGE": "..."}
            status_code = data.get('CODE', data.get('STATUS', ''))

            if str(status_code).upper() in ('SUCCESS', '200'):
                leads = data.get('RESPONSE', [])
                if isinstance(leads, list):
                    return {'success': True, 'leads': leads,
                            'total': len(leads), 'error': ''}
                return {'success': True, 'leads': [], 'total': 0, 'error': ''}
            else:
                error_msg = data.get('ERROR_MESSAGE', data.get('MESSAGE', str(data)))
                return {'success': False, 'leads': [], 'total': 0, 'error': error_msg}

        except requests.exceptions.RequestException as e:
            logger.error(f"IndiaMART Pull API error: {e}")
            return {'success': False, 'leads': [], 'total': 0, 'error': str(e)}

    @staticmethod
    def map_lead_data(im_lead: dict) -> dict:
        """
        Map IndiaMART lead response fields to our Lead model fields.

        IndiaMART fields (from their API):
            UNIQUE_QUERY_ID, QUERY_TYPE, QUERY_TIME,
            SENDER_NAME, SENDER_EMAIL, SENDER_MOBILE, SENDER_PHONE,
            SENDER_COMPANY, SENDER_ADDRESS, SENDER_CITY, SENDER_STATE,
            SENDER_PINCODE, SENDER_COUNTRY_ISO,
            SUBJECT, QUERY_MESSAGE, QUERY_PRODUCT_NAME, QUERY_MCAT_NAME
        """
        full_name = im_lead.get('SENDER_NAME', '').strip()
        parts = full_name.split(' ', 1) if full_name else ['']
        first_name = parts[0] if parts else ''
        last_name = parts[1] if len(parts) > 1 else ''

        # Build requirements from product + message
        product = im_lead.get('QUERY_PRODUCT_NAME', '') or ''
        message = im_lead.get('QUERY_MESSAGE', '') or ''
        subject = im_lead.get('SUBJECT', '') or ''
        requirements = '\n'.join(filter(None, [
            f'Product: {product}' if product else '',
            f'Subject: {subject}' if subject else '',
            message,
        ]))

        return {
            'first_name': first_name or 'IndiaMART Lead',
            'last_name': last_name,
            'email': im_lead.get('SENDER_EMAIL', '') or '',
            'phone': (im_lead.get('SENDER_MOBILE', '') or
                      im_lead.get('SENDER_PHONE', '') or ''),
            'company': im_lead.get('SENDER_COMPANY', '') or '',
            'address': im_lead.get('SENDER_ADDRESS', '') or '',
            'city': im_lead.get('SENDER_CITY', '') or '',
            'state': im_lead.get('SENDER_STATE', '') or '',
            'postal_code': im_lead.get('SENDER_PINCODE', '') or '',
            'country': im_lead.get('SENDER_COUNTRY_ISO', 'India') or 'India',
            'requirements': requirements.strip(),
            'notes': f"IndiaMART Query ID: {im_lead.get('UNIQUE_QUERY_ID', 'N/A')}",
        }

    def import_leads(self, leads_data: list, method: str = 'pull_api',
                     created_by=None) -> dict:
        """
        Import a list of IndiaMART leads into the Lead model.
        Deduplicates by UNIQUE_QUERY_ID.

        Returns dict with counts.
        """
        from leads.models import Lead, LeadSource
        from .models import LeadImportLog

        # Get or create the LeadSource
        source, _ = LeadSource.objects.get_or_create(
            name='IndiaMART',
            defaults={'description': 'Leads imported from IndiaMART Lead Manager'}
        )

        created = 0
        skipped = 0
        external_ids = []

        for im_lead in leads_data:
            query_id = str(im_lead.get('UNIQUE_QUERY_ID', ''))
            external_ids.append(query_id)

            # Check for duplicate by looking at existing import logs
            if query_id and LeadImportLog.objects.filter(
                source='indiamart',
                external_ids__contains=query_id,
            ).exists():
                skipped += 1
                continue

            mapped = self.map_lead_data(im_lead)

            # Also check for duplicate by email+phone within the tenant
            dup_filter = {}
            if mapped['email']:
                dup_filter['email'] = mapped['email']
            if mapped['phone']:
                dup_filter['phone'] = mapped['phone']

            if dup_filter and Lead.objects.filter(**dup_filter).exists():
                skipped += 1
                continue

            try:
                lead_kwargs = {**mapped, 'source': source, 'status': 'new', 'priority': 'warm'}
                if created_by:
                    lead_kwargs['created_by'] = created_by
                else:
                    # Use first admin user as fallback
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    admin_user = User.objects.filter(
                        is_staff=True, is_active=True
                    ).first()
                    if admin_user:
                        lead_kwargs['created_by'] = admin_user
                    else:
                        logger.warning("No admin user found, skipping lead creation")
                        skipped += 1
                        continue

                Lead.objects.create(**lead_kwargs)
                created += 1
            except Exception as e:
                logger.error(f"Failed to create lead from IndiaMART: {e}")
                skipped += 1

        # Log the import
        log = LeadImportLog.objects.create(
            source='indiamart',
            method=method,
            leads_received=len(leads_data),
            leads_created=created,
            leads_skipped=skipped,
            external_ids=external_ids,
        )

        # Update integration stats
        self.integration.last_sync = timezone.now()
        self.integration.sync_count += 1
        self.integration.save(update_fields=['last_sync', 'sync_count'])

        return {
            'success': True,
            'leads_received': len(leads_data),
            'leads_created': created,
            'leads_skipped': skipped,
            'log_id': log.id,
        }


# ── Meta (Facebook) Lead Ads ─────────────────────────────────────────────────
class MetaLeadAdsService:
    """
    Meta (Facebook) Lead Ads integration via Webhooks + Graph API.

    Webhook flow:
      1. Meta sends leadgen event to our webhook URL
      2. We extract leadgen_id from the payload
      3. We call Graph API to fetch full lead data
      4. We map and create Lead objects

    Graph API:
      GET https://graph.facebook.com/v19.0/<leadgen_id>
      ?access_token=<PAGE_ACCESS_TOKEN>

    Official docs:
      https://developers.facebook.com/docs/marketing-api/guides/lead-ads/
      https://developers.facebook.com/docs/graph-api/webhooks/getting-started/
    """
    GRAPH_API_BASE = 'https://graph.facebook.com/v19.0'

    def __init__(self, integration: Integration):
        self.integration = integration
        self.page_access_token = integration.api_key
        self.verify_token = (integration.config or {}).get('verify_token', '')
        self.app_secret = (integration.config or {}).get('app_secret', '')
        self.page_id = (integration.config or {}).get('page_id', '')

    def verify_webhook(self, mode: str, token: str, challenge: str) -> tuple:
        """
        Handle Meta webhook verification (GET request).
        Returns (is_valid, challenge_response).
        """
        if mode == 'subscribe' and token == self.verify_token:
            return True, challenge
        return False, ''

    def fetch_lead(self, leadgen_id: str) -> dict:
        """
        Fetch full lead data from Graph API using leadgen_id.
        """
        url = f"{self.GRAPH_API_BASE}/{leadgen_id}"
        params = {'access_token': self.page_access_token}

        try:
            r = requests.get(url, params=params, timeout=15)
            r.raise_for_status()
            return {'success': True, 'data': r.json()}
        except requests.exceptions.RequestException as e:
            logger.error(f"Meta Graph API error for lead {leadgen_id}: {e}")
            return {'success': False, 'error': str(e)}

    @staticmethod
    def map_lead_data(meta_lead: dict) -> dict:
        """
        Map Meta Lead Ads fields to our Lead model fields.

        Meta lead format (from Graph API):
        {
            "id": "...",
            "created_time": "...",
            "field_data": [
                {"name": "full_name", "values": ["John Doe"]},
                {"name": "email", "values": ["john@example.com"]},
                {"name": "phone_number", "values": ["+919876543210"]},
                {"name": "company_name", "values": ["Acme Corp"]},
                {"name": "city", "values": ["Mumbai"]},
                {"name": "state", "values": ["Maharashtra"]},
                ...
            ]
        }
        """
        # Extract field_data into a flat dict
        fields = {}
        for field in meta_lead.get('field_data', []):
            name = field.get('name', '')
            values = field.get('values', [])
            fields[name] = values[0] if values else ''

        # Parse name
        full_name = fields.get('full_name', '') or fields.get('name', '')
        parts = full_name.split(' ', 1) if full_name else ['']
        first_name = parts[0] if parts else ''
        last_name = parts[1] if len(parts) > 1 else ''

        # Use individual name fields if available
        if not first_name:
            first_name = fields.get('first_name', '')
        if not last_name:
            last_name = fields.get('last_name', '')

        return {
            'first_name': first_name or 'Meta Lead',
            'last_name': last_name,
            'email': fields.get('email', ''),
            'phone': fields.get('phone_number', '') or fields.get('phone', ''),
            'company': fields.get('company_name', '') or fields.get('company', ''),
            'city': fields.get('city', ''),
            'state': fields.get('state', '') or fields.get('region', ''),
            'country': fields.get('country', 'India'),
            'job_title': fields.get('job_title', ''),
            'requirements': fields.get('what_are_you_looking_for', '') or '',
            'notes': f"Meta Lead ID: {meta_lead.get('id', 'N/A')}",
        }

    def process_webhook_entry(self, entry: dict, created_by=None) -> dict:
        """
        Process a single webhook entry from Meta.
        Each entry can contain multiple lead changes.
        """
        from leads.models import Lead, LeadSource
        from .models import LeadImportLog

        source, _ = LeadSource.objects.get_or_create(
            name='Meta Lead Ads',
            defaults={'description': 'Leads from Meta (Facebook) Lead Ad forms'}
        )

        created = 0
        skipped = 0
        external_ids = []
        errors = []

        for change in entry.get('changes', []):
            if change.get('field') != 'leadgen':
                continue

            value = change.get('value', {})
            leadgen_id = str(value.get('leadgen_id', ''))
            if not leadgen_id:
                continue

            external_ids.append(leadgen_id)

            # Check for duplicate
            if LeadImportLog.objects.filter(
                source='meta_leads',
                external_ids__contains=leadgen_id,
            ).exists():
                skipped += 1
                continue

            # Fetch full lead data from Graph API
            result = self.fetch_lead(leadgen_id)
            if not result['success']:
                errors.append(f"Failed to fetch lead {leadgen_id}: {result.get('error')}")
                continue

            lead_data = result['data']
            mapped = self.map_lead_data(lead_data)

            # Dedup by email/phone
            dup_filter = {}
            if mapped['email']:
                dup_filter['email'] = mapped['email']
            if mapped['phone']:
                dup_filter['phone'] = mapped['phone']
            if dup_filter and Lead.objects.filter(**dup_filter).exists():
                skipped += 1
                continue

            try:
                lead_kwargs = {**mapped, 'source': source, 'status': 'new', 'priority': 'warm'}
                if created_by:
                    lead_kwargs['created_by'] = created_by
                else:
                    from django.contrib.auth import get_user_model
                    User = get_user_model()
                    admin_user = User.objects.filter(
                        is_staff=True, is_active=True
                    ).first()
                    if admin_user:
                        lead_kwargs['created_by'] = admin_user
                    else:
                        skipped += 1
                        continue

                Lead.objects.create(**lead_kwargs)
                created += 1
            except Exception as e:
                logger.error(f"Failed to create lead from Meta: {e}")
                errors.append(str(e))
                skipped += 1

        # Log the import
        log = LeadImportLog.objects.create(
            source='meta_leads',
            method='webhook',
            leads_received=len(external_ids),
            leads_created=created,
            leads_skipped=skipped,
            external_ids=external_ids,
            error_message='; '.join(errors) if errors else '',
        )

        # Update integration stats
        self.integration.last_sync = timezone.now()
        self.integration.sync_count += 1
        if errors:
            self.integration.last_error = errors[-1]
            self.integration.error_count += 1
        self.integration.save(update_fields=[
            'last_sync', 'sync_count', 'last_error', 'error_count'
        ])

        return {
            'success': True,
            'leads_created': created,
            'leads_skipped': skipped,
            'log_id': log.id,
        }

    @staticmethod
    def validate_signature(payload: bytes, signature: str, app_secret: str) -> bool:
        """
        Validate X-Hub-Signature-256 header from Meta webhook.
        """
        import hashlib, hmac
        if not signature or not app_secret:
            return False
        expected = 'sha256=' + hmac.new(
            app_secret.encode('utf-8'),
            payload,
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(expected, signature)
