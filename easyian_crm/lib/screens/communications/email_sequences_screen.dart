import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/email_model.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_loader.dart';

class EmailSequencesScreen extends StatefulWidget {
  const EmailSequencesScreen({super.key});

  @override
  State<EmailSequencesScreen> createState() => _EmailSequencesScreenState();
}

class _EmailSequencesScreenState extends State<EmailSequencesScreen> {
  List<EmailSequenceModel> _sequences = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await CommunicationsService.instance.getEmailSequences();
      setState(() => _sequences = s);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _create() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SequenceFormSheet(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: AppScaffoldController.openDrawer,
        ),
        title: Text('Sequences', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New Sequence'),
      ),
      body: _loading
          ? const Center(child: AppLoader())
          : _sequences.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.linear_scale_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No sequences yet', style: GoogleFonts.inter(fontSize: 15, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text('Create email sequences to automate follow-ups',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sequences.length,
                  itemBuilder: (_, i) {
                    final s = _sequences[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.linear_scale_rounded, color: AppColors.accent, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                            if (s.description != null)
                              Text(s.description!, style: GoogleFonts.inter(fontSize: 12,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              _chip('${s.stepsCount} steps', AppColors.primary),
                              const SizedBox(width: 6),
                              _chip(s.isActive ? 'Active' : 'Inactive',
                                  s.isActive ? AppColors.success : AppColors.error),
                            ]),
                          ])),
                        ]),
                      ),
                    );
                  },
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

class _SequenceFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _SequenceFormSheet({required this.onSaved});

  @override
  State<_SequenceFormSheet> createState() => _SequenceFormSheetState();
}

class _SequenceFormSheetState extends State<_SequenceFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await CommunicationsService.instance.createEmailSequence({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'is_active': _isActive,
      });
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
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New Sequence', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Sequence Name *')),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Active'),
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const AppLoader(color: Colors.white, size: 20) : const Text('Create Sequence'),
          ),
        ),
      ]),
    );
  }
}

