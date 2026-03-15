// lib/screens/contacts/contacts_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});
  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<ContactModel> _contacts = [];
  bool _loading = true;
  int _total = 0, _page = 1;
  static const _pageSize = 50;

  final _searchCtrl = TextEditingController();
  bool? _filterDnd;
  String _ordering = '-created_at';

  ContactModel? _detail;
  bool _showForm = false;
  ContactModel? _editContact;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _load(reset: true);
      });
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    try {
      final r = await ContactsService.instance.getContacts(
        page: _page, pageSize: _pageSize,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        dnd: _filterDnd, ordering: _ordering,
      );
      setState(() {
        _contacts = r['results'] as List<ContactModel>;
        _total    = r['count']   as int;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(ContactModel c) async {
    final ok = await _confirm('Delete ${c.fullName}?', 'This action cannot be undone.');
    if (!ok) return;
    await ContactsService.instance.deleteContact(c.id);
    _load(reset: true);
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete')),
      ],
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Contacts',
          subtitle: '$_total contacts',
          actions: [
            CrmButton(label: 'Add Contact', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() { _editContact = null; _showForm = true; })),
          ],
        ),
        TableToolbar(
          searchCtrl: _searchCtrl,
          searchHint: 'Search by name, email, phone, company...',
          filters: [
            const SizedBox(width: 8),
            FilterDropdown<bool?>(
              value: _filterDnd,
              hint: 'All Contacts',
              items: const [
                DropdownMenuItem(value: null,  child: Text('All')),
                DropdownMenuItem(value: false, child: Text('Active')),
                DropdownMenuItem(value: true,  child: Text('DND Only')),
              ],
              onChanged: (v) { setState(() => _filterDnd = v); _load(reset: true); },
            ),
          ],
          actions: [
            Text('$_total total', style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ],
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _contacts.isEmpty
              ? const TableShimmer(rows: 10)
              : _contacts.isEmpty
                  ? EmptyState(icon: Icons.contacts_outlined,
                      title: 'No contacts yet',
                      subtitle: 'Add your first contact to get started',
                      actionLabel: 'Add Contact',
                      onAction: () => setState(() { _editContact = null; _showForm = true; }))
                  : DataTable2(
                      columnSpacing: 12, horizontalMargin: 16,
                      minWidth: 800, headingRowHeight: 40, dataRowHeight: 48,
                      headingTextStyle: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      columns: const [
                        DataColumn2(label: Text('Name'), size: ColumnSize.L),
                        DataColumn2(label: Text('Company'), size: ColumnSize.M),
                        DataColumn2(label: Text('Phone / WhatsApp'), size: ColumnSize.M),
                        DataColumn2(label: Text('Email'), size: ColumnSize.M),
                        DataColumn2(label: Text('Status'), size: ColumnSize.S),
                        DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                      ],
                      rows: _contacts.map((c) => DataRow2(
                        onTap: () => setState(() { _detail = c; _showForm = false; }),
                        selected: _detail?.id == c.id,
                        cells: [
                          DataCell(Row(children: [
                            CircleAvatar(radius: 14,
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: Text(c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
                                      color: AppColors.primary))),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, children: [
                              Text(c.fullName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkText : AppColors.lightText)),
                              if (c.jobTitle != null)
                                Text(c.jobTitle!, style: GoogleFonts.inter(fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                            ]),
                          ])),
                          DataCell(Text(c.companyName ?? '—', style: GoogleFonts.inter(fontSize: 13,
                              color: isDark ? AppColors.darkText : AppColors.lightText))),
                          DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min, children: [
                            if (c.phone != null) Text(c.phone!, style: GoogleFonts.inter(fontSize: 12)),
                            if (c.whatsapp != null) Row(children: [
                              const Icon(Icons.chat_rounded, size: 11, color: Color(0xFF25D366)),
                              const SizedBox(width: 3),
                              Text(c.whatsapp!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF25D366))),
                            ]),
                          ])),
                          DataCell(Text(c.email ?? '—', style: GoogleFonts.inter(fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
                          DataCell(c.doNotContact
                              ? _badge('DND', AppColors.error)
                              : c.isActive ? _badge('Active', AppColors.success) : _badge('Inactive', AppColors.warning)),
                          DataCell(Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            IconButton(icon: const Icon(Icons.edit_rounded, size: 15), padding: EdgeInsets.zero,
                                onPressed: () => setState(() { _editContact = c; _showForm = true; _detail = null; })),
                            IconButton(icon: Icon(Icons.delete_rounded, size: 15, color: AppColors.error),
                                padding: EdgeInsets.zero, onPressed: () => _delete(c)),
                          ])),
                        ],
                      )).toList(),
                    ),
        ),
        if (_total > _pageSize)
          _Pager(page: _page, total: _total, pageSize: _pageSize,
              onPrev: () { setState(() => _page--); _load(); },
              onNext: () { setState(() => _page++); _load(); }),
      ])),

      // Detail / Form panel
      if (_detail != null && !_showForm)
        SidePanel(
          title: _detail!.fullName,
          width: 380,
          onClose: () => setState(() => _detail = null),
          actions: [
            IconButton(icon: const Icon(Icons.edit_rounded, size: 16), padding: EdgeInsets.zero,
                onPressed: () => setState(() { _editContact = _detail; _showForm = true; _detail = null; })),
          ],
          child: _ContactDetail(contact: _detail!, isDark: isDark),
        ),

      if (_showForm)
        SidePanel(
          title: _editContact != null ? 'Edit Contact' : 'New Contact',
          width: 480,
          onClose: () => setState(() { _showForm = false; _editContact = null; }),
          child: _ContactForm(
            key: ValueKey(_editContact?.id ?? 'new'),
            contact: _editContact,
            onSaved: () { setState(() { _showForm = false; _editContact = null; }); _load(); },
          ),
        ),
    ]);
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}

