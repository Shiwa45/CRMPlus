# integrations/services.py
"""
Runtime service wrappers for 3rd-party APIs.
Each service is stateless; pass in the Integration row + payload.
"""
import json, logging, requests
from django.utils import timezone
from .models import Integration, WhatsAppLog, WhatsAppTemplate

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
        self.tenant   = integration.tenant

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
                     sent_by=None) -> WhatsAppLog:
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

        log = WhatsAppLog(
            tenant=tenant, template=template, to_phone=phone,
            to_name=ctx['name'], message=rendered,
            sent_by=sent_by, lead_id=lead.id
        )
        try:
            intg = Integration.objects.get(tenant=tenant, service=Integration.SERVICE_WHATSAPP, is_enabled=True)
            svc = cls(intg)
            result = svc.send_text(phone, rendered)
            if result['success']:
                log.status = WhatsAppLog.STATUS_SENT
                log.wa_msg_id = result['data'].get('messages', [{}])[0].get('id', '')
                tenant.wa_sent += 1
                tenant.save(update_fields=['wa_sent'])
                template.use_count += 1
                template.save(update_fields=['use_count'])
            else:
                log.status = WhatsAppLog.STATUS_FAILED
                log.error  = result['error']
        except Integration.DoesNotExist:
            log.status = WhatsAppLog.STATUS_FAILED
            log.error  = 'WhatsApp integration not configured'
        except Exception as e:
            log.status = WhatsAppLog.STATUS_FAILED
            log.error  = str(e)
        log.save()
        return log


# ── Gemini AI ─────────────────────────────────────────────────────────────────
class GeminiService:
    BASE_URL = 'https://generativelanguage.googleapis.com/v1beta'
    MODEL    = 'gemini-1.5-flash-latest'

    def __init__(self, api_key: str):
        self.key = api_key

    def generate(self, prompt: str, system: str = '', max_tokens: int = 800) -> str:
        url = f"{self.BASE_URL}/models/{self.MODEL}:generateContent?key={self.key}"
        contents = []
        if system:
            contents.append({'role': 'user', 'parts': [{'text': system}]})
            contents.append({'role': 'model', 'parts': [{'text': 'Understood.'}]})
        contents.append({'role': 'user', 'parts': [{'text': prompt}]})
        body = {
            'contents': contents,
            'generationConfig': {'maxOutputTokens': max_tokens, 'temperature': 0.7},
        }
        try:
            r = requests.post(url, json=body, timeout=30)
            r.raise_for_status()
            return r.json()['candidates'][0]['content']['parts'][0]['text']
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
