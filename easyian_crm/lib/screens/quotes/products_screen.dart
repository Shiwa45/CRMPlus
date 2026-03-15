// lib/screens/quotes/products_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<ProductModel> _products = [];
  List<ProductModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String? _filterType;
  ProductModel? _edit;
  bool _showForm = false;

  final _curr =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await QuotesService.instance.getProducts();
      setState(() {
        _products = list;
        _applyFilter();
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final matchSearch = q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.code.toLowerCase().contains(q) ||
            (p.hsnSacCode?.toLowerCase().contains(q) ?? false);
        final matchType = _filterType == null || p.productType == _filterType;
        return matchSearch && matchType;
      }).toList();
    });
  }

  Future<void> _delete(ProductModel p) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Delete "${p.name}"?',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            content: const Text(
                'This product will be removed from the catalog. Existing quote lines are unaffected.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await QuotesService.instance.deleteProduct(p.id);
    } catch (_) {}
    _load();
  }

  Widget _typeBadge(String type) {
    final isService = type == 'service';
    final color = isService ? AppColors.info : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4)),
      child: Text(type.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)));
  }

  Widget _statusBadge(bool active) {
    final color = active ? AppColors.success : AppColors.lightTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4)),
      child: Text(active ? 'Active' : 'Inactive',
          style: GoogleFonts.inter(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(
        child: Column(children: [
          PageHeader(
            title: 'Products & Services',
            subtitle: '${_filtered.length} items',
            actions: [
              CrmButton(
                  label: 'Add Product',
                  icon: Icons.add_rounded,
                  primary: true,
                  onPressed: () =>
                      setState(() { _edit = null; _showForm = true; })),
            ],
          ),
          TableToolbar(
            searchCtrl: _searchCtrl,
            searchHint: 'Search by name, code or HSN/SAC...',
            filters: [
              const SizedBox(width: 8),
              FilterDropdown<String?>(
                value: _filterType,
                hint: 'All Types',
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(
                      value: 'service', child: Text('Services')),
                  DropdownMenuItem(
                      value: 'product', child: Text('Products')),
                ],
                onChanged: (v) {
                  setState(() => _filterType = v);
                  _applyFilter();
                },
              ),
            ],
            actions: [
              Text('${_filtered.length} items',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted)),
            ],
          ),
          Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          Expanded(
            child: _loading && _filtered.isEmpty
                ? const TableShimmer(rows: 8)
                : _filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: _products.isEmpty
                            ? 'No products yet'
                            : 'No results found',
                        subtitle: _products.isEmpty
                            ? 'Add products or services to use them in quotes'
                            : 'Try adjusting your search or filter',
                        actionLabel:
                            _products.isEmpty ? 'Add Product' : null,
                        onAction: _products.isEmpty
                            ? () => setState(
                                () { _edit = null; _showForm = true; })
                            : null,
                      )
                    : DataTable2(
                        columnSpacing: 12,
                        horizontalMargin: 16,
                        minWidth: 860,
                        headingRowHeight: 40,
                        dataRowHeight: 52,
                        headingTextStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted),
                        columns: const [
                          DataColumn2(
                              label: Text('Name / Description'),
                              size: ColumnSize.L),
                          DataColumn2(
                              label: Text('Code'), size: ColumnSize.S),
                          DataColumn2(
                              label: Text('Type'), size: ColumnSize.S),
                          DataColumn2(
                              label: Text('HSN / SAC'),
                              size: ColumnSize.S),
                          DataColumn2(
                              label: Text('Unit Price'),
                              size: ColumnSize.M,
                              numeric: true),
                          DataColumn2(
                              label: Text('GST %'),
                              size: ColumnSize.S,
                              numeric: true),
                          DataColumn2(
                              label: Text('Unit'), size: ColumnSize.S),
                          DataColumn2(
                              label: Text('Status'),
                              size: ColumnSize.S),
                          DataColumn2(
                              label: Text('Actions'),
                              size: ColumnSize.S,
                              numeric: true),
                        ],
                        rows: _filtered
                            .map((p) => DataRow2(
                                  cells: [
                                    DataCell(Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(p.name,
                                              style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: isDark
                                                      ? AppColors.darkText
                                                      : AppColors
                                                          .lightText)),
                                          if (p.description != null &&
                                              p.description!.isNotEmpty)
                                            Text(p.description!,
                                                style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? AppColors
                                                            .darkTextMuted
                                                        : AppColors
                                                            .lightTextMuted),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                        ])),
                                    DataCell(Text(p.code,
                                        style: GoogleFonts.robotoMono(
                                            fontSize: 12))),
                                    DataCell(_typeBadge(p.productType)),
                                    DataCell(Text(p.hsnSacCode ?? '—',
                                        style: GoogleFonts.inter(
                                            fontSize: 12))),
                                    DataCell(Text(
                                        _curr.format(p.unitPrice),
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w700))),
                                    DataCell(Text('${p.gstRate}%',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary))),
                                    DataCell(Text(p.unit,
                                        style: GoogleFonts.inter(
                                            fontSize: 12))),
                                    DataCell(_statusBadge(p.isActive)),
                                    DataCell(Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.edit_rounded,
                                                  size: 15),
                                              padding: EdgeInsets.zero,
                                              onPressed: () => setState(
                                                  () {
                                                    _edit = p;
                                                    _showForm = true;
                                                  })),
                                          IconButton(
                                              icon: Icon(
                                                  Icons.delete_rounded,
                                                  size: 15,
                                                  color: AppColors.error),
                                              padding: EdgeInsets.zero,
                                              onPressed: () =>
                                                  _delete(p)),
                                        ])),
                                  ],
                                ))
                            .toList()),
          ),
        ]),
      ),

      // Form side panel
      if (_showForm)
        SidePanel(
          title: _edit != null ? 'Edit Product' : 'New Product',
          width: 480,
          onClose: () => setState(() { _showForm = false; _edit = null; }),
          child: _ProductForm(
            key: ValueKey(_edit?.id ?? 'new'),
            product: _edit,
            onSaved: () {
              setState(() { _showForm = false; _edit = null; });
              _load();
            },
          ),
        ),
    ]);
  }
}

