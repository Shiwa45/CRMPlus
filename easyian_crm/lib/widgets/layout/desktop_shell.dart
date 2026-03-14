import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/leads/leads_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/communications/emails_screen.dart';
import '../../screens/communications/campaigns_screen.dart';
import '../../screens/communications/templates_screen.dart';
import '../../screens/communications/sequences_screen.dart';
import '../../screens/settings/email_config_screen.dart';
import '../../screens/settings/kpi_targets_screen.dart';
import '../../screens/users/users_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Row(
        children: [
          const _Sidebar(),
          VerticalDivider(width: 1, thickness: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          Expanded(child: _Body()),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final route = context.watch<AppProvider>().currentRoute;
    return switch (route) {
      AppRoute.dashboard  => DashboardScreen(),
      AppRoute.leads      => LeadsScreen(),
      AppRoute.analytics  => AnalyticsScreen(),
      AppRoute.emails     => EmailsScreen(),
      AppRoute.campaigns  => CampaignsScreen(),
      AppRoute.templates  => TemplatesScreen(),
      AppRoute.sequences  => SequencesScreen(),
      AppRoute.emailConfig=> EmailConfigScreen(),
      AppRoute.kpiTargets => KpiTargetsScreen(),
      AppRoute.users      => UsersScreen(),
      AppRoute.profile    => ProfileScreen(),
      AppRoute.settings   => SettingsScreen(),
    };
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  static const double _w = 232;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final isDark = provider.isDark;
    final bg = isDark ? AppColors.sidebarDark : AppColors.sidebarLight;

    return Container(
      width: _w,
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
            ),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: AppColors.logoRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text('E', style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Text('Easyian', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16,
                  letterSpacing: -0.3)),
              const Spacer(),
              // Theme toggle
              GestureDetector(
                onTap: () => provider.toggleTheme(),
                child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 16, color: AppColors.sidebarMuted),
              ),
            ]),
          ),

          // Nav
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _navItem(context, AppRoute.dashboard, Icons.grid_view_rounded, 'Dashboard'),
                const SizedBox(height: 4),

                _sectionLabel('CRM'),
                _navItem(context, AppRoute.leads, Icons.people_rounded, 'Leads'),
                _navItem(context, AppRoute.analytics, Icons.bar_chart_rounded, 'Analytics'),

                const SizedBox(height: 4),
                _sectionLabel('Communications'),
                _navItem(context, AppRoute.emails, Icons.email_rounded, 'Emails'),
                _navItem(context, AppRoute.campaigns, Icons.campaign_rounded, 'Campaigns'),
                _navItem(context, AppRoute.templates, Icons.description_rounded, 'Templates'),
                _navItem(context, AppRoute.sequences, Icons.linear_scale_rounded, 'Sequences'),

                if (user?.isAdmin ?? false) ...[
                  const SizedBox(height: 4),
                  _sectionLabel('Admin'),
                  _navItem(context, AppRoute.users, Icons.manage_accounts_rounded, 'Users'),
                  _navItem(context, AppRoute.kpiTargets, Icons.flag_rounded, 'KPI Targets'),
                  _navItem(context, AppRoute.emailConfig, Icons.settings_input_composite_rounded, 'Email Config'),
                ],

                const SizedBox(height: 4),
                _sectionLabel('Account'),
                _navItem(context, AppRoute.profile, Icons.person_rounded, 'Profile'),
                _navItem(context, AppRoute.settings, Icons.settings_rounded, 'Settings'),
              ]),
            ),
          ),

          // User footer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.primary,
                child: Text(
                  user != null && user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? 'User',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(user?.roleDisplayName ?? '', style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.sidebarMuted)),
              ])),
              GestureDetector(
                onTap: () => context.read<AppProvider>().logout(),
                child: const Tooltip(
                  message: 'Logout',
                  child: Icon(Icons.logout_rounded, size: 15, color: AppColors.sidebarMuted),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(label.toUpperCase(),
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: AppColors.sidebarMuted, letterSpacing: 0.8)),
    );
  }

  Widget _navItem(BuildContext context, AppRoute route, IconData icon, String label) {
    final current = context.watch<AppProvider>().currentRoute == route;
    return GestureDetector(
      onTap: () => context.read<AppProvider>().navigate(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: current ? AppColors.sidebarActiveBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: current
              ? Border(left: const BorderSide(color: AppColors.sidebarActive, width: 2.5))
              : null,
        ),
        child: Row(children: [
          Icon(icon, size: 16,
              color: current ? Colors.white : AppColors.sidebarMuted),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              color: current ? Colors.white : AppColors.sidebarText)),
        ]),
      ),
    );
  }
}
