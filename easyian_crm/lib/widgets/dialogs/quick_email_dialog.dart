// widgets/dialogs/quick_email_dialog.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_client.dart';

class QuickEmailDialog extends StatefulWidget {
  final String toEmail, toName;
  final int? leadId, contactId;
  final VoidCallback? onSent;

  const QuickEmailDialog({
    super.key,
    required this.toEmail,
    required this.toName,
    this.leadId,
    this.contactId,
    this.onSent,
  });

  @override
  State<QuickEmailDialog> createState() => _QuickEmailDialogState();
}

class _QuickEmailDialogState extends State<QuickEmailDialog> {
  List<dynamic> _templates = [];
  dynamic _selectedTemplate;
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _selectedConfig = '';
  List<dynamic> _configs = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  bool _aiDrafting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final futures = await Future.wait([
        ApiClient.instance.get(AppConstants.emailTemplatesEndpoint),
        ApiClient.instance.get(AppConstants.emailConfigsEndpoint),
      ]);
      final tpl = futures[0] is List ? futures[0] : (futures[0]['results'] ?? []);
      final cfg = futures[1] is List ? futures[1] : (futures[1]['results'] ?? []);
      if (mounted) {
        setState(() {
          _templates = tpl;
          _configs = cfg;
          if (cfg.isNotEmpty) _selectedConfig = cfg[0]['id'].toString();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyTemplate(dynamic t) {
    final subject = (t['subject'] as String? ?? '')
        .replaceAll('{{name}}', widget.toName)
        .replaceAll('{{first_name}}', widget.toName.split(' ').first);
    var body = (t['body_html'] as String? ?? t['body_text'] as String? ?? '')
        .replaceAll('{{name}}', widget.toName)
        .replaceAll('{{first_name}}', widget.toName.split(' ').first);
    // Strip HTML tags for preview
    body = body.replaceAll(RegExp(r'<[^>]*>'), '');
    setState(() {
      _selectedTemplate = t;
      _subjectCtrl.text = subject;
      _bodyCtrl.text = body;
    });
  }

  Future<void> _aiDraft() async {
    setState(() => _aiDrafting = true);
    try {
      final result = await ApiClient.instance.post(
        '${AppConstants.aiEndpoint}draft_email/',
        body: {
          'to_name': widget.toName,
          'context': 'Follow up email to a sales lead',
          'tone': 'professional',
        },
      );
      if (mounted) {
        _subjectCtrl.text = result['subject'] ?? '';
        _bodyCtrl.text = result['body'] ?? '';
        setState(() => _aiDrafting = false);
      }
    } catch (_) {
      if (mounted) setState(() => _aiDrafting = false);
    }
  }

  Future<void> _send() async {
    if (_subjectCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Subject and body are required');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await ApiClient.instance.post(AppConstants.emailsEndpoint, body: {
        'to_email': widget.toEmail,
        'to_name': widget.toName,
        'subject': _subjectCtrl.text,
        'body_html': '<p>${_bodyCtrl.text.replaceAll('\n', '</p><p>')}</p>',
        'body_text': _bodyCtrl.text,
        if (widget.leadId != null) 'lead': widget.leadId,
        if (_selectedConfig.isNotEmpty) 'config': int.tryParse(_selectedConfig),
      });
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
        width: 560, height: 580,
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
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
                child: const Icon(Icons.email_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quick Email',
                    style: GoogleFonts.inter(
                        fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('To: ${widget.toName} <${widget.toEmail}>',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.white.withOpacity(0.85)),
                    overflow: TextOverflow.ellipsis),
              ])),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Template quick-select
              if (_templates.isNotEmpty) ...[
                Row(children: [
                  Text('Templates', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
                  const Spacer(),
                  // AI draft button
                  TextButton.icon(
                    onPressed: _aiDrafting ? null : _aiDraft,
                    icon: _aiDrafting
                        ? const SizedBox(width: 12, height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome, size: 14),
                    label: Text(_aiDrafting ? 'Drafting...' : 'AI Draft',
                        style: GoogleFonts.inter(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.purple),
                  ),
                ]),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _templates.length,
                    itemBuilder: (_, i) {
                      final t = _templates[i];
                      final sel = _selectedTemplate?['id'] == t['id'];
                      return InkWell(
                        onTap: () => _applyTemplate(t),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? Colors.blue.shade600 : Colors.transparent,
                            border: Border.all(
                                color: sel ? Colors.blue.shade600 : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t['name'] ?? '',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: sel ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText),
                                  fontWeight: FontWeight.w500)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // Config selector
              if (_configs.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedConfig.isEmpty ? null : _selectedConfig,
                  decoration: InputDecoration(
                    labelText: 'Send from',
                    labelStyle: GoogleFonts.inter(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _configs.map<DropdownMenuItem<String>>((c) =>
                    DropdownMenuItem(
                      value: c['id'].toString(),
                      child: Text(c['name'] ?? '', style: GoogleFonts.inter(fontSize: 13)),
                    )).toList(),
                  onChanged: (v) => setState(() => _selectedConfig = v ?? ''),
                ),
                const SizedBox(height: 12),
              ],
              // Subject
              TextField(
                controller: _subjectCtrl,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: GoogleFonts.inter(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              // Body
              TextField(
                controller: _bodyCtrl,
                maxLines: 8,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  labelStyle: GoogleFonts.inter(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ]),
          )),

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
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, size: 16),
                label: Text(_sending ? 'Sending...' : 'Send Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
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
