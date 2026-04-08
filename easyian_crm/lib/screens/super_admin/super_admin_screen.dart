// screens/super_admin/super_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_client.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});
  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        color: isDark ? AppColors.darkSurface : Colors.white,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFF9333EA)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Super Admin',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkText : AppColors.lightText)),
              Text('Manage tenants, plans & platform settings',
                  style: GoogleFonts.inter(fontSize: 13,
                      color: isDark ? AppColors.darkTextSub : AppColors.lightTextSub)),
            ]),
          ]),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabs,
            labelColor: const Color(0xFFDC2626),
            unselectedLabelColor: isDark ? AppColors.darkTextSub : AppColors.lightTextSub,
            indicatorColor: const Color(0xFFDC2626),
            tabs: const [
              Tab(icon: Icon(Icons.business, size: 16), text: 'Tenants'),
              Tab(icon: Icon(Icons.card_membership, size: 16), text: 'Plans'),
              Tab(icon: Icon(Icons.analytics_outlined, size: 16), text: 'Platform Stats'),
            ],
          ),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tabs, children: [
        _TenantsTab(isDark: isDark),
        _PlansTab(isDark: isDark),
        _PlatformStatsTab(isDark: isDark),
      ])),
    ]);
  }
}

// ── Tenants Tab ───────────────────────────────────────────────────────────────
class _TenantsTab extends StatefulWidget {
  final bool isDark;
  const _TenantsTab({required this.isDark});
  @override
  State<_TenantsTab> createState() => _TenantsTabState();
}

class _TenantsTabState extends State<_TenantsTab> {
  List<dynamic> _tenants = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.get(AppConstants.tenantsEndpoint);
      final list = r is List ? r : (r['results'] ?? []);
      if (mounted) setState(() { _tenants = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered => _search.isEmpty
      ? _tenants
      : _tenants.where((t) =>
          (t['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search tenants...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          )),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showCreateTenant(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Tenant'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
          ),
        ]),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _TenantRow(
                tenant: _filtered[i], isDark: widget.isDark, onChanged: _load,
              ),
            )),
    ]);
  }

  void _showCreateTenant(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CreateTenantDialog(onCreated: _load),
    );
  }
}

class _TenantRow extends StatelessWidget {
  final dynamic tenant;
  final bool isDark;
  final VoidCallback onChanged;

  const _TenantRow({required this.tenant, required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final status = tenant['status'] ?? 'trial';
    final statusColors = {
      'active': Colors.green, 'trial': Colors.blue,
      'suspended': Colors.red, 'expired': Colors.grey,
    };
    final sc = statusColors[status] ?? Colors.grey;
    final plan = tenant['plan_name'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        // Avatar
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.primaries[tenant['name'].hashCode.abs() % Colors.primaries.length],
              Colors.primaries[(tenant['name'].hashCode.abs() + 3) % Colors.primaries.length],
            ]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(
            (tenant['name'] as String? ?? '?')[0].toUpperCase(),
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          )),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tenant['name'] ?? '', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          Row(children: [
            Icon(Icons.people_outline, size: 13, color: Colors.grey),
            const SizedBox(width: 3),
            Text('${tenant['user_count'] ?? 0} users',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(width: 10),
            Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
            const SizedBox(width: 3),
            Text(tenant['city'] ?? 'India',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          ]),
        ])),
        // Plan badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(plan, style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        const SizedBox(width: 10),
        // Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status.toUpperCase(), style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
        ),
        const SizedBox(width: 8),
        // Actions
        PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 18),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
            const PopupMenuItem(value: 'activate', child: Text('Activate')),
            const PopupMenuItem(value: 'change_plan', child: Text('Change Plan')),
            const PopupMenuItem(value: 'view_users', child: Text('View Users')),
          ],
          onSelected: (v) async {
            if (v == 'suspend') {
              await ApiClient.instance.post(
                  '${AppConstants.tenantsEndpoint}${tenant['id']}/suspend/', body: {});
              onChanged();
            } else if (v == 'activate') {
              await ApiClient.instance.post(
                  '${AppConstants.tenantsEndpoint}${tenant['id']}/activate/', body: {});
              onChanged();
            }
          },
        ),
      ]),
    );
  }
}

