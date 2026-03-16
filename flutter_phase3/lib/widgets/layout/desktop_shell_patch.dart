// lib/widgets/layout/desktop_shell_patch.dart
// ─────────────────────────────────────────────────────────────────────────────
// INSTRUCTIONS: Apply these changes to your existing desktop_shell.dart
// 1. Add these imports at the top
// 2. Add new routes to _buildContent()
// 3. Add new sidebar items
// 4. Wrap body with Stack to include AI assistant
// ─────────────────────────────────────────────────────────────────────────────

// NEW IMPORTS to add:
/*
import '../../screens/leads/lead_detail_screen.dart';
import '../../screens/contacts/contact_detail_screen.dart';
import '../../screens/deals/deal_detail_screen.dart';
import '../../screens/tickets/ticket_detail_screen.dart';
import '../../screens/super_admin/super_admin_screen.dart';
import '../ai_assistant_widget.dart';
*/

// ─────────────────────────────────────────────────────────────────────────────
// ADD to AppRoute enum:
// superAdmin, leadDetail, contactDetail, dealDetail, ticketDetail,
// tenantSettings, integrationSettings,
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// REPLACE the Scaffold body in DesktopShell.build() with this Stack version:
// ─────────────────────────────────────────────────────────────────────────────

/*
body: Stack(children: [
  Row(children: [
    const _Sidebar(),
    VerticalDivider(width:1, thickness:1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder2),
    Expanded(child: _buildContent(prov.currentRoute)),
  ]),
  const Positioned(bottom: 0, right: 0, child: AIAssistantWidget()),
]),
*/

// ─────────────────────────────────────────────────────────────────────────────
// ADD to _buildContent() switch cases:
// ─────────────────────────────────────────────────────────────────────────────

/*
AppRoute.superAdmin:   return const SuperAdminScreen();
AppRoute.settings:     return const SettingsScreen();   // replace old one

// Detail screens - navigate via Navigator.push from list screens:
// Navigator.push(context, MaterialPageRoute(
//   builder: (_) => LeadDetailScreen(leadId: id)));
*/

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR ADDITIONS — add to _sidebarItems() list:
// ─────────────────────────────────────────────────────────────────────────────

/*
// Under Admin section (only show if user.role == 'superadmin'):
SidebarItem(route: AppRoute.superAdmin, icon: Icons.admin_panel_settings,
    label: 'Super Admin'),

// Under Settings:
SidebarItem(route: AppRoute.settings, icon: Icons.integration_instructions,
    label: 'Integrations'),
*/

// ─────────────────────────────────────────────────────────────────────────────
// HOW TO OPEN DETAIL SCREENS FROM LIST SCREENS:
// Replace right-panel slide-out with full Navigator.push:
// ─────────────────────────────────────────────────────────────────────────────

/*
// In leads_screen.dart - onTap of a lead row:
onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => LeadDetailScreen(leadId: lead.id)));

// In contacts_screen.dart:
onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => ContactDetailScreen(contactId: contact.id)));

// In deals_screen.dart / pipeline_screen.dart:
onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => DealDetailScreen(dealId: deal.id)));

// In tickets_screen.dart:
onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => TicketDetailScreen(ticketId: ticket.id)));
*/