// ── Detail Panel ──────────────────────────────────────────────────────────────
class _ContactDetail extends StatelessWidget {
  final ContactModel contact;
  final bool isDark;
  const _ContactDetail({required this.contact, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Avatar
        Center(child: Column(children: [
          CircleAvatar(radius: 32,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(contact.fullName.isNotEmpty ? contact.fullName[0].toUpperCase() : '?',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary))),
          const SizedBox(height: 8),
          Text(contact.fullName, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          if (contact.jobTitle != null)
            Text(contact.jobTitle!, style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          if (contact.companyName != null) ...[
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.business_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(contact.companyName!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary,
                  fontWeight: FontWeight.w500)),
            ]),
          ],
        ])),
        const SizedBox(height: 20),

        _section('Contact Info', isDark),
        if (contact.email != null) _row(Icons.email_rounded, contact.email!, isDark),
        if (contact.phone != null) _row(Icons.phone_rounded, contact.phone!, isDark),
        if (contact.mobile != null) _row(Icons.smartphone_rounded, contact.mobile!, isDark),
        if (contact.whatsapp != null)
          _row(Icons.chat_rounded, contact.whatsapp!, isDark, color: const Color(0xFF25D366)),
        if (contact.linkedin != null) _row(Icons.link_rounded, contact.linkedin!, isDark),
        const SizedBox(height: 12),

        if (contact.city != null || contact.state != null) ...[
          _section('Location', isDark),
          _row(Icons.location_on_rounded,
              [contact.city, contact.state].where((e) => e != null).join(', '), isDark),
          const SizedBox(height: 12),
        ],

        if (contact.pan != null) ...[
          _section('Compliance', isDark),
          _row(Icons.badge_rounded, 'PAN: ${contact.pan}', isDark),
          const SizedBox(height: 12),
        ],

        _section('Tags', isDark),
        if (contact.tags.isEmpty)
          Text('No tags', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))
        else
          Wrap(spacing: 6, runSpacing: 4, children: contact.tags.map((t) =>
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(t, style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary)))).toList()),

        if (contact.doNotContact) ...[
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(6)),
            child: Row(children: [
              Icon(Icons.block_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Text('Do Not Contact', style: GoogleFonts.inter(
                  color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13)),
            ])),
        ],
      ]),
    );
  }

  Widget _section(String label, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label.toUpperCase(), style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
  );

  Widget _row(IconData icon, String value, bool isDark, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Icon(icon, size: 14, color: color ?? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13,
          color: color ?? (isDark ? AppColors.darkText : AppColors.lightText)))),
    ]),
  );
}

// ── Contact Form ──────────────────────────────────────────────────────────────
class _ContactForm extends StatefulWidget {
  final ContactModel? contact;
  final VoidCallback onSaved;
  const _ContactForm({super.key, this.contact, required this.onSaved});

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final Map<String, TextEditingController> _c = {};
  bool _saving = false, _dnd = false;

