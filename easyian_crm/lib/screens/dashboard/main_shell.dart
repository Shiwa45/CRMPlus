import 'package:flutter/material.dart';
import '../../core/utils/app_scaffold_controller.dart';
import '../../widgets/app_drawer.dart';
import '../dashboard/dashboard_screen.dart';
import '../analytics/analytics_screen.dart';
import '../leads/leads_list_screen.dart';
import '../leads/lead_form_screen.dart';
import '../leads/lead_sources_screen.dart';
import '../communications/email_list_screen.dart';
import '../communications/email_campaigns_screen.dart';
import '../communications/email_templates_screen.dart';
import '../communications/email_sequences_screen.dart';
import '../settings/email_config_screen.dart';
import '../users/users_list_screen.dart';
import '../settings/kpi_targets_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),       // 0
    const AnalyticsScreen(),       // 1
    const LeadsListScreen(),       // 2
    const LeadFormScreen(),        // 3
    const LeadSourcesScreen(),     // 4
    const EmailListScreen(),       // 5
    const EmailCampaignsScreen(),  // 6
    const EmailTemplatesScreen(),  // 7
    const EmailSequencesScreen(),  // 8
    const EmailConfigScreen(),     // 9
    const UsersListScreen(),       // 10
    const KpiTargetsScreen(),      // 11
    const ProfileScreen(),         // 12
    const SettingsScreen(),        // 13
  ];

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppScaffoldController.rootScaffoldKey,
      drawer: AppDrawer(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
    );
  }
}
