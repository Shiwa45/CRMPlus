// screens/tickets/ticket_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../core/utils/api_client.dart';
import '../../core/constants/app_constants.dart';

class TicketDetailScreen extends StatefulWidget {
  final int ticketId;
  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  TicketModel? _ticket;
  bool _loading = true;
  final _replyCtrl = TextEditingController();
  bool _isPublic = true;
  bool _sendingReply = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _replyCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final t = await TicketsService.instance.getTicket(widget.ticketId);
      if (mounted) setState(() { _ticket = t; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sendingReply = true);
    try {
      await ApiClient.instance.post(AppConstants.ticketRepliesEndpoint, body: {
        'ticket': _ticket!.id,
        'body': _replyCtrl.text,
        'is_internal': !_isPublic,
      });
      _replyCtrl.clear();
      _load();
    } catch (_) {}
    if (mounted) setState(() => _sendingReply = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_ticket == null) return const Scaffold(body: Center(child: Text('Ticket not found')));

    final t = _ticket!;
    final priorityColor = const {'urgent': Color(0xFFDC2626), 'high': Color(0xFFEA580C),
        'medium': Color(0xFFCA8A04), 'low': Color(0xFF16A34A)};
    final pc = priorityColor[t.priority] ?? const Color(0xFF6B7280);
    final statusColor = const {'open': Color(0xFF3B82F6), 'in_progress': Color(0xFF8B5CF6),
        'waiting': Color(0xFFCA8A04), 'resolved': Color(0xFF16A34A), 'closed': Color(0xFF6B7280)};
    final sc = statusColor[t.status] ?? const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: Column(children: [
        // ── Hero ────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E2235), const Color(0xFF111827)]
                  : [const Color(0xFF1E40AF), const Color(0xFF3B82F6)],
            ),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context)),
                const Spacer(),
                // Resolve button
                if (t.status != 'resolved' && t.status != 'closed')
                  ElevatedButton(
                    onPressed: () async {
                      await ApiClient.instance.patch(
                          '${AppConstants.ticketsEndpoint}${t.id}/', body: {'status': 'resolved'});
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Resolve'),
                  ),
              ]),
              const SizedBox(height: 8),
              // Ticket number
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#${t.id}', style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white,
                      fontFeatures: [const FontFeature.tabularFigures()])),
                ),
                const SizedBox(width: 10),
                _badge(t.status.replaceAll('_', ' ').toUpperCase(), sc),
                const SizedBox(width: 8),
                _badge(t.priority.toUpperCase(), pc),
              ]),
              const SizedBox(height: 10),
              Text(t.subject, style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Row(children: [
                if (t.contactName != null) ...[
                  const Icon(Icons.person_outline, size: 13, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text(t.contactName!, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  const SizedBox(width: 12),
                ],
                if (t.categoryName != null) ...[
                  const Icon(Icons.label_outline, size: 13, color: Colors.white60),
                  const SizedBox(width: 4),
                  Text(t.categoryName!, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                ],
              ]),
              const SizedBox(height: 12),
              // SLA indicators
              if (t.resolutionDue != null)
                _SlaBar(dueDate: t.resolutionDue!, label: 'Resolution SLA',
                    breached: t.slaBreached, isOverdue: t.isOverdue),
            ]),
          )),
        ),
        // ── Replies thread ───────────────────────────────────────────────
        Expanded(child: t.replies.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('No replies yet', style: GoogleFonts.inter(color: Colors.grey)),
                const SizedBox(height: 6),
                Text('Be the first to respond',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: t.replies.length,
                itemBuilder: (_, i) => _ReplyBubble(
                    reply: t.replies[i], isDark: isDark),
              )),
        // ── Reply composer ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder2)),
          ),
          child: Column(children: [
            // Internal / public toggle
            Row(children: [
              Text('Reply type:', style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
              const SizedBox(width: 12),
              _typeToggle('Public', _isPublic, Colors.blue, () => setState(() => _isPublic = true)),
              const SizedBox(width: 8),
              _typeToggle('Internal Note', !_isPublic, Colors.orange, () => setState(() => _isPublic = false)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(
                controller: _replyCtrl,
                maxLines: 3,
                minLines: 1,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: _isPublic ? 'Reply to customer...' : 'Internal note (not visible to customer)...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: !_isPublic
                      ? Colors.orange.withOpacity(0.05)
                      : (isDark ? AppColors.darkBg : Colors.grey.shade50),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: !_isPublic ? Colors.orange.shade200 : Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: !_isPublic ? Colors.orange.shade300 : Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              )),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _sendingReply ? null : _sendReply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_isPublic ? Colors.orange : Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _sendingReply
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(!_isPublic ? Icons.lock_outline : Icons.send, size: 18),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  Widget _typeToggle(String label, bool active, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? color : Colors.grey.shade300),
          ),
          child: Text(label, style: GoogleFonts.inter(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: active ? color : Colors.grey)),
        ),
      );
}

class _SlaBar extends StatelessWidget {
  final String dueDate, label;
  final bool breached, isOverdue;
  const _SlaBar({required this.dueDate, required this.label,
      required this.breached, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    DateTime? due;
    try { due = DateTime.parse(dueDate).toLocal(); } catch (_) {}
    final color = breached || isOverdue ? Colors.red : Colors.green;
    final icon = breached ? Icons.warning_amber : Icons.timer_outlined;
    final text = due == null ? dueDate : isOverdue
        ? 'Overdue by ${DateTime.now().difference(due).inHours}h'
        : 'Due ${DateFormat('dd MMM, hh:mm a').format(due)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text('$label: $text',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final TicketReplyModel reply;
  final bool isDark;
  const _ReplyBubble({required this.reply, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPublic = reply.isPublic;
    final bubbleColor = !isPublic
        ? Colors.orange.withOpacity(0.1)
        : (isDark ? AppColors.darkCard : Colors.white);
    final borderColor = !isPublic ? Colors.orange.withOpacity(0.4) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [if (isPublic) BoxShadow(
          color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16, backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
                ((reply.authorName ?? '').isNotEmpty ? reply.authorName![0] : '?').toUpperCase(),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reply.authorName ?? 'Unknown', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
            Text(_ago(reply.createdAt), style: GoogleFonts.inter(
                fontSize: 11, color: isDark ? AppColors.darkTextFaint : Colors.grey)),
          ]),
          const Spacer(),
          if (!isPublic) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.lock_outline, size: 11, color: Colors.orange),
              const SizedBox(width: 3),
              Text('INTERNAL', style: GoogleFonts.inter(
                  fontSize: 9, fontWeight: FontWeight.w800, color: Colors.orange)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Text(reply.body, style: GoogleFonts.inter(fontSize: 14, height: 1.5,
            color: isDark ? AppColors.darkText : AppColors.lightText)),
      ]),
    );
  }

  String _ago(String dt) {
    try {
      final d = DateTime.parse(dt).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 1) return DateFormat('dd MMM').format(d);
      if (diff.inHours >= 1) return '${diff.inHours}h ago';
      if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
      return 'just now';
    } catch (_) { return dt; }
  }
}