  final _fields = ['first_name', 'last_name', 'email', 'phone', 'mobile',
    'whatsapp', 'job_title', 'department', 'city', 'state', 'pan'];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) _c[f] = TextEditingController();
    final ct = widget.contact;
    if (ct != null) {
      _c['first_name']!.text  = ct.firstName;
      _c['last_name']!.text   = ct.lastName ?? '';
      _c['email']!.text       = ct.email ?? '';
      _c['phone']!.text       = ct.phone ?? '';
      _c['mobile']!.text      = ct.mobile ?? '';
      _c['whatsapp']!.text    = ct.whatsapp ?? '';
      _c['job_title']!.text   = ct.jobTitle ?? '';
      _c['department']!.text  = ct.department ?? '';
      _c['city']!.text        = ct.city ?? '';
      _c['state']!.text       = ct.state ?? '';
      _c['pan']!.text         = ct.pan ?? '';
      _dnd                    = ct.doNotContact;
    }
  }

  @override
  void dispose() { for (final c in _c.values) c.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_c['first_name']!.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('First name is required')));
      return;
    }
    setState(() => _saving = true);
    final body = {
      'first_name':   _c['first_name']!.text.trim(),
      'last_name':    _c['last_name']!.text.trim(),
      'email':        _c['email']!.text.trim(),
      'phone':        _c['phone']!.text.trim(),
      'mobile':       _c['mobile']!.text.trim(),
      'whatsapp':     _c['whatsapp']!.text.trim(),
      'job_title':    _c['job_title']!.text.trim(),
      'department':   _c['department']!.text.trim(),
      'city':         _c['city']!.text.trim(),
      'state':        _c['state']!.text.trim(),
      'pan':          _c['pan']!.text.trim(),
      'do_not_contact': _dnd,
    };
    try {
      if (widget.contact != null) {
        await ContactsService.instance.updateContact(widget.contact!.id, body);
      } else {
        await ContactsService.instance.createContact(body);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _fLabel('Basic Info', isDark),
        Row(children: [
          Expanded(child: _field('First Name *', _c['first_name']!)),
          const SizedBox(width: 12),
          Expanded(child: _field('Last Name', _c['last_name']!)),
        ]),
        const SizedBox(height: 12),
        _field('Job Title', _c['job_title']!),
        const SizedBox(height: 12),
        _field('Department', _c['department']!),
        const SizedBox(height: 20),

        _fLabel('Contact Details', isDark),
        _field('Email', _c['email']!, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field('Phone', _c['phone']!, keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _field('Mobile', _c['mobile']!, keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _field('WhatsApp', _c['whatsapp']!, keyboard: TextInputType.phone),
        const SizedBox(height: 20),

        _fLabel('Location', isDark),
        Row(children: [
          Expanded(child: _field('City', _c['city']!)),
          const SizedBox(width: 12),
          Expanded(child: _field('State', _c['state']!)),
        ]),
        const SizedBox(height: 20),

        _fLabel('Compliance (India)', isDark),
        _field('PAN Number', _c['pan']!),
        const SizedBox(height: 16),

        SwitchListTile(
          value: _dnd, onChanged: (v) => setState(() => _dnd = v),
          title: Text('Do Not Contact (DND)', style: GoogleFonts.inter(fontSize: 13)),
          subtitle: Text('Prevent emails/calls to this contact', style: GoogleFonts.inter(fontSize: 11)),
          contentPadding: EdgeInsets.zero, dense: true,
          activeColor: AppColors.error,
        ),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity,
          child: CrmButton(label: widget.contact != null ? 'Save Changes' : 'Create Contact',
              primary: true, loading: _saving, onPressed: _save)),
      ]),
    );
  }

  Widget _fLabel(String label, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
  );

  Widget _field(String label, TextEditingController ctrl,
      {TextInputType? keyboard}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl, keyboardType: keyboard,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        ),
      ),
    ]);
  }
}

// ─── Pager widget (reusable) ──────────────────────────────────────────────────
class _Pager extends StatelessWidget {
  final int page, total, pageSize;
  final VoidCallback onPrev, onNext;
  const _Pager({required this.page, required this.total, required this.pageSize,
    required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages  = (total / pageSize).ceil();
    return Container(
      height: 44, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder))),
      child: Row(children: [
        Text('Page $page of $pages ($total total)',
            style: GoogleFonts.inter(fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left_rounded),
            onPressed: page > 1 ? onPrev : null),
        IconButton(icon: const Icon(Icons.chevron_right_rounded),
            onPressed: page < pages ? onNext : null),
      ]),
    );
  }
}
