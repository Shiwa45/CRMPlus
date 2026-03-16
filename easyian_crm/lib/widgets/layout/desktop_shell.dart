// lib/widgets/layout/desktop_shell.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';

// ── Screen imports ────────────────────────────────────────────────────────────
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
import '../../screens/super_admin/super_admin_screen.dart'; // NEW
// New screens
import '../../screens/contacts/contacts_screen.dart';
import '../../screens/contacts/companies_screen.dart';
import '../../screens/deals/pipeline_screen.dart';
import '../../screens/deals/deals_screen.dart';
import '../../screens/quotes/quotes_screen.dart';
import '../../screens/quotes/invoices_screen.dart';
import '../../screens/quotes/products_screen.dart';
import '../../screens/tickets/tickets_screen.dart';
import '../../screens/tasks/tasks_screen.dart';
import '../../screens/workflows/workflows_screen.dart';
import '../ai_assistant_widget.dart';

class DesktopShell extends StatelessWidget {
  const DesktopShell({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          Row(children: [
            const _Sidebar(),
            VerticalDivider(width: 1, thickness: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            Expanded(child: _Body()),
          ]),
          const Positioned.fill(child: AIAssistantWidget()),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: AppProvider.shellNavigatorKey,
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            final route = context.watch<AppProvider>().currentRoute;
            return switch (route) {
              AppRoute.dashboard  => const DashboardScreen(),
              AppRoute.leads      => const LeadsScreen(),
              AppRoute.contacts   => const ContactsScreen(),
              AppRoute.companies  => const CompaniesScreen(),
              AppRoute.pipeline   => const PipelineScreen(),
              AppRoute.deals      => const DealsScreen(),
              AppRoute.quotes     => const QuotesScreen(),
              AppRoute.invoices   => const InvoicesScreen(),
              AppRoute.products   => const ProductsScreen(),
              AppRoute.tickets    => const TicketsScreen(),
              AppRoute.tasks      => const TasksScreen(),
              AppRoute.workflows  => const WorkflowsScreen(),
              AppRoute.analytics  => const AnalyticsScreen(),
              AppRoute.emails     => const EmailsScreen(),
              AppRoute.campaigns  => const CampaignsScreen(),
              AppRoute.templates  => const TemplatesScreen(),
              AppRoute.sequences  => const SequencesScreen(),
              AppRoute.emailConfig => const EmailConfigScreen(),
              AppRoute.kpiTargets  => const KpiTargetsScreen(),
              AppRoute.users       => const UsersScreen(),
              AppRoute.profile     => const ProfileScreen(),
              AppRoute.superAdmin  => const SuperAdminScreen(), // NEW
              AppRoute.settings    => const SettingsScreen(),
            };
          },
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
    );
  }
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar();
  static const double _w = 236;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user     = provider.currentUser;
    final isDark   = provider.isDark;
    final bg       = isDark ? AppColors.sidebarDark : AppColors.sidebarLight;

