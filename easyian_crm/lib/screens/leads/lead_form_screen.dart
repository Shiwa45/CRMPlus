import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/lead_model.dart';
import '../../services/leads_service.dart';
import '../../widgets/app_loader.dart';

class LeadFormScreen extends StatefulWidget {
  final LeadModel? lead;
  const LeadFormScreen({super.key, this.lead});

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;
  List<LeadSourceModel> _sources = [];
  bool get _isEdit => widget.lead != null;

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _status = 'new';
  String _priority = 'warm';
  String _country = 'India';
  int? _sourceId;

  @override
  void initState() {
    super.initState();
    _loadSources();
    if (_isEdit) _prefill();
  }

  void _prefill() {
    final l = widget.lead!;
    _firstNameCtrl.text = l.firstName;
    _lastNameCtrl.text = l.lastName ?? '';
    _emailCtrl.text = l.email;
    _phoneCtrl.text = l.phone ?? '';
    _companyCtrl.text = l.company ?? '';
    _jobTitleCtrl.text = l.jobTitle ?? '';
    _addressCtrl.text = l.address ?? '';
    _cityCtrl.text = l.city ?? '';
    _stateCtrl.text = l.state ?? '';
    _postalCodeCtrl.text = l.postalCode ?? '';
    _budgetCtrl.text = l.budget?.toString() ?? '';
    _requirementsCtrl.text = l.requirements ?? '';
    _notesCtrl.text = l.notes ?? '';
    _status = l.status;
    _priority = l.priority;
    _country = l.country ?? 'India';
    _sourceId = l.sourceId;
  }

  @override
  void dispose() {
    for (final c in [_firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl, _companyCtrl,
      _jobTitleCtrl, _addressCtrl, _cityCtrl, _stateCtrl, _postalCodeCtrl, _budgetCtrl,
      _requirementsCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSources() async {
    try {
      final sources = await LeadsService.instance.getLeadSources();
      setState(() => _sources = sources);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final data = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim().isEmpty ? null : _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'company': _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      'job_title': _jobTitleCtrl.text.trim().isEmpty ? null : _jobTitleCtrl.text.trim(),
      'status': _status,
      'priority': _priority,
      'source': _sourceId,
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      'country': _country,
      'postal_code': _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
      'budget': _budgetCtrl.text.trim().isEmpty ? null : double.tryParse(_budgetCtrl.text.trim()),
      'requirements': _requirementsCtrl.text.trim().isEmpty ? null : _requirementsCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };
    try {
      if (_isEdit) {
        await LeadsService.instance.updateLead(widget.lead!.id, data);
      } else {
        await LeadsService.instance.createLead(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Lead' : 'Add Lead',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const AppLoader(size: 18)
                : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) _errorBanner(),
            _section('Basic Information'),
            _row([
              _field(_firstNameCtrl, 'First Name *', validator: (v) => v!.isEmpty ? 'Required' : null),
              _field(_lastNameCtrl, 'Last Name'),
            ]),
            _field(_emailCtrl, 'Email *',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v!.isEmpty ? 'Required' : (!v.contains('@') ? 'Invalid email' : null)),
            _field(_phoneCtrl, 'Phone', keyboardType: TextInputType.phone),
            _field(_companyCtrl, 'Company'),
            _field(_jobTitleCtrl, 'Job Title'),
            const SizedBox(height: 8),
            _section('Lead Status & Priority'),
            _dropdownRow(),
            _sourcePicker(),
            const SizedBox(height: 8),
            _section('Address'),
            _field(_addressCtrl, 'Address', maxLines: 2),
            _row([
              _field(_cityCtrl, 'City'),
              _field(_stateCtrl, 'State'),
            ]),
            _row([
              _field(_postalCodeCtrl, 'Postal Code'),
              _countryField(),
            ]),
            const SizedBox(height: 8),
            _section('Deal Information'),
            _field(_budgetCtrl, 'Budget (₹)', keyboardType: TextInputType.number),
            _field(_requirementsCtrl, 'Requirements', maxLines: 3),
            _field(_notesCtrl, 'Notes', maxLines: 3),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13))),
      ]),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: Text(title,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
              color: AppColors.primary)),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((w) => Expanded(child: Padding(
        padding: children.indexOf(w) == 0 ? const EdgeInsets.only(right: 6) : const EdgeInsets.only(left: 6),
        child: w,
      ))).toList(),
    );
  }

  Widget _dropdownRow() {
    return Row(children: [
      Expanded(child: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 12),
        child: DropdownButtonFormField<String>(
          value: _status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: ['new', 'contacted', 'qualified', 'proposal', 'negotiation', 'won', 'lost', 'on_hold']
              .map((s) => DropdownMenuItem(value: s,
                  child: Text(s.replaceAll('_', ' ').split(' ')
                      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' '))))
              .toList(),
          onChanged: (v) => setState(() => _status = v!),
        ),
      )),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 12),
        child: DropdownButtonFormField<String>(
          value: _priority,
          decoration: const InputDecoration(labelText: 'Priority'),
          items: const [
            DropdownMenuItem(value: 'hot', child: Text('🔥 Hot')),
            DropdownMenuItem(value: 'warm', child: Text('🌡️ Warm')),
            DropdownMenuItem(value: 'cold', child: Text('❄️ Cold')),
          ],
          onChanged: (v) => setState(() => _priority = v!),
        ),
      )),
    ]);
  }

  Widget _sourcePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int?>(
        value: _sourceId,
        decoration: const InputDecoration(labelText: 'Lead Source'),
        items: [
          const DropdownMenuItem(value: null, child: Text('None')),
          ..._sources.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
        ],
        onChanged: (v) => setState(() => _sourceId = v),
      ),
    );
  }

  Widget _countryField() {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 12),
      child: TextFormField(
        initialValue: _country,
        decoration: const InputDecoration(labelText: 'Country'),
        onChanged: (v) => _country = v,
      ),
    );
  }
}