class _CreateTenantDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const _CreateTenantDialog({required this.onCreated});

  @override
  State<_CreateTenantDialog> createState() => _CreateTenantDialogState();
}

class _CreateTenantDialogState extends State<_CreateTenantDialog> {
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  List<dynamic> _plans = [];
  String? _selectedPlan;
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final r = await ApiClient.instance.get(AppConstants.plansEndpoint);
      final list = r is List ? r : (r['results'] ?? []);
      if (mounted) setState(() {
        _plans = list;
        if (list.isNotEmpty) _selectedPlan = list[0]['id'].toString();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final slug = _slugCtrl.text.isEmpty
          ? _nameCtrl.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          : _slugCtrl.text;
      await ApiClient.instance.post(AppConstants.tenantsEndpoint, body: {
        'name': _nameCtrl.text,
        'slug': slug,
        'email': _emailCtrl.text,
        'phone': _phoneCtrl.text,
        'plan': int.tryParse(_selectedPlan ?? '') ?? 1,
        'status': 'trial',
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: _loading ? const Padding(padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()))
          : Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 440, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create New Tenant',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Company Name *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _slugCtrl,
                decoration: const InputDecoration(labelText: 'Slug (auto-generated)', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedPlan,
              decoration: const InputDecoration(labelText: 'Plan', border: OutlineInputBorder()),
              items: _plans.map<DropdownMenuItem<String>>((p) =>
                DropdownMenuItem(
                  value: p['id'].toString(),
                  child: Text('${p['display_name']} — ₹${p['monthly_price']}/mo'),
                )).toList(),
              onChanged: (v) => setState(() => _selectedPlan = v),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saving ? null : _create,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                child: Text(_saving ? 'Creating...' : 'Create Tenant',
                    style: const TextStyle(color: Colors.white)),
              ),
            ]),
          ],
        )),
      ),
    );
  }
}

// ── Plans Tab ─────────────────────────────────────────────────────────────────
class _PlansTab extends StatefulWidget {
  final bool isDark;
  const _PlansTab({required this.isDark});
  @override
  State<_PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<_PlansTab> {
  List<dynamic> _plans = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.get(AppConstants.plansEndpoint);
      final list = r is List ? r : (r['results'] ?? []);
      if (mounted) setState(() { _plans = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final curr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final planColors = [Colors.grey, Colors.blue, Colors.deepPurple, Colors.orange];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
      itemCount: _plans.length,
      itemBuilder: (_, i) {
        final p = _plans[i];
        final color = planColors[i % planColors.length];
        final feats = <String>[];
        if (p['feat_whatsapp'] == true) feats.add('WhatsApp');
        if (p['feat_ai_assistant'] == true) feats.add('AI Assistant');
        if (p['feat_ai_calls'] == true) feats.add('AI Calls');
        if (p['feat_workflows'] == true) feats.add('Workflows');
        if (p['feat_tickets'] == true) feats.add('Tickets');
        if (p['feat_sso'] == true) feats.add('SSO');

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
              ),
              child: Text(p['display_name'] ?? '',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(height: 10),
            Text(curr.format(double.tryParse(p['monthly_price'].toString()) ?? 0),
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900,
                    color: widget.isDark ? AppColors.darkText : AppColors.lightText)),
            Text('/month', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Text('${p['max_users'] == -1 ? '∞' : p['max_users']} users  •  '
                '${p['max_leads'] == -1 ? '∞' : p['max_leads']} leads',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Expanded(child: Wrap(spacing: 4, runSpacing: 4, children: feats.take(4).map((f) =>
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5),
                ),
                child: Text(f, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              )).toList())),
            Text('${p['tenant_count'] ?? 0} active tenants',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
          ]),
        );
      },
    );
  }
}

// ── Platform Stats ────────────────────────────────────────────────────────────
class _PlatformStatsTab extends StatelessWidget {
  final bool isDark;
  const _PlatformStatsTab({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Platform analytics — coming soon',
        style: GoogleFonts.inter(color: Colors.grey)));
  }
}
