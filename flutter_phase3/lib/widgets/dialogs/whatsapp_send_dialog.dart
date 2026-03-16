// widgets/dialogs/whatsapp_send_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_client.dart';
import '../../models/models.dart';

class WhatsAppSendDialog extends StatefulWidget {
  final LeadModel lead;
  final VoidCallback? onSent;

  const WhatsAppSendDialog({super.key, required this.lead, this.onSent});

  @override
  State<WhatsAppSendDialog> createState() => _WhatsAppSendDialogState();
}

class _WhatsAppSendDialogState extends State<WhatsAppSendDialog> {
  List<dynamic> _templates = [];
  dynamic _selected;
  String _preview = '';
  bool _loading = true;
  bool _sending = false;
  String? _error;
  final Map<String, TextEditingController> _varCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    for (final c in _varCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final resp = await ApiClient.instance.get(AppConstants.waTemplatesEndpoint);
      final list = resp is List ? resp : (resp['results'] as List? ?? []);
      if (mounted) setState(() { _templates = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _selectTemplate(dynamic t) {
    setState(() {
      _selected = t;
      _varCtrls.clear();
      final vars = List<String>.from(t['variables'] ?? []);
      for (final v in vars) {
        _varCtrls[v] = TextEditingController(text: _defaultValue(v));
      }
      _updatePreview();
    });
  }

  String _defaultValue(String variable) {
    final l = widget.lead;
    return switch (variable) {
      'name'       => l.fullName,
      'first_name' => l.firstName,
      'last_name'  => l.lastName,
      'company'    => l.company ?? '',
      'phone'      => l.phone ?? '',
      'email'      => l.email,
      'lead_status'=> l.status,
      'budget'     => l.budget?.toString() ?? '',
      _            => '',
    };
  }

  void _updatePreview() {
    if (_selected == null) return;
    var body = _selected['body'] as String? ?? '';
    for (final e in _varCtrls.entries) {
      body = body.replaceAll('{{${e.key}}}', e.value.text.isNotEmpty ? e.value.text : '{{${e.key}}}');
    }
    // Also replace defaults not in vars
    body = body.replaceAll('{{name}}', widget.lead.fullName);
    setState(() => _preview = body);
  }

  Future<void> _send() async {
    if (_selected == null) return;
    setState(() { _sending = true; _error = null; });
    try {
      final vars = {for (final e in _varCtrls.entries) e.key: e.value.text};
      await ApiClient.instance.post(
        '${AppConstants.waTemplatesEndpoint}send_to_lead/',
        body: {
          'template_id': _selected['id'],
          'lead_id': widget.lead.id,
          'variables': vars,
        },
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSent?.call();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SizedBox(
        width: 560, height: 620,
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.whatsapp, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Send WhatsApp',
                    style: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('To: ${widget.lead.fullName} • ${widget.lead.phone ?? 'No phone'}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white.withOpacity(0.85))),
              ]),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF25D366)))
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Template list
                  SizedBox(
                    width: 200,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text('Templates',
                            style: GoogleFonts.inter(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
                      ),
                      Expanded(child: _templates.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('No templates found.\nCreate templates in Settings.',
                                  style: GoogleFonts.inter(fontSize: 12,
                                      color: isDark ? AppColors.darkTextFaint : Colors.grey)),
                            )
                          : ListView.builder(
                              itemCount: _templates.length,
                              itemBuilder: (_, i) {
                                final t = _templates[i];
                                final sel = _selected?['id'] == t['id'];
                                return InkWell(
                                  onTap: () => _selectTemplate(t),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? const Color(0xFF25D366).withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? const Color(0xFF25D366)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t['name'] ?? '',
                                            style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: sel
                                                    ? const Color(0xFF25D366)
                                                    : (isDark ? AppColors.darkText : AppColors.lightText))),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            (t['category'] ?? 'utility').toUpperCase(),
                                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.blue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )),
                    ]),
                  ),
                  VerticalDivider(width: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder2),
                  // Preview + variables
                  Expanded(child: _selected == null
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.touch_app_outlined, size: 40,
                              color: isDark ? AppColors.darkTextFaint : Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text('Select a template', style: GoogleFonts.inter(color: Colors.grey)),
                        ]))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Variable fields
                            if (_varCtrls.isNotEmpty) ...[
                              Text('Customize Variables',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
                              const SizedBox(height: 8),
                              ..._varCtrls.entries.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: TextField(
                                  controller: e.value,
                                  onChanged: (_) => _updatePreview(),
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: e.key.replaceAll('_', ' '),
                                    labelStyle: GoogleFonts.inter(fontSize: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                ),
                              )),
                              const Divider(height: 20),
                            ],
                            // Message preview
                            Text('Preview',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCF8C6),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Text(_preview.isEmpty ? (_selected?['body'] ?? '') : _preview,
                                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black87)),
                            ),
                          ]),
                        )),
                ])),

          // Error
          if (_error != null) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder2)),
            ),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                onPressed: (_selected == null || _sending) ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 16),
                label: Text(_sending ? 'Sending...' : 'Send Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}
