// lib/screens/contacts/companies_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});
  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  List<CompanyModel> _companies = [];
  bool _loading = true;
  int _total = 0, _page = 1;
  static const _pageSize = 50;
  final _searchCtrl = TextEditingController();
  String? _filterIndustry;
  CompanyModel? _detail;
  bool _showForm = false;
  CompanyModel? _edit;
  final _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static const _industries = [
    'Technology','Finance','Healthcare','Education','Manufacturing',
    'Retail','Real Estate','Media','Consulting','Other',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() =>
        Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _load(reset: true); }));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    try {
      final r = await ContactsService.instance.getCompanies(
        page: _page, search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        industry: _filterIndustry);
      setState(() { _companies = r['results'] as List<CompanyModel>; _total = r['count'] as int; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(CompanyModel co) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Delete ${co.name}?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: const Text('Associated contacts will lose their company link.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    )) ?? false;
    if (!ok) return;
    try { await ContactsService.instance.deleteCompany(co.id); } catch (_) {}
    if (_detail?.id == co.id) setState(() => _detail = null);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Companies', subtitle: '$_total companies',
          actions: [
            CrmButton(label: 'Add Company', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() { _edit = null; _showForm = true; _detail = null; })),
          ],
        ),
        TableToolbar(
          searchCtrl: _searchCtrl, searchHint: 'Search by name, GSTIN, email...',
          filters: [
            const SizedBox(width: 8),
            FilterDropdown<String?>(value: _filterIndustry, hint: 'All Industries',
              items: [const DropdownMenuItem(value: null, child: Text('All Industries')),
                ..._industries.map((i) => DropdownMenuItem(value: i, child: Text(i)))],
              onChanged: (v) { setState(() => _filterIndustry = v); _load(reset: true); }),
          ],
          actions: [Text('$_total total', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))],
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _companies.isEmpty ? const TableShimmer(rows: 10)
              : _companies.isEmpty
                  ? EmptyState(icon: Icons.business_outlined, title: 'No companies yet',
                      subtitle: 'Add your first company to get started', actionLabel: 'Add Company',
                      onAction: () => setState(() { _edit = null; _showForm = true; }))
                  : DataTable2(
                      columnSpacing: 12, horizontalMargin: 16,
                      minWidth: 820, headingRowHeight: 40, dataRowHeight: 52,
                      headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      columns: const [
                        DataColumn2(label: Text('Company'), size: ColumnSize.L),
                        DataColumn2(label: Text('Industry'), size: ColumnSize.M),
                        DataColumn2(label: Text('Contacts'), size: ColumnSize.S, numeric: true),
                        DataColumn2(label: Text('Annual Revenue'), size: ColumnSize.M, numeric: true),
                        DataColumn2(label: Text('City'), size: ColumnSize.M),
                        DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                      ],
                      rows: _companies.map((co) => DataRow2(
                        onTap: () => setState(() { _detail = co; _showForm = false; }),
                        selected: _detail?.id == co.id,
                        cells: [
                          DataCell(Row(children: [
                            Container(width: 32, height: 32,
                              decoration: BoxDecoration(color: AppColors.info.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6)),
                              alignment: Alignment.center,
                              child: Text(co.name[0].toUpperCase(), style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.info))),
                            const SizedBox(width: 10),
                            Column(crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, children: [
                              Text(co.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                              if (co.gstin != null) Text('GST: ${co.gstin}',
                                  style: GoogleFonts.inter(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                            ]),
                          ])),
                          DataCell(Text(co.industry ?? '—', style: GoogleFonts.inter(fontSize: 13))),
                          DataCell(Text('${co.contactsCount}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))),
                          DataCell(Text(co.annualRevenue != null ? _curr.format(co.annualRevenue) : '—',
                              style: GoogleFonts.inter(fontSize: 13))),
                          DataCell(Text(co.city ?? '—', style: GoogleFonts.inter(fontSize: 13))),
                          DataCell(Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            IconButton(icon: const Icon(Icons.edit_rounded, size: 15), padding: EdgeInsets.zero,
                                onPressed: () => setState(() { _edit = co; _showForm = true; _detail = null; })),
                            IconButton(icon: Icon(Icons.delete_rounded, size: 15, color: AppColors.error),
                                padding: EdgeInsets.zero, onPressed: () => _delete(co)),
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

      if (_detail != null && !_showForm)
        SidePanel(title: _detail!.name, width: 360, onClose: () => setState(() => _detail = null),
          actions: [IconButton(icon: const Icon(Icons.edit_rounded, size: 16), padding: EdgeInsets.zero,
              onPressed: () => setState(() { _edit = _detail; _showForm = true; _detail = null; }))],
          child: _CompanyDetail(company: _detail!, isDark: isDark, curr: _curr)),

      if (_showForm)
        SidePanel(title: _edit != null ? 'Edit Company' : 'New Company', width: 480,
          onClose: () => setState(() { _showForm = false; _edit = null; }),
          child: _CompanyForm(key: ValueKey(_edit?.id ?? 'new'), company: _edit,
              industries: _industries,
              onSaved: () { setState(() { _showForm = false; _edit = null; }); _load(); })),
    ]);
  }
}

class _CompanyDetail extends StatelessWidget {
  final CompanyModel company; final bool isDark; final NumberFormat curr;
  const _CompanyDetail({required this.company, required this.isDark, required this.curr});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(child: Column(children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.info.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)), alignment: Alignment.center,
          child: Text(company.name[0].toUpperCase(), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.info))),
        const SizedBox(height: 8),
        Text(company.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkText : AppColors.lightText), textAlign: TextAlign.center),
        if (company.industry != null)
          Text(company.industry!, style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      ])),
      const SizedBox(height: 20),
      Row(children: [
        _statChip('Contacts', '${company.contactsCount}'),
        const SizedBox(width: 8),
        if (company.annualRevenue != null) _statChip('Revenue', curr.format(company.annualRevenue)),
      ]),
      const SizedBox(height: 16),
      if (company.email != null)   _row(Icons.email_rounded,    company.email!,   isDark),
      if (company.phone != null)   _row(Icons.phone_rounded,    company.phone!,   isDark),
      if (company.website != null) _row(Icons.language_rounded, company.website!, isDark),
      if (company.gstin != null)   _row(Icons.receipt_long_rounded, 'GSTIN: ${company.gstin}', isDark),
      if (company.pan != null)     _row(Icons.badge_rounded,    'PAN: ${company.pan}',   isDark),
      if (company.city != null)    _row(Icons.location_on_rounded,
          [company.city, company.state].where((e) => e != null).join(', '), isDark),
    ]),
  );

  Widget _statChip(String l, String v) => Expanded(child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(v, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
      Text(l, style: GoogleFonts.inter(fontSize: 11,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
    ]),
  ));

  Widget _row(IconData icon, String value, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Icon(icon, size: 14, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 13,
          color: isDark ? AppColors.darkText : AppColors.lightText))),
    ]),
  );
}

