import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/num_utils.dart';
import '../../models/user_model.dart';
import '../../services/users_service.dart';
import '../../widgets/app_loader.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  int _totalCount = 0;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await UsersService.instance.getUsers(search: _search.isEmpty ? null : _search);
      setState(() {
        _users = result['results'] as List<UserModel>;
        _totalCount = toInt(result['count']);
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _createUser() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => UserFormScreen(onSaved: _load)));
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
        title: Text('Users', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) { _search = v; _load(); },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createUser,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
      ),
      body: Column(
        children: [
          if (!_loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              child: Row(children: [
                Text('$_totalCount users', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          Expanded(
            child: _loading
                ? const Center(child: AppLoader())
                : _users.isEmpty
                    ? Center(child: Text('No users found', style: GoogleFonts.inter(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _UserTile(
                          user: _users[i],
                          isDark: isDark,
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => UserFormScreen(user: _users[i], onSaved: _load))),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final VoidCallback onTap;
  const _UserTile({required this.user, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor(user.role);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: roleColor.withOpacity(0.15),
              child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: roleColor)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(user.email, style: GoogleFonts.inter(fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                _chip(user.roleDisplayName, roleColor),
                if (user.department != null) ...[
                  const SizedBox(width: 6),
                  _chip(user.department!, AppColors.info),
                ],
              ]),
            ])),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: user.isActive ? AppColors.success : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'superadmin': return AppColors.logoRed;
      case 'admin': return AppColors.error;
      case 'sales_manager': return AppColors.warning;
      default: return AppColors.primary;
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class UserFormScreen extends StatefulWidget {
  final UserModel? user;
  final VoidCallback onSaved;
  const UserFormScreen({super.key, this.user, required this.onSaved});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = 'sales_rep';
  bool _isActive = true;
  bool _saving = false;
  bool _obscurePass = true;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final u = widget.user!;
      _firstNameCtrl.text = u.firstName;
      _lastNameCtrl.text = u.lastName;
      _emailCtrl.text = u.email;
      _usernameCtrl.text = u.username;
      _phoneCtrl.text = u.phone ?? '';
      _deptCtrl.text = u.department ?? '';
      _role = u.role;
      _isActive = u.isActive;
    }
  }

  @override
  void dispose() {
    for (final c in [_firstNameCtrl, _lastNameCtrl, _emailCtrl, _usernameCtrl, _phoneCtrl, _deptCtrl, _passwordCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final data = {
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'username': _usernameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'department': _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
      'role': _role,
      'is_active': _isActive,
      if (!_isEdit && _passwordCtrl.text.isNotEmpty) 'password': _passwordCtrl.text,
    };
    try {
      if (_isEdit) {
        await UsersService.instance.updateUser(widget.user!.id, data);
      } else {
        await UsersService.instance.createUser(data);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit User' : 'New User', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const AppLoader(size: 18) : Text('Save',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name *'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name'))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Username *')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email *')),
          const SizedBox(height: 12),
          TextField(controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [
              const DropdownMenuItem(value: 'sales_rep', child: Text('Sales Rep')),
              const DropdownMenuItem(value: 'sales_manager', child: Text('Sales Manager')),
              const DropdownMenuItem(value: 'admin', child: Text('Admin')),
              const DropdownMenuItem(value: 'superadmin', child: Text('Super Admin')),
            ],
            onChanged: (v) => setState(() => _role = v!),
          ),
          if (!_isEdit) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: 'Password *',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

