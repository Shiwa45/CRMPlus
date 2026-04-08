import re

def rebuild():
    with open(r'c:\Users\shiwa\crmpro-main\crmpro-main\easyian_crm\lib\screens\settings\settings_screen.dart', 'w', encoding='utf-8') as fw:
        # We know the content from the view_file from step 229, but let's just write the full file content directly here:
        content = """// screens/settings/settings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.settings, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Settings & Integrations',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text('Manage API keys, integrations & preferences',
                  style: GoogleFonts.inter(fontSize: 13,
                      color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
            ]),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.integration_instructions, size: 16), text: 'Integrations'),
              Tab(icon: Icon(Icons.chat, size: 16), text: 'WhatsApp'),
              Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'AI & Sarvam'),
              Tab(icon: Icon(Icons.tune, size: 16), text: 'General'),
            ],
          ),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _IntegrationsTab(isDark: isDark),
        _WhatsAppTab(isDark: isDark),
        _AITab(isDark: isDark),
        _GeneralTab(isDark: isDark),
      ])),
    ]);
  }
}

// ── Integrations Tab ──────────────────────────────────────────────────────────
class _IntegrationsTab extends StatefulWidget {
  final bool isDark;
  const _IntegrationsTab({required this.isDark});
  @override
  State<_IntegrationsTab> createState() => _IntegrationsTabState();
}

class _IntegrationsTabState extends State<_IntegrationsTab> {
  List<dynamic> _integrations = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.get(AppConstants.integrationsEndpoint);
      final list = r is List ? r : (r['results'] ?? []);
      if (mounted) setState(() { _integrations = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final services = [
      {'service': 'indiamart', 'icon': Icons.storefront, 'color': Colors.orange,
       'title': 'IndiaMART Leads', 'desc': 'Auto-import leads via Pull API & Webhooks'},
      {'service': 'meta_leads', 'icon': Icons.facebook, 'color': Colors.blueAccent,
       'title': 'Facebook Lead Ads', 'desc': 'Receive leads automatically from Meta'},
      {'service': 'whatsapp', 'icon': Icons.chat, 'color': const Color(0xFF25D366),
       'title': 'WhatsApp Business', 'desc': 'Send messages via Meta Cloud API'},
      {'service': 'gemini',   'icon': Icons.auto_awesome, 'color': Colors.deepPurple,
       'title': 'Google Gemini AI', 'desc': 'AI scoring, email drafting, marketing copy'},
      {'service': 'sarvam',   'icon': Icons.record_voice_over, 'color': Colors.orange,
       'title': 'Sarvam AI', 'desc': 'Voice calls, speech-to-text, Hindi/regional language'},
      {'service': 'sendgrid', 'icon': Icons.send, 'color': Colors.blue,
       'title': 'SendGrid', 'desc': 'Transactional & bulk email delivery'},
      {'service': 'razorpay', 'icon': Icons.payment, 'color': Colors.indigo,
       'title': 'Razorpay', 'desc': 'Payment collection & invoicing'},
    ];

    return ListView(padding: const EdgeInsets.all(24), children: [
      for (final s in services) () {
        final existing = _integrations.firstWhere(
          (i) => i['service'] == s['service'], orElse: () => null);
        return _IntegrationCard(
          service: s['service'] as String,
          icon: s['icon'] as IconData,
          color: s['color'] as Color,
          title: s['title'] as String,
          desc: s['desc'] as String,
          existing: existing,
          isDark: widget.isDark,
          onSaved: _load,
        );
      }(),
    ]);
  }
}

class _IntegrationCard extends StatefulWidget {
  final String service, title, desc;
  final IconData icon;
  final Color color;
  final dynamic existing;
  final bool isDark;
  final VoidCallback onSaved;

  const _IntegrationCard({
    required this.service, required this.icon, required this.color,
    required this.title, required this.desc,
    required this.existing, required this.isDark, required this.onSaved,
  });

  @override
  State<_IntegrationCard> createState() => _IntegrationCardState();
}

class _IntegrationCardState extends State<_IntegrationCard> {
  bool _expanded = false;
  bool _testing = false;
  bool _saving = false;
  final _keyCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  final _extraCtrl = TextEditingController();
  final _verifyTokenCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _keyCtrl.text = '';  // masked
      if (widget.service == 'meta_leads' && widget.existing['config'] != null) {
        _extraCtrl.text = widget.existing['config']['page_id'] ?? '';
        _verifyTokenCtrl.text = widget.existing['config']['verify_token'] ?? '';
      } else if (widget.service == 'whatsapp' && widget.existing['config'] != null) {
        _extraCtrl.text = widget.existing['config']['phone_number_id'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _keyCtrl.dispose(); _secretCtrl.dispose(); _extraCtrl.dispose(); _verifyTokenCtrl.dispose();
    super.dispose();
  }

  bool get _isConnected => widget.existing != null && widget.existing['is_enabled'] == true;

  Future<void> _save() async {
    if (_keyCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final body = {
        'service': widget.service,
        'api_key': _keyCtrl.text,
        if (_secretCtrl.text.isNotEmpty && widget.service != 'meta_leads') 'api_secret': _secretCtrl.text,
        'is_enabled': true,
      };

      if (widget.service == 'meta_leads') {
        final extraMap = <String, String>{};
        if (_extraCtrl.text.isNotEmpty) extraMap['page_id'] = _extraCtrl.text;
        if (_verifyTokenCtrl.text.isNotEmpty) extraMap['verify_token'] = _verifyTokenCtrl.text;
        if (_secretCtrl.text.isNotEmpty) extraMap['app_secret'] = _secretCtrl.text;
        if (extraMap.isNotEmpty) body['extra'] = jsonEncode(extraMap);
      } else if (widget.service == 'whatsapp' && _extraCtrl.text.isNotEmpty) {
        body['extra'] = _extraCtrl.text;
      }

      if (widget.existing != null) {
        await ApiClient.instance.patch(
            '${AppConstants.integrationsEndpoint}${widget.existing['id']}/', body: body);
      } else {
        await ApiClient.instance.post(AppConstants.integrationsEndpoint, body: body);
      }
      widget.onSaved();
      if (mounted) setState(() { _saving = false; _expanded = false; });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.title} saved!')));
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    if (widget.existing == null) return;
    setState(() => _testing = true);
    try {
      final r = await ApiClient.instance.post(
          '${AppConstants.integrationsEndpoint}${widget.existing['id']}/test/', body: {});
      final msg = r['message'] ?? (r['success'] == true ? 'Connection OK!' : 'Test failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        setState(() => _testing = false);
      }
    } catch (_) {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isConnected ? widget.color.withOpacity(0.3) : (isDark ? AppColors.darkBorder : AppColors.lightBorder2),
          width: _isConnected ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        // Header row
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText)),
                Text(widget.desc, style: GoogleFonts.inter(
                    fontSize: 12, color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
              ])),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 12, color: _isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(_isConnected ? 'Connected' : 'Not set',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _isConnected ? Colors.green : Colors.grey)),
                ]),
              ),
              const SizedBox(width: 8),
              Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                  color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
            ]),
          ),
        ),
        // Expanded form
        if (_expanded) Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Divider(),
            const SizedBox(height: 8),
            TextField(
              controller: _keyCtrl,
              obscureText: true,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                labelText: widget.service == 'meta_leads' ? 'Page Access Token' : 'API Key',
                hintText: widget.existing != null ? '••••••••••••' : 'Enter API key',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (widget.service == 'whatsapp') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _extraCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Phone Number ID (Meta)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
            if (widget.service == 'meta_leads') ...[
              const SizedBox(height: 10),
              TextField(
                controller: _extraCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Page ID',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _secretCtrl,
                obscureText: true,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'App Secret (Optional)',
                  hintText: 'For signature validation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _verifyTokenCtrl,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Verify Token',
                  hintText: 'e.g. my-custom-token',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
            if ((widget.service == 'indiamart' || widget.service == 'meta_leads') && widget.existing != null && widget.existing['webhook_url'] != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDark ? AppColors.darkSurface : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Webhook URL (${widget.service == 'indiamart' ? 'Push API' : 'Meta Config'})', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  SelectableText(widget.existing['webhook_url'].toString(), style: GoogleFonts.inter(fontSize: 12, color: widget.color)),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            Row(children: [
              if (widget.existing != null) ...[
                OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_tethering, size: 14),
                  label: Text(_testing ? 'Testing...' : 'Test'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: widget.color,
                      side: BorderSide(color: widget.color)),
                ),
                const SizedBox(width: 10),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color, foregroundColor: Colors.white),
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── WhatsApp Templates Tab ────────────────────────────────────────────────────
class _WhatsAppTab extends StatefulWidget {
  final bool isDark;
  const _WhatsAppTab({required this.isDark});
  @override
  State<_WhatsAppTab> createState() => _WhatsAppTabState();
}

class _WhatsAppTabState extends State<_WhatsAppTab> {
  List<dynamic> _templates = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.get(AppConstants.waTemplatesEndpoint);
      final list = r is List ? r : (r['results'] ?? []);
      if (mounted) setState(() { _templates = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Text('WhatsApp Templates (${_templates.length})',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showTemplateForm(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Template'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
          ),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _templates.length,
                  itemBuilder: (_, i) => _TemplateTile(
                    template: _templates[i], isDark: widget.isDark, onDeleted: _load,
                  ),
                )),
    ]);
  }

  Widget _empty() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.chat, size: 52, color: Color(0xFF25D366)),
    const SizedBox(height: 12),
    Text('No templates yet', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    Text('Create templates with {{variables}} for personalization',
        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
    const SizedBox(height: 20),
    ElevatedButton(
      onPressed: () => _showTemplateForm(context),
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
      child: const Text('Create First Template', style: TextStyle(color: Colors.white)),
    ),
  ]));

  void _showTemplateForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _TemplateFormDialog(onSaved: _load),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final dynamic template;
  final bool isDark;
  final VoidCallback onDeleted;

  const _TemplateTile({required this.template, required this.isDark, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final status = template['status'] ?? 'draft';
    final statusColors = {'approved': Colors.green, 'pending': Colors.orange,
        'rejected': Colors.red, 'draft': Colors.grey};
    final sc = statusColors[status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(template['name'] ?? '',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () async {
              await ApiClient.instance.delete(
                  '${AppConstants.waTemplatesEndpoint}${template['id']}/');
              onDeleted();
            },
          ),
        ]),
        const SizedBox(height: 6),
        Text(template['body'] ?? '',
            style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Wrap(spacing: 6, children: [
          for (final v in List.from(template['variables'] ?? []))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '{{$v}}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF25D366),
                ),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _TemplateFormDialog extends StatefulWidget {
  final VoidCallback onSaved;
  const _TemplateFormDialog({required this.onSaved});

  @override
  State<_TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends State<_TemplateFormDialog> {
  final _nameCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _headerCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  bool _saving = false;
  List<String> _detectedVars = [];

  void _detectVars(String text) {
    final matches = RegExp(r'\{\{(\w+)\}\}').allMatches(text);
    setState(() => _detectedVars = matches.map((m) => m.group(1)!).toSet().toList());
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.post(AppConstants.waTemplatesEndpoint, body: {
        'name': _nameCtrl.text,
        'body': _bodyCtrl.text,
        'header_text': _headerCtrl.text,
        'footer_text': _footerCtrl.text,
        'variables': _detectedVars,
        'category': 'utility',
        'status': 'draft',
      });
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 480, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New WhatsApp Template',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Use {{name}}, {{company}}, {{phone}}, {{email}}, {{lead_status}} as variables',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Template Name', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _bodyCtrl, maxLines: 5,
              onChanged: _detectVars,
              decoration: const InputDecoration(labelText: 'Message Body', border: OutlineInputBorder(),
                alignLabelWithHint: true)),
            if (_detectedVars.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                const Text('Detected: ', style: TextStyle(fontSize: 12)),
                for (final v in _detectedVars) Chip(label: Text('{{$v}}',
                    style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
              ]),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                child: Text(_saving ? 'Saving...' : 'Save Template',
                    style: const TextStyle(color: Colors.white)),
              ),
            ]),
          ],
        )),
      ),
    );
  }
}

// ── AI & Sarvam Tab ────────────────────────────────────────────────────────────
class _AITab extends StatelessWidget {
  final bool isDark;
  const _AITab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      _featureCard(
        icon: Icons.score, color: Colors.deepPurple,
        title: 'AI Lead Scoring',
        desc: 'Gemini analyses each lead and assigns a 0–100 score with recommended action.',
        badge: 'Growth+', isDark: isDark,
      ),
      _featureCard(
        icon: Icons.email_outlined, color: Colors.blue,
        title: 'AI Email Drafting',
        desc: 'One-click email drafts using context from the lead\'s profile and history.',
        badge: 'Growth+', isDark: isDark,
      ),
      _featureCard(
        icon: Icons.campaign_outlined, color: Colors.orange,
        title: 'Marketing Copy Generator',
        desc: 'Generate compelling ad copy, WhatsApp campaigns, and social posts via Gemini.',
        badge: 'Growth+', isDark: isDark,
      ),
      _featureCard(
        icon: Icons.record_voice_over, color: Colors.red,
        title: 'Sarvam Voice AI',
        desc: 'Hindi/regional language speech-to-text for call transcription and analysis.',
        badge: 'Professional+', isDark: isDark,
      ),
      _featureCard(
        icon: Icons.translate, color: Colors.teal,
        title: 'Message Translation',
        desc: 'Translate CRM messages between English, Hindi, Tamil, Telugu and more.',
        badge: 'Professional+', isDark: isDark,
      ),
      _featureCard(
        icon: Icons.smart_toy, color: Colors.indigo,
        title: 'AI CRM Assistant',
        desc: 'Chat with your CRM data — ask questions, get summaries, take actions.',
        badge: 'Growth+', isDark: isDark,
      ),
    ]);
  }

  Widget _featureCard({
    required IconData icon, required Color color,
    required String title, required String desc,
    required String badge, required bool isDark,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder2),
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge, style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(desc, style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextFaint : AppColors.lightTextFaint)),
          ])),
        ]),
      );
}

// ── General Tab ───────────────────────────────────────────────────────────────
class _GeneralTab extends StatelessWidget {
  final bool isDark;
  const _GeneralTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      Text('Email Configuration', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
      const SizedBox(height: 10),
      ListTile(
        leading: const Icon(Icons.mail_outline),
        title: const Text('Email Configs'),
        subtitle: const Text('SMTP / SendGrid / Gmail settings'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isDark ? AppColors.darkCard : Colors.white,
      ),
      const SizedBox(height: 20),
      Text('Notifications', style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
      const SizedBox(height: 10),
      ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: const Text('Notification Preferences'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isDark ? AppColors.darkCard : Colors.white,
      ),
    ]);
  }
}
"""
        fw.write(content)

rebuild()
