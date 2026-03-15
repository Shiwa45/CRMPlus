// lib/screens/quotes/invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../widgets/desktop_widgets.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});
  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<InvoiceModel> _invoices = [];
  bool _loading = true;
  int _total = 0, _page = 1;
  static const _pageSize = 50;
  String? _filterStatus;
  final _curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  InvoiceModel? _detail;
  bool _showPayment = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) setState(() => _page = 1);
    setState(() => _loading = true);
    try {
      final r = await QuotesService.instance
          .getInvoices(page: _page, status: _filterStatus);
      setState(() {
        _invoices = r['results'] as List<InvoiceModel>;
        _total = r['count'] as int;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String s) => switch (s) {
        'paid' => AppColors.success,
        'partially_paid' => AppColors.info,
        'sent' => AppColors.primary,
        'overdue' => AppColors.error,
        'draft' => AppColors.lightTextMuted,
        _ => AppColors.warning,
      };

  Widget _badge(String l, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(l.replaceAll('_', ' ').toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 11, color: c, fontWeight: FontWeight.w600)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(
          child: Column(children: [
        PageHeader(
          title: 'Invoices',
          subtitle: '$_total invoices',
          actions: [
            CrmButton(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: () => _load(reset: true),
                loading: _loading),
          ],
        ),
        TableToolbar(
          searchCtrl: null,
          searchHint: '',
          filters: [
            FilterDropdown<String?>(
              value: _filterStatus,
              hint: 'All Status',
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'sent', child: Text('Sent')),
                DropdownMenuItem(value: 'paid', child: Text('Paid')),
                DropdownMenuItem(
                    value: 'partially_paid', child: Text('Partial')),
                DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
              ],
              onChanged: (v) {
                setState(() => _filterStatus = v);
                _load(reset: true);
              },
            ),
          ],
          actions: [
            Text('$_total total',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted))
          ],
        ),
        Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        Expanded(
          child: _loading && _invoices.isEmpty
              ? const TableShimmer(rows: 8)
              : _invoices.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No invoices',
                      subtitle: 'Convert a quote to invoice to get started')
                  : DataTable2(
                      columnSpacing: 12,
                      horizontalMargin: 16,
                      minWidth: 900,
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
                            label: Text('Invoice #'), size: ColumnSize.S),
                        DataColumn2(
                            label: Text('Contact / Company'),
                            size: ColumnSize.M),
                        DataColumn2(
                            label: Text('Total'),
                            size: ColumnSize.M,
                            numeric: true),
                        DataColumn2(
                            label: Text('Paid'),
                            size: ColumnSize.M,
                            numeric: true),
                        DataColumn2(
                            label: Text('Due'),
                            size: ColumnSize.M,
                            numeric: true),
                        DataColumn2(
                            label: Text('Status'), size: ColumnSize.S),
                        DataColumn2(
                            label: Text('Due Date'), size: ColumnSize.M),
                        DataColumn2(
                            label: Text(''),
                            size: ColumnSize.S,
                            numeric: true),
                      ],
                      rows: _invoices
                          .map((inv) => DataRow2(
                                onTap: () => setState(() {
                                  _detail = inv;
                                  _showPayment = false;
                                }),
                                selected: _detail?.id == inv.id,
                                color: inv.status == 'overdue'
                                    ? MaterialStateProperty.all(
                                        AppColors.error.withOpacity(0.04))
                                    : null,
                                cells: [
                                  DataCell(Text(inv.invoiceNumber,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary))),
                                  DataCell(Text(
                                      inv.contactName ??
                                          inv.companyName ??
                                          '—',
                                      style:
                                          GoogleFonts.inter(fontSize: 12))),
                                  DataCell(Text(_curr.format(inv.grandTotal),
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700))),
                                  DataCell(Text(_curr.format(inv.amountPaid),
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600))),
                                  DataCell(Text(_curr.format(inv.amountDue),
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: inv.amountDue > 0
                                              ? AppColors.error
                                              : AppColors.success,
                                          fontWeight: FontWeight.w600))),
                                  DataCell(_badge(
                                      inv.status, _statusColor(inv.status))),
                                  DataCell(Text(inv.dueDate ?? '—',
                                      style:
                                          GoogleFonts.inter(fontSize: 12))),
                                  DataCell(inv.amountDue > 0
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons.payments_rounded,
                                              size: 15,
                                              color: AppColors.success),
                                          padding: EdgeInsets.zero,
                                          tooltip: 'Record Payment',
                                          onPressed: () => setState(() {
                                                _detail = inv;
                                                _showPayment = true;
                                              }))
                                      : const SizedBox.shrink()),
                                ],
                              ))
                          .toList()),
        ),
        if (_total > _pageSize)
          _Pager(
              page: _page,
              total: _total,
              pageSize: _pageSize,
              onPrev: () {
                setState(() => _page--);
                _load();
              },
              onNext: () {
                setState(() => _page++);
                _load();
              }),
      ])),

      // Detail panel
      if (_detail != null && !_showPayment)
        SidePanel(
            title: 'INV ${_detail!.invoiceNumber}',
            width: 380,
            onClose: () => setState(() => _detail = null),
            actions: [
              if (_detail!.amountDue > 0)
                TextButton.icon(
                    icon: const Icon(Icons.payments_rounded, size: 14),
                    label: const Text('Pay'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.success),
                    onPressed: () => setState(() => _showPayment = true)),
            ],
            child:
                _InvoiceDetail(invoice: _detail!, isDark: isDark, curr: _curr)),

      // Payment panel
      if (_showPayment && _detail != null)
        SidePanel(
            title: 'Record Payment',
            width: 400,
            onClose: () => setState(() => _showPayment = false),
            child: _PaymentForm(
                key: ValueKey(_detail!.id),
                invoice: _detail!,
                onSaved: () async {
                  setState(() => _showPayment = false);
                  try {
                    final updated = await QuotesService.instance
                        .getInvoice(_detail!.id);
                    setState(() => _detail = updated);
                  } catch (_) {}
                  _load();
                })),
    ]);
  }
}

