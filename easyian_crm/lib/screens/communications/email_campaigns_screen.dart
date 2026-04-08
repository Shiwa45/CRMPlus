import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/num_utils.dart';
import '../../models/email_model.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_loader.dart';

class EmailCampaignsScreen extends StatefulWidget {
  const EmailCampaignsScreen({super.key});

  @override
  State<EmailCampaignsScreen> createState() => _EmailCampaignsScreenState();
}

class _EmailCampaignsScreenState extends State<EmailCampaignsScreen> {
  List<EmailCampaignModel> _campaigns = [];
  bool _loading = true;
  int _totalCount = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await CommunicationsService.instance.getEmailCampaigns();
      setState(() {
        _campaigns = result['results'] as List<EmailCampaignModel>;
        _totalCount = toInt(result['count']);
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _createCampaign() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CampaignFormSheet(onSaved: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: AppScaffoldController.openDrawer,
        ),
        title: Text('Campaigns', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCampaign,
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
      body: _loading
          ? const Center(child: AppLoader())
          : _campaigns.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No campaigns yet', style: GoogleFonts.inter(fontSize: 15, color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _campaigns.length,
                  itemBuilder: (_, i) => _CampaignCard(campaign: _campaigns[i]),
                ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final EmailCampaignModel campaign;
  const _CampaignCard({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(campaign.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(campaign.name,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700))),
            _statusBadge(campaign.status, statusColor),
          ]),
          if (campaign.description != null) ...[
            const SizedBox(height: 4),
            Text(campaign.description!, style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),

          // Progress bar
          if (campaign.totalRecipients > 0) ...[
            Row(children: [
              Text('Progress: ${campaign.progress.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${campaign.sentCount}/${campaign.totalRecipients}',
                  style: GoogleFonts.inter(fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: campaign.progress / 100,
                minHeight: 6,
                backgroundColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Stats row
          Row(children: [
            _stat('Sent', '${campaign.sentCount}', AppColors.primary),
            _stat('Opened', '${campaign.openCount}', AppColors.success),
            _stat('Clicked', '${campaign.clickCount}', AppColors.accent),
            _stat('Failed', '${campaign.failedCount}', AppColors.error),
          ]),
          const SizedBox(height: 8),
          Text(_formatDate(campaign.createdAt),
              style: GoogleFonts.inter(fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
      ]),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text('${status[0].toUpperCase()}${status.substring(1)}',
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'running': return AppColors.success;
      case 'completed': return AppColors.info;
      case 'paused': return AppColors.warning;
      case 'failed': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  String _formatDate(String dt) {
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(dt).toLocal()); }
    catch (_) { return dt; }
  }
}

class _CampaignFormSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _CampaignFormSheet({required this.onSaved});

  @override
  State<_CampaignFormSheet> createState() => _CampaignFormSheetState();
}

class _CampaignFormSheetState extends State<_CampaignFormSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await CommunicationsService.instance.createCampaign({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
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
        Text('New Campaign', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Campaign Name *')),
        const SizedBox(height: 12),
        TextField(controller: _descCtrl, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const AppLoader(color: Colors.white, size: 20) : const Text('Create Campaign'),
          ),
        ),
      ]),
    );
  }
}

