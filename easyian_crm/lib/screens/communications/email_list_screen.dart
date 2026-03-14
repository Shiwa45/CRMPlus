import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/num_utils.dart';
import '../../models/email_model.dart';
import '../../services/dashboard_service.dart';

class EmailListScreen extends StatefulWidget {
  const EmailListScreen({super.key});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  List<EmailModel> _emails = [];
  bool _loading = true;
  int _totalCount = 0;
  String? _filterStatus;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() { _page = 1; _emails = []; _loading = true; });
    try {
      final result = await CommunicationsService.instance.getEmails(
        page: _page,
        status: _filterStatus,
      );
      final newEmails = result['results'] as List<EmailModel>;
      setState(() {
        _emails = reset ? newEmails : [..._emails, ...newEmails];
        _totalCount = toInt(result['count']);
      });
    } catch (_) {}
    setState(() => _loading = false);
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
        title: Text('Emails', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [null, 'pending', 'sent', 'failed', 'opened'].map((s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s == null ? 'All' : '${s[0].toUpperCase()}${s.substring(1)}'),
                  selected: _filterStatus == s,
                  onSelected: (_) {
                    setState(() => _filterStatus = s);
                    _load(reset: true);
                  },
                ),
              )).toList(),
            ),
          ),
        ),
      ),
      body: _loading && _emails.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _emails.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.email_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text('No emails found', style: GoogleFonts.inter(fontSize: 15, color: Colors.grey)),
                ]))
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      child: Row(children: [
                        Text('$_totalCount emails', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _emails.length,
                        itemBuilder: (_, i) => _EmailTile(email: _emails[i], isDark: isDark),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _EmailTile extends StatelessWidget {
  final EmailModel email;
  final bool isDark;
  const _EmailTile({required this.email, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(email.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.email_rounded, size: 18, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(email.subject, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text('To: ${email.toEmail}', style: GoogleFonts.inter(fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
              ])),
              _statusBadge(email.status, statusColor),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.access_time, size: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              const SizedBox(width: 4),
              Text(_formatDate(email.createdAt), style: GoogleFonts.inter(fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
              if (email.sentAt != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.send, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Sent ${_formatDate(email.sentAt!)}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.success)),
              ],
              if (email.openedAt != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.visibility, size: 12, color: AppColors.info),
                const SizedBox(width: 4),
                Text('Opened', style: GoogleFonts.inter(fontSize: 11, color: AppColors.info)),
              ],
            ]),
            if (email.errorMessage != null) ...[
              const SizedBox(height: 4),
              Text('Error: ${email.errorMessage}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.error),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
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
      case 'sent': return AppColors.success;
      case 'pending': return AppColors.warning;
      case 'failed': return AppColors.error;
      case 'opened': return AppColors.info;
      default: return AppColors.primary;
    }
  }

  String _formatDate(String dt) {
    try { return DateFormat('dd MMM, hh:mm a').format(DateTime.parse(dt).toLocal()); }
    catch (_) { return dt; }
  }
}

