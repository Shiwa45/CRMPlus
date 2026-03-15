// lib/screens/quotes/quotes_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});
  @override State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  List<QuoteModel> _quotes = [];
  bool _loading = true;
  int _total = 0, _page = 1;
  static const _pageSize = 50;
  String? _filterStatus;
  final _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  QuoteModel? _detail;
  bool _showForm = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    try {
      final r = await QuotesService.instance.getQuotes(page: _page, status: _filterStatus);
      setState(() { _quotes = r['results'] as List<QuoteModel>; _total = r['count'] as int; });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _convertToInvoice(QuoteModel q) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Convert to Invoice?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      content: Text('Quote #${q.quoteNumber} will become a draft invoice.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true), child: const Text('Convert')),
      ],
    )) ?? false;
    if (!ok) return;
    try {
      await QuotesService.instance.convertToInvoice(q.id);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice created!'), backgroundColor: AppColors.success));
      _load(reset: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Color _statusColor(String s) => switch (s) {
    'accepted' => AppColors.success,
    'sent'     => AppColors.info,
    'draft'    => AppColors.lightTextMuted,
    'expired'  => AppColors.warning,
    'rejected' => AppColors.error,
    _          => AppColors.primary,
  };

  Widget _badge(String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(l.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, color: c, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: Column(children: [
        PageHeader(
          title: 'Quotes', subtitle: '$_total quotes',
          actions: [
            CrmButton(label: 'New Quote', icon: Icons.add_rounded, primary: true,
                onPressed: () => setState(() { _showForm = true; _detail = null; })),
          ],
        ),
        TableToolbar(
          searchCtrl: null, searchHint: '',
          filters: [
            FilterDropdown<String?>(value: _filterStatus, hint: 'All Status',
              items: const [
                DropdownMenuItem(value: null,       child: Text('All Status')),
                DropdownMenuItem(value: 'draft',    child: Text('Draft')),
                DropdownMenuItem(value: 'sent',     child: Text('Sent')),
                DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'expired',  child: Text('Expired')),
              ],
              onChanged: (v) { setState(() => _filterStatus = v); _load(reset: true); }),
          ],
          actions: [Text('$_total total', style: GoogleFonts.inter(fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted))],
        ),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _quotes.isEmpty ? const TableShimmer(rows: 8)
              : _quotes.isEmpty ? EmptyState(icon: Icons.request_quote_outlined, title: 'No quotes yet',
                  subtitle: 'Create your first GST-compliant quote', actionLabel: 'New Quote',
                  onAction: () => setState(() { _showForm = true; _detail = null; }))
              : DataTable2(
                  columnSpacing: 12, horizontalMargin: 16, minWidth: 860,
                  headingRowHeight: 40, dataRowHeight: 48,
                  headingTextStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  columns: const [
                    DataColumn2(label: Text('Quote #'), size: ColumnSize.S),
                    DataColumn2(label: Text('Title'), size: ColumnSize.L),
                    DataColumn2(label: Text('Contact / Company'), size: ColumnSize.M),
                    DataColumn2(label: Text('Total'), size: ColumnSize.M, numeric: true),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    DataColumn2(label: Text('Date'), size: ColumnSize.M),
                    DataColumn2(label: Text('Actions'), size: ColumnSize.S, numeric: true),
                  ],
                  rows: _quotes.map((q) => DataRow2(
                    onTap: () => setState(() { _detail = q; _showForm = false; }),
                    selected: _detail?.id == q.id,
                    cells: [
                      DataCell(Text(q.quoteNumber, style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary))),
                      DataCell(Text(q.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis)),
                      DataCell(Text(q.contactName ?? q.companyName ?? '—', style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(Text(_curr.format(q.grandTotal), style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700))),
                      DataCell(_badge(q.status, _statusColor(q.status))),
                      DataCell(Text(q.quoteDate.length > 10 ? q.quoteDate.substring(0,10) : q.quoteDate,
                          style: GoogleFonts.inter(fontSize: 12))),
                      DataCell(Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        if (q.status == 'accepted' || q.status == 'sent')
                          IconButton(icon: const Icon(Icons.receipt_long_rounded, size: 15, color: AppColors.success),
                              padding: EdgeInsets.zero, tooltip: 'Convert to Invoice',
                              onPressed: () => _convertToInvoice(q)),
                        IconButton(icon: Icon(Icons.delete_rounded, size: 15, color: AppColors.error),
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              await QuotesService.instance.deleteQuote(q.id).catchError((_) {});
                              if (_detail?.id == q.id) setState(() => _detail = null);
                              _load(reset: true);
                            }),
                      ])),
                    ],
                  )).toList()),
        ),
        if (_total > _pageSize)
          _Pager(page: _page, total: _total, pageSize: _pageSize,
              onPrev: () { setState(() => _page--); _load(); },
              onNext: () { setState(() => _page++); _load(); }),
      ])),

      if (_detail != null && !_showForm)
        SidePanel(title: 'Quote ${_detail!.quoteNumber}', width: 400,
          onClose: () => setState(() => _detail = null),
          actions: [
            IconButton(icon: const Icon(Icons.edit_rounded, size: 16), padding: EdgeInsets.zero,
                onPressed: () {}),
          ],
          child: _QuoteDetailPanel(quote: _detail!, isDark: isDark, curr: _curr)),

      if (_showForm)
        SidePanel(title: 'New Quote', width: 560,
          onClose: () => setState(() => _showForm = false),
          child: _QuoteForm(key: const ValueKey('new'),
              onSaved: () { setState(() => _showForm = false); _load(); })),
    ]);
  }
}

