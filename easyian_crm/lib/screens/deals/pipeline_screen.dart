// lib/screens/deals/pipeline_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  List<PipelineModel> _pipelines = [];
  bool _loading = true;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await DealsService.instance.getPipelines();
      setState(() => _pipelines = list);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Pipeline',
          subtitle: '${_pipelines.length} pipelines',
          actions: [
            CrmButton(
              label: 'New Pipeline',
              icon: Icons.add_rounded,
              primary: true,
              onPressed: () => setState(() => _showForm = true),
            ),
          ],
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        Expanded(
          child: _loading
              ? const TableShimmer(rows: 6)
              : _pipelines.isEmpty
                  ? EmptyState(
                      icon: Icons.view_kanban_outlined,
                      title: 'No pipelines yet',
                      subtitle: 'Create your first pipeline to get started',
                      actionLabel: 'New Pipeline',
                      onAction: () => setState(() => _showForm = true),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _pipelines.length,
                      itemBuilder: (_, i) {
                        final p = _pipelines[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(
                                      p.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkText : AppColors.lightText,
                                      ),
                                    ),
                                    if (p.isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.successBg,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Default',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(
                                    p.description?.isNotEmpty == true
                                        ? p.description!
                                        : 'No description',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${p.stages.length} stages',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ])),

      if (_showForm)
        SidePanel(
          title: 'New Pipeline',
          width: 420,
          onClose: () => setState(() => _showForm = false),
          child: _PipelineForm(
            onSaved: () {
              setState(() => _showForm = false);
              _load();
            },
          ),
        ),
    ]);
  }
}

class _PipelineForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _PipelineForm({required this.onSaved});
  @override
  State<_PipelineForm> createState() => _PipelineFormState();
}

class _PipelineFormState extends State<_PipelineForm> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  bool _isDefault = false;
  bool _isActive = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pipeline name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await DealsService.instance.createPipeline({
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'is_default': _isDefault,
        'is_active': _isActive,
      });
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _field('Pipeline Name *', _name, isDark),
        const SizedBox(height: 12),
        _field('Description', _desc, isDark, maxLines: 4),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _isDefault,
          onChanged: (v) => setState(() => _isDefault = v ?? false),
          contentPadding: EdgeInsets.zero,
          title: const Text('Set as default pipeline'),
        ),
        CheckboxListTile(
          value: _isActive,
          onChanged: (v) => setState(() => _isActive = v ?? true),
          contentPadding: EdgeInsets.zero,
          title: const Text('Active'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: CrmButton(
            label: 'Create Pipeline',
            primary: true,
            loading: _saving,
            onPressed: _save,
          ),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, bool isDark,
      {int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
          ),
        ),
      ]);
}