// ── Invoice detail ────────────────────────────────────────────────────────────
class _InvoiceDetail extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isDark;
  final NumberFormat curr;
  const _InvoiceDetail(
      {required this.invoice, required this.isDark, required this.curr});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_curr_fmt(invoice.grandTotal),
              style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 4),
          Row(children: [
            Text('Paid: ${_curr_fmt(invoice.amountPaid)}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 12),
            Text('Due: ${_curr_fmt(invoice.amountDue)}',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: invoice.amountDue > 0
                        ? AppColors.error
                        : AppColors.success,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          if (invoice.contactName != null)
            _r(Icons.person_rounded, invoice.contactName!, isDark),
          if (invoice.companyName != null)
            _r(Icons.business_rounded, invoice.companyName!, isDark),
          if (invoice.dueDate != null)
            _r(Icons.event_rounded, 'Due: ${invoice.dueDate}', isDark),
          if (invoice.payments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('PAYMENTS',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted)),
            const SizedBox(height: 8),
            ...invoice.payments.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_curr_fmt(p.amount),
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                        Text(
                            '${p.method.toUpperCase()} · ${p.paymentDate}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted)),
                      ])),
                ]))),
          ],
        ]),
      );

  String _curr_fmt(double v) => curr.format(v);

  Widget _r(IconData icon, String v, bool isDark) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon,
            size: 14,
            color:
                isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
        const SizedBox(width: 8),
        Text(v,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.darkText : AppColors.lightText)),
      ]));
}

// ── Payment form ──────────────────────────────────────────────────────────────
class _PaymentForm extends StatefulWidget {
  final InvoiceModel invoice;
  final VoidCallback onSaved;
  const _PaymentForm({super.key, required this.invoice, required this.onSaved});
  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  final _amount = TextEditingController();
  final _txnId = TextEditingController();
  final _date = TextEditingController();
  String _method = 'upi';
  bool _saving = false;
  final _curr =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _amount.text = widget.invoice.amountDue.toStringAsFixed(2);
    _date.text = DateTime.now().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _amount.dispose();
    _txnId.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amount.text.trim());
    if (amt == null || amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _saving = true);
    try {
      await QuotesService.instance.recordPayment(widget.invoice.id, {
        'amount': amt,
        'method': _method,
        'payment_date': _date.text.trim(),
        if (_txnId.text.trim().isNotEmpty) 'transaction_id': _txnId.text.trim(),
      });
      widget.onSaved();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
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
          // Summary chip
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Invoice ${widget.invoice.invoiceNumber}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.info)),
                Text(_curr.format(widget.invoice.grandTotal),
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                Text(
                    'Outstanding: ${_curr.format(widget.invoice.amountDue)}',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.error)),
              ])),
          const SizedBox(height: 16),
          _fld('Amount (₹) *', _amount, isDark,
              keyboard: TextInputType.number),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
              value: _method,
              decoration: InputDecoration(
                  labelText: 'Payment Method',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6))),
              items: const [
                DropdownMenuItem(value: 'upi', child: Text('UPI')),
                DropdownMenuItem(
                    value: 'bank_transfer', child: Text('Bank Transfer')),
                DropdownMenuItem(value: 'card', child: Text('Card')),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'upi'),
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 12),
          _fld('Transaction ID / UTR', _txnId, isDark),
          const SizedBox(height: 12),
          _fld('Payment Date *', _date, isDark),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: CrmButton(
                  label: 'Record Payment',
                  primary: true,
                  loading: _saving,
                  onPressed: _save)),
        ]));
  }

  Widget _fld(String label, TextEditingController ctrl, bool isDark,
          {TextInputType? keyboard}) =>
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
}

class _Pager extends StatelessWidget {
  final int page, total, pageSize;
  final VoidCallback onPrev, onNext;
  const _Pager(
      {required this.page,
      required this.total,
      required this.pageSize,
      required this.onPrev,
      required this.onNext});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = (total / pageSize).ceil();
    return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder))),
        child: Row(children: [
          Text('Page $page of $pages',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: page > 1 ? onPrev : null),
          IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: page < pages ? onNext : null),
        ]));
  }
}
