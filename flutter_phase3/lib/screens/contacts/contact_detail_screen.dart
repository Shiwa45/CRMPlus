// screens/contacts/contact_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/dialogs/whatsapp_send_dialog.dart';
import '../../widgets/dialogs/quick_email_dialog.dart';

class ContactDetailScreen extends StatefulWidget {
  final int contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen>
    with SingleTickerProviderStateMixin {
  ContactModel? _contact;
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final c = await ContactsService.instance.getContact(widget.contactId);
      if (mounted) setState(() { _contact = c; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_contact == null) return const Scaffold(body: Center(child: Text('Contact not found')));

    final c = _contact!;
    final initials = '${c.firstName.isNotEmpty ? c.firstName[0] : ''}${c.lastName?.isNotEmpty == true ? c.lastName![0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF5F3FF),
      body: Column(children: [
        // ── Hero ───────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1C1A3A), const Color(0xFF0D0B1F)]
                  : [const Color(0xFF7C3AED), const Color(0xFF4F46E5)],
            ),
          ),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Nav row
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                _iconBtn(Icons.edit_outlined, () {}),
                const SizedBox(width: 8),
                _iconBtn(Icons.more_horiz, () {}),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                // Avatar with company initial
                Stack(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
                    ),
                    child: Center(child: Text(initials,
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
                  ),
                  if (c.companyName != null)
                    Positioned(bottom: 0, right: 0, child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Center(child: Text(c.companyName![0].toUpperCase(),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800,
                              color: const Color(0xFF7C3AED)))),
                    )),
                ]),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.fullName, style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  if (c.jobTitle != null) Text(c.jobTitle!,
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  if (c.companyName != null) Row(children: [
                    Icon(Icons.business, size: 13, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 4),
                    Text(c.companyName!,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                  ]),
                  const SizedBox(height: 6),
                  if (c.doNotContact)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.block, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('DNC', style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)),
                      ]),
                    ),
                ])),
              ]),
              const SizedBox(height: 20),
              // Action buttons
              Row(children: [
                if (!c.doNotContact) ...[
                  _actionBtn(Icons.whatsapp, 'WhatsApp', const Color(0xFF25D366), () {
                    showDialog(context: context, builder: (_) =>
                        WhatsAppSendDialog(lead: _contactAsLead(c)));
                  }),
                  const SizedBox(width: 10),
                  _actionBtn(Icons.email_outlined, 'Email', Colors.blue.shade300, () {
                    showDialog(context: context, builder: (_) =>
                        QuickEmailDialog(toEmail: c.email ?? '', toName: c.fullName, contactId: c.id));
                  }),
                  const SizedBox(width: 10),
                ],
                _actionBtn(Icons.phone_outlined, 'Call', Colors.green.shade300, () {
                  if (c.phone != null) Clipboard.setData(ClipboardData(text: c.phone!));
                }),
                const SizedBox(width: 10),
                _actionBtn(Icons.note_add_outlined, 'Note', Colors.amber.shade300, () {}),
              ]),
            ]),
          )),
        ),
        // ── Tabs ───────────────────────────────────────────────────────────
        Container(
          color: isDark ? AppColors.darkSurface : Colors.white,
          child: TabBar(
            controller: _tabs,
            labelColor: const Color(0xFF7C3AED),
            unselectedLabelColor: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
            indicatorColor: const Color(0xFF7C3AED),
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 16), text: 'Info'),
              Tab(icon: Icon(Icons.handshake_outlined, size: 16), text: 'Deals'),
              Tab(icon: Icon(Icons.confirmation_num_outlined, size: 16), text: 'Tickets'),
            ],
          ),
        ),
        Expanded(child: TabBarView(controller: _tabs, children: [
          _ContactInfoTab(contact: c, isDark: isDark),
          _LinkedDealsTab(contactId: c.id, isDark: isDark),
          _LinkedTicketsTab(contactId: c.id, isDark: isDark),
        ])),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) =>
      Expanded(child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
          ]),
        ),
      ));

  // Adapt ContactModel to LeadModel shape for WhatsApp dialog
  dynamic _contactAsLead(ContactModel c) => _FakeLead(c);
}

// Adapter to reuse WhatsAppSendDialog with Contact
class _FakeLead {
  final ContactModel c;
  _FakeLead(this.c);
  String get fullName => c.fullName;
  String get firstName => c.firstName;
  String get lastName => c.lastName ?? '';
  String? get phone => c.phone;
  String get email => c.email ?? '';
  String? get company => c.companyName;
  String get status => 'contact';
  dynamic get budget => null;
  int get id => c.id;
  String get getFullName => c.fullName;
}

class _ContactInfoTab extends StatelessWidget {
  final ContactModel contact;
  final bool isDark;
  const _ContactInfoTab({required this.contact, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = contact;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _card('Contact Details', [
          if (c.email != null) _row(Icons.email_outlined, 'Email', c.email!),
          if (c.phone != null) _row(Icons.phone_outlined, 'Phone', c.phone!),
          if (c.mobile != null) _row(Icons.smartphone, 'Mobile', c.mobile!),
          if (c.linkedin != null) _row(Icons.link, 'LinkedIn', c.linkedin!),
        ], isDark),
        const SizedBox(height: 12),
        _card('Address', [
          if (c.city != null || c.state != null)
            _row(Icons.location_on_outlined, 'City/State', '${c.city ?? ''}, ${c.state ?? ''}'),
          if (c.pincode != null) _row(Icons.markunread_mailbox_outlined, 'Pincode', c.pincode!),
        ], isDark),
        const SizedBox(height: 12),
        if (c.tags.isNotEmpty) _card('Tags', [
          Wrap(spacing: 6, runSpacing: 6, children: c.tags.map((t) => Chip(
            label: Text(t, style: GoogleFonts.inter(fontSize: 11)),
            backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
            side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
            visualDensity: VisualDensity.compact,
          )).toList()),
        ], isDark),
      ]),
    );
  }

  Widget _card(String title, List<Widget> children, bool isDark) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
      const SizedBox(height: 10),
      if (children.isEmpty) Text('No info', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13))
      else ...children,
    ]),
  );

  Widget _row(IconData icon, String label, String value) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF7C3AED).withOpacity(0.7)),
        const SizedBox(width: 10),
        Text('$label: ', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13), overflow: TextOverflow.ellipsis)),
      ]));
}

class _LinkedDealsTab extends StatelessWidget {
  final int contactId;
  final bool isDark;
  const _LinkedDealsTab({required this.contactId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.handshake_outlined, size: 48, color: isDark ? AppColors.darkTextFaint : Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('Linked Deals', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Deals with this contact will appear here',
          style: GoogleFonts.inter(color: Colors.grey)),
    ]));
  }
}

class _LinkedTicketsTab extends StatelessWidget {
  final int contactId;
  final bool isDark;
  const _LinkedTicketsTab({required this.contactId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.confirmation_num_outlined, size: 48, color: isDark ? AppColors.darkTextFaint : Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('Support Tickets', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('Tickets for this contact will appear here', style: GoogleFonts.inter(color: Colors.grey)),
    ]));
  }
}