class _QuoteDetailPanel extends StatelessWidget {
  final QuoteModel quote; final bool isDark; final NumberFormat curr;
  const _QuoteDetailPanel({required this.quote, required this.isDark, required this.curr});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(quote.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
      const SizedBox(height: 4),
      Text('Valid until: ${quote.validUntil ?? "—"}', style: GoogleFonts.inter(fontSize: 12,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(height: 16),
      // Line items
      Text('LINE ITEMS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 0.8, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(height: 8),
      ...quote.items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
            borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
            Text('${item.quantity} × ${curr.format(item.unitPrice)} · GST ${item.gstRate}%',
                style: GoogleFonts.inter(fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
          ])),
          Text(curr.format(item.amount), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
        ]))),
      const Divider(height: 16),
      // Totals
      _total('Subtotal',       curr.format(quote.subtotal),      isDark),
      if (quote.cgstTotal > 0) _total('CGST',  curr.format(quote.cgstTotal),      isDark),
      if (quote.sgstTotal > 0) _total('SGST',  curr.format(quote.sgstTotal),      isDark),
      if (quote.igstTotal > 0) _total('IGST',  curr.format(quote.igstTotal),      isDark),
      if (quote.cessTotal > 0) _total('Cess',  curr.format(quote.cessTotal),      isDark),
      const Divider(height: 8),
      _total('Grand Total', curr.format(quote.grandTotal), isDark, bold: true),
    ]),
  );

  Widget _total(String l, String v, bool isDark, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(l, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
      const Spacer(),
      Text(v, style: GoogleFonts.inter(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          color: bold ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText))),
    ]));
}

