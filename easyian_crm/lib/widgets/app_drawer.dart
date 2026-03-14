import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_provider.dart';
import 'easyian_logo.dart';

class AppDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final isDark = provider.isDark;

    return Drawer(
      width: 268,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EasyianLogo(size: 38),
                  const SizedBox(height: 20),
                  if (user != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.fullName,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                              Text(user.roleDisplayName,
                                  style: GoogleFonts.inter(fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _navSection('MAIN'),
                  _navItem(context, Icons.dashboard_rounded, 'Dashboard', 0),
                  _navItem(context, Icons.analytics_rounded, 'Analytics', 1),
                  const SizedBox(height: 6),
                  _navSection('LEADS'),
                  _navItem(context, Icons.people_alt_rounded, 'All Leads', 2),
                  _navItem(context, Icons.person_add_rounded, 'Add Lead', 3),
                  _navItem(context, Icons.source_rounded, 'Lead Sources', 4),
                  const SizedBox(height: 6),
                  _navSection('COMMUNICATIONS'),
                  _navItem(context, Icons.email_rounded, 'Emails', 5),
                  _navItem(context, Icons.campaign_rounded, 'Campaigns', 6),
                  _navItem(context, Icons.description_rounded, 'Templates', 7),
                  _navItem(context, Icons.linear_scale_rounded, 'Sequences', 8),
                  _navItem(context, Icons.tune_rounded, 'Email Config', 9),
                  const SizedBox(height: 6),
                  if (user?.isAdmin == true || user?.isManager == true) ...[
                    _navSection('ADMIN'),
                    _navItem(context, Icons.manage_accounts_rounded, 'Users', 10),
                    _navItem(context, Icons.flag_rounded, 'KPI Targets', 11),
                    const SizedBox(height: 6),
                  ],
                  _navSection('ACCOUNT'),
                  _navItem(context, Icons.person_rounded, 'My Profile', 12),
                  _navItem(context, Icons.settings_rounded, 'Settings', 13),
                ],
              ),
            ),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  _footerBtn(
                    context,
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    isDark ? 'Light Mode' : 'Dark Mode',
                    () => provider.toggleTheme(),
                  ),
                  const SizedBox(height: 2),
                  _footerBtn(
                    context,
                    Icons.logout_rounded,
                    'Logout',
                    () async { Navigator.pop(context); await provider.logout(); },
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navSection(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 3),
      child: Text(label,
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1,
              color: Colors.grey.withOpacity(0.5))),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20,
                    color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.45)),
                const SizedBox(width: 12),
                Text(label,
                    style: GoogleFonts.inter(fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerBtn(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c),
              const SizedBox(width: 12),
              Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}