// ── Product Form ──────────────────────────────────────────────────────────────
class _ProductForm extends StatefulWidget {
  final ProductModel? product;
  final VoidCallback onSaved;
  const _ProductForm({super.key, this.product, required this.onSaved});
  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _name  = TextEditingController();
  final _code  = TextEditingController();
  final _desc  = TextEditingController();
  final _hsn   = TextEditingController();
  final _price = TextEditingController();

  String _type   = 'service';
  String _unit   = 'nos';
  int    _gst    = 18;
  bool   _active = true;
  bool   _saving = false;

  static const _gstRates = [0, 5, 12, 18, 28];
  static const _units    = [
    'nos', 'hrs', 'days', 'kg', 'ltr', 'mtr', 'sqft', 'pcs', 'box', 'set'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text  = p.name;
      _code.text  = p.code;
      _desc.text  = p.description ?? '';
      _hsn.text   = p.hsnSacCode ?? '';
      _price.text = p.unitPrice.toStringAsFixed(2);
      _type       = p.productType;
      _unit       = p.unit;
      _gst        = p.gstRate;
      _active     = p.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _desc.dispose();
    _hsn.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _code.text.trim().isEmpty ||
        _price.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name, code and price are required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'name':         _name.text.trim(),
        'code':         _code.text.trim(),
        'description':  _desc.text.trim(),
        'hsn_sac_code': _hsn.text.trim(),
        'unit_price':   double.tryParse(_price.text.trim()) ?? 0,
        'product_type': _type,
        'unit':         _unit,
        'gst_rate':     _gst,
        'is_active':    _active,
      };
      if (widget.product != null) {
        await QuotesService.instance.updateProduct(widget.product!.id, body);
      } else {
        await QuotesService.instance.createProduct(body);
      }
      widget.onSaved();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Basic info ──────────────────────────────────────────────────────
        _sectionLabel('Basic Info', isDark),
        _fld('Name *', _name, isDark),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _fld('Product Code *', _code, isDark)),
          const SizedBox(width: 12),
          Expanded(child: _fld('HSN / SAC Code', _hsn, isDark)),
        ]),
        const SizedBox(height: 12),
        _fld('Description', _desc, isDark, maxLines: 3),
        const SizedBox(height: 20),

        // ── Classification ─────────────────────────────────────────────────
        _sectionLabel('Classification', isDark),
        Row(children: [
          Expanded(child: _drop<String>(
            'Type',
            [
              const DropdownMenuItem(value: 'service', child: Text('Service')),
              const DropdownMenuItem(value: 'product', child: Text('Product')),
            ],
            _type,
            (v) => setState(() => _type = v ?? 'service'),
            isDark,
          )),
          const SizedBox(width: 12),
          Expanded(child: _drop<String>(
            'Unit',
            _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
            _unit,
            (v) => setState(() => _unit = v ?? 'nos'),
            isDark,
          )),
        ]),
        const SizedBox(height: 20),

        // ── Pricing ────────────────────────────────────────────────────────
        _sectionLabel('Pricing & Tax', isDark),
        Row(children: [
          Expanded(child: _fld('Unit Price (₹) *', _price, isDark,
              keyboard: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _drop<int>(
            'GST Rate',
            _gstRates
                .map((r) => DropdownMenuItem(value: r, child: Text('$r%')))
                .toList(),
            _gst,
            (v) => setState(() => _gst = v ?? 18),
            isDark,
          )),
        ]),

        // ── GST preview ────────────────────────────────────────────────────
        if (_price.text.trim().isNotEmpty)
          _GstPreview(price: double.tryParse(_price.text) ?? 0, gstRate: _gst),

        const SizedBox(height: 20),

        // ── Status ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface2 : AppColors.lightSurface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Active',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text('Inactive products won\'t appear in the quote builder',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
            ])),
            Switch(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              activeColor: AppColors.success,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: CrmButton(
              label: widget.product != null ? 'Save Changes' : 'Add to Catalog',
              primary: true,
              loading: _saving,
              onPressed: _save),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
      );

  Widget _fld(String label, TextEditingController ctrl, bool isDark,
      {TextInputType? keyboard, int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)),
        const SizedBox(height: 4),
        TextField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder)))),
      ]);

  Widget _drop<T>(String label, List<DropdownMenuItem<T>> items, T? value,
          void Function(T?) cb, bool isDark) =>
      DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
              labelText: label,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))),
          items: items,
          onChanged: cb,
          style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppColors.darkText : AppColors.lightText));
}

// ── Live GST preview ──────────────────────────────────────────────────────────
class _GstPreview extends StatelessWidget {
  final double price;
  final int gstRate;
  const _GstPreview({required this.price, required this.gstRate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gst   = price * gstRate / 100;
    final total = price + gst;
    final curr  = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.15))),
      child: Row(children: [
        const Icon(Icons.calculate_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Wrap(spacing: 16, children: [
          _chip('Base', curr.format(price), isDark),
          _chip('GST ($gstRate%)', curr.format(gst), isDark),
          _chip('Total', curr.format(total), isDark, bold: true),
        ])),
      ]),
    );
  }

  Widget _chip(String label, String value, bool isDark, {bool bold = false}) =>
      RichText(
        text: TextSpan(
          style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
                text: value,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                    color: bold ? AppColors.primary : (isDark ? AppColors.darkText : AppColors.lightText))),
          ],
        ),
      );
}
