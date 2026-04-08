import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/email_model.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_loader.dart';

class EmailTemplatesScreen extends StatefulWidget {
  const EmailTemplatesScreen({super.key});

  @override
  State<EmailTemplatesScreen> createState() => _EmailTemplatesScreenState();
}

class _EmailTemplatesScreenState extends State<EmailTemplatesScreen> {
  List<EmailTemplateModel> _templates = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await CommunicationsService.instance.getEmailTemplates(search: _search.isEmpty ? null : _search);
      setState(() => _templates = result['results'] as List<EmailTemplateModel>);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _createTemplate() {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => TemplateFormScreen(onSaved: _load)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: AppScaffoldController.openDrawer,
        ),
        title: Text('Templates', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search templates...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) { _search = v; _load(); },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTemplate,
        icon: const Icon(Icons.add),
        label: const Text('New Template'),
      ),
      body: _loading
          ? const Center(child: AppLoader())
          : _templates.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No templates found', style: GoogleFonts.inter(fontSize: 15, color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  itemBuilder: (_, i) => _TemplateTile(
                    template: _templates[i],
                    onEdit: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => TemplateFormScreen(template: _templates[i], onSaved: _load))),
                    onDelete: () async {
                      await CommunicationsService.instance.deleteEmailTemplate(_templates[i].id);
                      _load();
                    },
                  ),
                ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final EmailTemplateModel template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TemplateTile({required this.template, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_rounded, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(template.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(template.subject, style: GoogleFonts.inter(fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  overflow: TextOverflow.ellipsis),
            ])),
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit'),
                ])),
                const PopupMenuItem(value: 'delete', child: Row(children: [
                  Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error)),
                ])),
              ],
              onSelected: (v) { if (v == 'edit') onEdit(); else if (v == 'delete') onDelete(); },
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _chip(template.templateType, AppColors.accent),
            const SizedBox(width: 6),
            if (template.isShared) _chip('Shared', AppColors.success),
            if (!template.isActive) _chip('Inactive', AppColors.error),
            const Spacer(),
            Text('Used ${template.usageCount}×',
                style: GoogleFonts.inter(fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class TemplateFormScreen extends StatefulWidget {
  final EmailTemplateModel? template;
  final VoidCallback onSaved;
  const TemplateFormScreen({super.key, this.template, required this.onSaved});

  @override
  State<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _TemplateFormScreenState extends State<TemplateFormScreen> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _type = 'general';
  bool _isShared = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.template != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.template!.name;
      _subjectCtrl.text = widget.template!.subject;
      _bodyCtrl.text = widget.template!.bodyHtml;
      _type = widget.template!.templateType;
      _isShared = widget.template!.isShared;
      _isActive = widget.template!.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _subjectCtrl.dispose(); _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _subjectCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'subject': _subjectCtrl.text.trim(),
      'body_html': _bodyCtrl.text.trim(),
      'template_type': _type,
      'is_shared': _isShared,
      'is_active': _isActive,
    };
    try {
      if (_isEdit) {
        await CommunicationsService.instance.updateEmailTemplate(widget.template!.id, data);
      } else {
        await CommunicationsService.instance.createEmailTemplate(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Template' : 'New Template',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const AppLoader(size: 18) : Text('Save',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Template Name *')),
          const SizedBox(height: 12),
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject *')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Template Type'),
            items: ['general', 'welcome', 'follow_up', 'proposal', 'newsletter', 'promotion']
                .map((t) => DropdownMenuItem(value: t,
                    child: Text(t.replaceAll('_', ' ').split(' ')
                        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' '))))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyCtrl,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Email Body (HTML)',
              hintText: 'Enter your email content here...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Shared with team'),
            subtitle: const Text('Allow other users to use this template'),
            value: _isShared,
            onChanged: (v) => setState(() => _isShared = v),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