class _QuoteForm extends StatefulWidget {
  final VoidCallback onSaved;
  const _QuoteForm({super.key, required this.onSaved});
  @override State<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends State<_QuoteForm> {
  final _title     = TextEditingController();
  final _billName  = TextEditingController();
  final _billGstin = TextEditingController();
  bool _saving = false;
  int? _taxProfileId;
  List<TaxProfileModel> _taxProfiles = [];
  final List<Map<String, dynamic>> _lineItems = [];

  final _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() { super.initState(); _loadProfiles(); _addItem(); }

  Future<void> _loadProfiles() async {
    final profiles = await QuotesService.instance.getTaxProfiles().catchError((_) => <TaxProfileModel>[]);
    setState(() {
      _taxProfiles = profiles;
      if (profiles.isNotEmpty) _taxProfileId = profiles.first.id;
    });
  }

  void _addItem() => _lineItems.add({
    'name': TextEditingController(), 'quantity': TextEditingController(text: '1'),
    'unit_price': TextEditingController(), 'gst_rate': 18, 'discount_pct': 0.0,
  });

  void _removeItem(int i) => setState(() {
    (_lineItems[i]['name'] as TextEditingController).dispose();
    (_lineItems[i]['quantity'] as TextEditingController).dispose();
    (_lineItems[i]['unit_price'] as TextEditingController).dispose();
    _lineItems.removeAt(i);
  });

  double _lineTotal(Map<String, dynamic> item) {
    final qty = double.tryParse((item['quantity'] as TextEditingController).text) ?? 0;
    final price = double.tryParse((item['unit_price'] as TextEditingController).text) ?? 0;
    return qty * price;
  }

  @override
  void dispose() {
    _title.dispose(); _billName.dispose(); _billGstin.dispose();
    for (final item in _lineItems) {
      (item['name'] as TextEditingController).dispose();
      (item['quantity'] as TextEditingController).dispose();
      (item['unit_price'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _billName.text.trim().isEmpty || _taxProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title, Bill To, and Tax Profile are required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final items = _lineItems.asMap().entries.map((e) => {
        'name':         (e.value['name'] as TextEditingController).text.trim(),
        'quantity':     double.tryParse((e.value['quantity'] as TextEditingController).text) ?? 1,
        'unit_price':   double.tryParse((e.value['unit_price'] as TextEditingController).text) ?? 0,
        'gst_rate':     e.value['gst_rate'] as int,
        'discount_pct': e.value['discount_pct'] as double,
        'order':        e.key,
      }).toList();

      await QuotesService.instance.createQuote({
        'title':          _title.text.trim(),
        'bill_to_name':   _billName.text.trim(),
        'bill_to_gstin':  _billGstin.text.trim(),
        'tax_profile':    _taxProfileId,
        'supply_type':    'intra',
        'items':          items,
      });
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
      _fld('Quote Title *', _title, isDark), const SizedBox(height: 12),
      if (_taxProfiles.isNotEmpty) ...[
        DropdownButtonFormField<int>(value: _taxProfileId,
          decoration: InputDecoration(labelText: 'Tax Profile *', isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
          items: _taxProfiles.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
          onChanged: (v) => setState(() => _taxProfileId = v),
          style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
        const SizedBox(height: 12),
      ],
      _fld('Bill To Name *', _billName, isDark), const SizedBox(height: 12),
      _fld('Bill To GSTIN', _billGstin, isDark), const SizedBox(height: 20),

      Text('LINE ITEMS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700,
          letterSpacing: 0.6, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(height: 10),

      ..._lineItems.asMap().entries.map((e) => _LineItemRow(
        item: e.value, index: e.key, isDark: isDark,
        onRemove: _lineItems.length > 1 ? () { setState(() { _removeItem(e.key); }); } : null,
        onChanged: () => setState(() {}),
      )),

      TextButton.icon(
        onPressed: () => setState(() => _addItem()),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text('Add Line Item'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary)),

      const Divider(height: 24),
      // Summary
      _totalRow('Subtotal', _curr.format(_lineItems.fold(0.0, (s, item) => s + _lineTotal(item))), isDark),
      _totalRow('GST (approx)', _curr.format(_lineItems.fold(0.0, (s, item) =>
          s + _lineTotal(item) * (item['gst_rate'] as int) / 100)), isDark),
      const SizedBox(height: 8),
      Text('* Final taxes calculated on save', style: GoogleFonts.inter(fontSize: 10,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity,
        child: CrmButton(label: 'Create Quote', primary: true, loading: _saving, onPressed: _save)),
    ]));
  }

  Widget _totalRow(String l, String v, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(l, style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkText : AppColors.lightText)),
      const Spacer(),
      Text(v, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkText : AppColors.lightText)),
    ]));

  Widget _fld(String label, TextEditingController ctrl, bool isDark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        TextField(controller: ctrl, style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)))),
      ]);
}

class _LineItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final bool isDark;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;
  const _LineItemRow({required this.item, required this.index, required this.isDark,
    this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
    child: Column(children: [
      Row(children: [
        Expanded(flex: 4, child: _mini('Item name', item['name'] as TextEditingController, isDark, onChanged)),
        const SizedBox(width: 8),
        SizedBox(width: 60, child: _mini('Qty', item['quantity'] as TextEditingController, isDark, onChanged,
            keyboard: TextInputType.number)),
        const SizedBox(width: 8),
        SizedBox(width: 100, child: _mini('Price', item['unit_price'] as TextEditingController, isDark, onChanged,
            keyboard: TextInputType.number)),
        const SizedBox(width: 4),
        if (onRemove != null)
          IconButton(icon: Icon(Icons.remove_circle_rounded, size: 18, color: AppColors.error),
              padding: EdgeInsets.zero, onPressed: onRemove),
      ]),
    ]));

  Widget _mini(String hint, TextEditingController ctrl, bool isDark, VoidCallback onChange,
      {TextInputType? keyboard}) => TextField(
    controller: ctrl, onChanged: (_) => onChange(), keyboardType: keyboard,
    style: GoogleFonts.inter(fontSize: 12), decoration: InputDecoration(
      hintText: hint, isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder))));
}

class _Pager extends StatelessWidget {
  final int page, total, pageSize; final VoidCallback onPrev, onNext;
  const _Pager({required this.page, required this.total, required this.pageSize, required this.onPrev, required this.onNext});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = (total / pageSize).ceil();
    return Container(height: 44, padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder))),
      child: Row(children: [
        Text('Page $page of $pages', style: GoogleFonts.inter(fontSize: 12,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: page > 1 ? onPrev : null),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: page < pages ? onNext : null),
      ]));
  }
}