    return Container(
      width: _w,
      color: bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Logo bar ────────────────────────────────────────────────────────
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
                color: AppColors.logoRed, borderRadius: BorderRadius.circular(6)),
              alignment: Alignment.center,
              child: Text('E', style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Text('Easyian', style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: 16, letterSpacing: -0.3)),
            const Spacer(),
            GestureDetector(
              onTap: () => provider.toggleTheme(),
              child: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 16, color: AppColors.sidebarMuted),
            ),
          ]),
        ),

        // ── Nav ─────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _navItem(context, AppRoute.dashboard, Icons.grid_view_rounded, 'Dashboard'),

              _sectionLabel('CRM'),
              _navItem(context, AppRoute.leads,    Icons.people_rounded,    'Leads'),
              _navItem(context, AppRoute.contacts, Icons.contacts_rounded,  'Contacts'),
              _navItem(context, AppRoute.companies, Icons.business_rounded, 'Companies'),
              _navItem(context, AppRoute.analytics, Icons.bar_chart_rounded,'Analytics'),

              _sectionLabel('Sales'),
              _navItem(context, AppRoute.pipeline, Icons.view_kanban_rounded, 'Pipeline'),
              _navItem(context, AppRoute.deals,    Icons.handshake_rounded,   'Deals'),
              _navItem(context, AppRoute.tasks,    Icons.task_alt_rounded,    'Tasks'),

              _sectionLabel('Finance'),
              _navItem(context, AppRoute.quotes,   Icons.request_quote_rounded, 'Quotes'),
              _navItem(context, AppRoute.invoices, Icons.receipt_long_rounded,  'Invoices'),
              _navItem(context, AppRoute.products, Icons.inventory_2_rounded,   'Products'),

              _sectionLabel('Support'),
              _navItem(context, AppRoute.tickets,  Icons.support_agent_rounded, 'Tickets'),

              _sectionLabel('Communications'),
              _navItem(context, AppRoute.emails,    Icons.email_rounded,       'Emails'),
              _navItem(context, AppRoute.campaigns, Icons.campaign_rounded,    'Campaigns'),
              _navItem(context, AppRoute.templates, Icons.description_rounded, 'Templates'),
              _navItem(context, AppRoute.sequences, Icons.linear_scale_rounded,'Sequences'),

              if (user?.isAdmin ?? false) ...[
                _sectionLabel('Automation'),
                _navItem(context, AppRoute.workflows, Icons.account_tree_rounded, 'Workflows'),
                _sectionLabel('Administration'),
                _navItem(context, AppRoute.users,      Icons.manage_accounts_rounded, 'Users'),
                _navItem(context, AppRoute.emailConfig, Icons.settings_input_composite_rounded, 'Email Config'),
                _navItem(context, AppRoute.kpiTargets,  Icons.flag_rounded,             'KPI Targets'),
                if (user?.role == 'superadmin')
                  _navItem(context, AppRoute.superAdmin, Icons.admin_panel_settings_rounded, 'Super Admin'),
                _navItem(context, AppRoute.settings, Icons.integration_instructions_rounded, 'Integrations'),
              ],
            ]),
          ),
        ),

        // ── User footer ──────────────────────────────────────────────────────
        if (user != null)
          _UserFooter(user: user, provider: provider),
      ]),
    );
  }

  static Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(label.toUpperCase(), style: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8,
        color: AppColors.sidebarMuted)),
  );

  static Widget _navItem(BuildContext context, AppRoute route, IconData icon, String label) {
    final provider = context.watch<AppProvider>();
    final active   = provider.currentRoute == route;
    final isDark   = provider.isDark;

    Color bg      = Colors.transparent;
    Color fg      = isDark ? Colors.white70 : Colors.white70;
    Color iconFg  = isDark ? Colors.white54 : Colors.white54;
    if (active) {
      bg     = Colors.white.withOpacity(0.12);
      fg     = Colors.white;
      iconFg = Colors.white;
    }

    return GestureDetector(
      onTap: () => provider.navigate(route),
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
        child: Row(children: [
          Icon(icon, size: 16, color: iconFg),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(
              fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: fg)),
          if (route == AppRoute.tickets) ...[
            const Spacer(),
            _NotifBadge(route: route),
          ],
        ]),
      ),
    );
  }
}

class _NotifBadge extends StatelessWidget {
  final AppRoute route;
  const _NotifBadge({required this.route});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _UserFooter extends StatelessWidget {
  final UserModel user;
  final AppProvider provider;
  const _UserFooter({required this.user, required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => provider.navigate(AppRoute.profile),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07)))),
        child: Row(children: [
          CircleAvatar(
            radius: 16, backgroundColor: AppColors.primary.withOpacity(0.25),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, children: [
            Text(user.fullName, style: GoogleFonts.inter(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
            Text(user.roleDisplayName, style: GoogleFonts.inter(
                color: AppColors.sidebarMuted, fontSize: 11)),
          ])),
          GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out')),
                ],
              ));
              if (ok == true && context.mounted) provider.logout();
            },
            child: const Icon(Icons.logout_rounded, size: 16, color: AppColors.sidebarMuted),
          ),
        ]),
      ),
    );
  }
}
