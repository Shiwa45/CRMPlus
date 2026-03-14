import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';
import '../../services/leads_service.dart';
import '../../widgets/app_loader.dart';

class LeadSourcesScreen extends StatefulWidget {
  const LeadSourcesScreen({super.key});

  @override
  State<LeadSourcesScreen> createState() => _LeadSourcesScreenState();
}

class _LeadSourcesScreenState extends State<LeadSourcesScreen> {
  List<LeadSourceModel> _sources = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await LeadsService.instance.getLeadSources();
      setState(() => _sources = s);
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _addSource() {
    showDialog(
      context: context,
      builder: (_) => _SourceDialog(onSave: (name) async {
        await LeadsService.instance.createLeadSource({'name': name, 'is_active': true});
        _load();
      }),
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
        title: Text('Lead Sources', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSource,
        icon: const Icon(Icons.add),
        label: const Text('Add Source'),
      ),
      body: _loading
          ? const Center(child: AppLoader())
          : _sources.isEmpty
              ? Center(child: Text('No lead sources yet', style: GoogleFonts.inter(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sources.length,
                  itemBuilder: (_, i) {
                    final s = _sources[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.source_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: Text(s.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        subtitle: s.description != null
                            ? Text(s.description!, style: GoogleFonts.inter(fontSize: 12))
                            : null,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (s.isActive ? AppColors.success : AppColors.error).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(s.isActive ? 'Active' : 'Inactive',
                              style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: s.isActive ? AppColors.success : AppColors.error)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _SourceDialog extends StatefulWidget {
  final Future<void> Function(String) onSave;
  const _SourceDialog({required this.onSave});

  @override
  State<_SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends State<_SourceDialog> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Lead Source'),
      content: TextField(
        controller: _ctrl,
        decoration: const InputDecoration(labelText: 'Source Name', hintText: 'e.g. Website, Referral'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : () async {
            if (_ctrl.text.trim().isEmpty) return;
            setState(() => _saving = true);
            await widget.onSave(_ctrl.text.trim());
            if (mounted) Navigator.pop(context);
          },
          child: _saving ? const AppLoader(color: Colors.white, size: 18) : const Text('Save'),
        ),
      ],
    );
  }
}