class _CompanyForm extends StatefulWidget {
  final CompanyModel? company; final List<String> industries; final VoidCallback onSaved;
  const _CompanyForm({super.key, this.company, required this.industries, required this.onSaved});
  @override State<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<_CompanyForm> {
  final Map<String, TextEditingController> _c = {};
  String? _industry; bool _saving = false;
  final _fields = ['name','website','phone','email','annual_revenue','gstin','pan','city','state','postal_code'];

  @override
  void initState() {
    super.initState();
    for (final f in _fields) _c[f] = TextEditingController();
    final co = widget.company;
    if (co != null) {
      _c['name']!.text = co.name; _c['website']!.text = co.website ?? '';
      _c['phone']!.text = co.phone ?? ''; _c['email']!.text = co.email ?? '';
      _c['gstin']!.text = co.gstin ?? ''; _c['pan']!.text = co.pan ?? '';
      _c['city']!.text = co.city ?? ''; _c['state']!.text = co.state ?? '';
      _c['annual_revenue']!.text = co.annualRevenue?.toString() ?? '';
      _industry = co.industry;
    }
  }

  @override
  void dispose() { for (final c in _c.values) c.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_c['name']!.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company name is required'))); return;
    }
    setState(() => _saving = true);
    final body = {
      'name': _c['name']!.text.trim(), 'website': _c['website']!.text.trim(),
      'phone': _c['phone']!.text.trim(), 'email': _c['email']!.text.trim(),
      'gstin': _c['gstin']!.text.trim(), 'pan': _c['pan']!.text.trim(),
      'city': _c['city']!.text.trim(), 'state': _c['state']!.text.trim(),
      'postal_code': _c['postal_code']!.text.trim(),
      if (_industry != null) 'industry': _industry,
      if (_c['annual_revenue']!.text.trim().isNotEmpty)
        'annual_revenue': double.tryParse(_c['annual_revenue']!.text.trim()) ?? 0,
    };
    try {
      widget.company != null
          ? await ContactsService.instance.updateCompany(widget.company!.id, body)
          : await ContactsService.instance.createCompany(body);
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
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      _fld('Company Name *', _c['name']!, isDark),   const SizedBox(height: 12),
      _fld('Website',        _c['website']!, isDark), const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _industry,
        decoration: InputDecoration(labelText: 'Industry', isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
        items: [const DropdownMenuItem(value: null, child: Text('Select industry')),
          ...widget.industries.map((i) => DropdownMenuItem(value: i, child: Text(i)))],
        onChanged: (v) => setState(() => _industry = v),
        style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _fld('Phone', _c['phone']!, isDark)),
        const SizedBox(width: 12), Expanded(child: _fld('Email', _c['email']!, isDark))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _fld('GSTIN', _c['gstin']!, isDark)),
        const SizedBox(width: 12), Expanded(child: _fld('PAN', _c['pan']!, isDark))]),
      const SizedBox(height: 12),
      _fld('Annual Revenue (₹)', _c['annual_revenue']!, isDark, keyboard: TextInputType.number),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: _fld('City', _c['city']!, isDark)),
        const SizedBox(width: 12), Expanded(child: _fld('State', _c['state']!, isDark))]),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: CrmButton(
        label: widget.company != null ? 'Save Changes' : 'Create Company',
        primary: true, loading: _saving, onPressed: _save)),
    ]));
  }

  Widget _fld(String label, TextEditingController ctrl, bool isDark, {TextInputType? keyboard}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        TextField(controller: ctrl, keyboardType: keyboard, style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)))),
      ]);
}

class _Pager extends StatelessWidget {
  final int page, total, pageSize;
  final VoidCallback onPrev, onNext;
  const _Pager({required this.page, required this.total, required this.pageSize, required this.onPrev, required this.onNext});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = (total / pageSize).ceil();
    return Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder))),
      child: Row(children: [
        Text('Page $page of $pages ($total total)', style: GoogleFonts.inter(fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: page > 1 ? onPrev : null),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: page < pages ? onNext : null),
      ]));
  }
}
