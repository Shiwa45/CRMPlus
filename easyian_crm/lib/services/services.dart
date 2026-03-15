// lib/services/services.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/api_client.dart';
import '../models/models.dart';

int _asInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

List<T> _mapList<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return <T>[];
  return raw.whereType<Map>().map((e) => fromJson(Map<String, dynamic>.from(e))).toList();
}

// ─── Auth ─────────────────────────────────────────────────────────────────────
class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  Future<void> login(String username, String password) async {
    final data = await ApiClient.instance.post(AppConstants.loginEndpoint,
        body: {'username': username, 'password': password}, noAuth: true);
    final token  = data['token'] ?? data['key'] ?? '';
    final userId = data['user_id'] ?? 0;
    final prefs  = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token.toString());
    await prefs.setInt(AppConstants.userIdKey, userId);
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(AppConstants.tokenKey);
    await p.remove(AppConstants.userIdKey);
  }

  Future<bool> get isLoggedIn async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(AppConstants.tokenKey) ?? '').isNotEmpty;
  }

  Future<UserModel?> getMe() async {
    try {
      final p  = await SharedPreferences.getInstance();
      final id = p.getInt(AppConstants.userIdKey);
      if (id == null) return null;
      final data = await ApiClient.instance.get('${AppConstants.usersEndpoint}$id/');
      return UserModel.fromJson(data);
    } catch (_) { return null; }
  }

  Future<UserModel> updateProfile(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.usersEndpoint}$id/', body: body);
    return UserModel.fromJson(data);
  }
}

// ─── Leads ────────────────────────────────────────────────────────────────────
class LeadsService {
  static final LeadsService instance = LeadsService._();
  LeadsService._();

  Future<Map<String, dynamic>> getLeads({int page = 1, int pageSize = 50,
      String? search, String? status, String? priority,
      int? sourceId, int? assignedTo, String? ordering}) async {
    final data = await ApiClient.instance.get(AppConstants.leadsEndpoint, q: {
      'page': page, 'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null)    'status': status,
      if (priority != null)  'priority': priority,
      if (sourceId != null)  'source': sourceId,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (ordering != null)  'ordering': ordering,
    });
    if (data is List) {
      final results = _mapList(data, LeadModel.fromJson);
      return {'results': results, 'count': results.length};
    }
    return {
      'results': _mapList(data['results'], LeadModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<LeadModel> createLead(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.leadsEndpoint, body: body);
    return LeadModel.fromJson(data);
  }

  Future<LeadModel> updateLead(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.leadsEndpoint}$id/', body: body);
    return LeadModel.fromJson(data);
  }

  Future<void> deleteLead(int id) =>
      ApiClient.instance.delete('${AppConstants.leadsEndpoint}$id/');

  Future<void> bulkDelete(List<int> ids) async {
    for (final id in ids) {
      await deleteLead(id);
    }
  }

  Future<List<LeadSourceModel>> getLeadSources() async {
    final data = await ApiClient.instance.get(AppConstants.leadSourcesEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, LeadSourceModel.fromJson);
  }

  Future<LeadSourceModel> createLeadSource(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.leadSourcesEndpoint, body: body);
    return LeadSourceModel.fromJson(data);
  }

  Future<List<LeadActivityModel>> getActivities(int leadId) async {
    final data = await ApiClient.instance.get(AppConstants.leadActivitiesEndpoint, q: {'lead': leadId});
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, LeadActivityModel.fromJson);
  }

  Future<LeadActivityModel> createActivity(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.leadActivitiesEndpoint, body: body);
    return LeadActivityModel.fromJson(data);
  }
}

// ─── Contacts ─────────────────────────────────────────────────────────────────
class ContactsService {
  static final ContactsService instance = ContactsService._();
  ContactsService._();

  Future<Map<String, dynamic>> getContacts({int page = 1, int pageSize = 50,
      String? search, int? companyId, bool? dnd, String? ordering}) async {
    final data = await ApiClient.instance.get(AppConstants.contactsEndpoint, q: {
      'page': page, 'page_size': pageSize,
      if (search != null && search.isNotEmpty) 'search': search,
      if (companyId != null) 'company': companyId,
      if (dnd == true) 'dnd': 'true',
      if (ordering != null) 'ordering': ordering,
    });
    if (data is List) {
      final r = _mapList(data, ContactModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], ContactModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<ContactModel> getContact(int id) async {
    final data = await ApiClient.instance.get('${AppConstants.contactsEndpoint}$id/');
    return ContactModel.fromJson(data);
  }

  Future<ContactModel> createContact(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.contactsEndpoint, body: body);
    return ContactModel.fromJson(data);
  }

  Future<ContactModel> updateContact(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.contactsEndpoint}$id/', body: body);
    return ContactModel.fromJson(data);
  }

  Future<void> deleteContact(int id) =>
      ApiClient.instance.delete('${AppConstants.contactsEndpoint}$id/');

  Future<Map<String, dynamic>> getStats() async {
    final data = await ApiClient.instance.get('${AppConstants.contactsEndpoint}stats/');
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> getDuplicates() async {
    final data = await ApiClient.instance.get('${AppConstants.contactsEndpoint}duplicates/');
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Companies ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getCompanies({int page = 1, String? search, String? industry}) async {
    final data = await ApiClient.instance.get(AppConstants.companiesEndpoint, q: {
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
      if (industry != null) 'industry': industry,
    });
    if (data is List) {
      final r = _mapList(data, CompanyModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], CompanyModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<CompanyModel> createCompany(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.companiesEndpoint, body: body);
    return CompanyModel.fromJson(data);
  }

  Future<CompanyModel> updateCompany(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.companiesEndpoint}$id/', body: body);
    return CompanyModel.fromJson(data);
  }

  Future<void> deleteCompany(int id) =>
      ApiClient.instance.delete('${AppConstants.companiesEndpoint}$id/');
}

// ─── Deals ────────────────────────────────────────────────────────────────────
class DealsService {
  static final DealsService instance = DealsService._();
  DealsService._();

  Future<List<PipelineModel>> getPipelines() async {
    final data = await ApiClient.instance.get(AppConstants.pipelinesEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, PipelineModel.fromJson);
  }

  Future<PipelineModel> createPipeline(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.pipelinesEndpoint, body: body);
    return PipelineModel.fromJson(data);
  }

  Future<List<KanbanColumnModel>> getKanban(int pipelineId) async {
    final data = await ApiClient.instance.get('${AppConstants.pipelinesEndpoint}$pipelineId/kanban/');
    if (data is List) return _mapList(data, KanbanColumnModel.fromJson);
    return [];
  }

  Future<Map<String, dynamic>> getDeals({int page = 1, int? pipelineId, String? status,
      String? priority, int? ownerId, String? ordering}) async {
    final data = await ApiClient.instance.get(AppConstants.dealsEndpoint, q: {
      'page': page,
      if (pipelineId != null) 'pipeline': pipelineId,
      if (status != null)     'status': status,
      if (priority != null)   'priority': priority,
      if (ownerId != null)    'owner': ownerId,
      if (ordering != null)   'ordering': ordering,
    });
    if (data is List) {
      final r = _mapList(data, DealModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], DealModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<DealModel> createDeal(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.dealsEndpoint, body: body);
    return DealModel.fromJson(data);
  }

  Future<DealModel> updateDeal(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.dealsEndpoint}$id/', body: body);
    return DealModel.fromJson(data);
  }

  Future<DealModel> moveStage(int dealId, int stageId) async {
    final data = await ApiClient.instance.post(
        '${AppConstants.dealsEndpoint}$dealId/move_stage/',
        body: {'stage_id': stageId});
    return DealModel.fromJson(data);
  }

  Future<void> deleteDeal(int id) =>
      ApiClient.instance.delete('${AppConstants.dealsEndpoint}$id/');

  Future<Map<String, dynamic>> getStats() async {
    final data = await ApiClient.instance.get('${AppConstants.dealsEndpoint}stats/');
    return data is Map<String, dynamic> ? data : {};
  }
}

// ─── Quotes & Invoices ────────────────────────────────────────────────────────
class QuotesService {
  static final QuotesService instance = QuotesService._();
  QuotesService._();

  Future<List<TaxProfileModel>> getTaxProfiles() async {
    final data = await ApiClient.instance.get(AppConstants.taxProfilesEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, TaxProfileModel.fromJson);
  }

  Future<List<ProductModel>> getProducts({String? search}) async {
    final data = await ApiClient.instance.get(AppConstants.productsEndpoint,
        q: {if (search != null) 'search': search});
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, ProductModel.fromJson);
  }

  Future<ProductModel> createProduct(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.productsEndpoint, body: body);
    return ProductModel.fromJson(data);
  }

  Future<ProductModel> updateProduct(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.productsEndpoint}$id/', body: body);
    return ProductModel.fromJson(data);
  }

  Future<void> deleteProduct(int id) =>
      ApiClient.instance.delete('${AppConstants.productsEndpoint}$id/');

  // ── Quotes ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getQuotes({int page = 1, String? status}) async {
    final data = await ApiClient.instance.get(AppConstants.quotesEndpoint, q: {
      'page': page, if (status != null) 'status': status,
    });
    if (data is List) {
      final r = _mapList(data, QuoteModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], QuoteModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<QuoteModel> getQuote(int id) async {
    final data = await ApiClient.instance.get('${AppConstants.quotesEndpoint}$id/');
    return QuoteModel.fromJson(data);
  }

  Future<QuoteModel> createQuote(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.quotesEndpoint, body: body);
    return QuoteModel.fromJson(data);
  }

  Future<QuoteModel> updateQuote(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.quotesEndpoint}$id/', body: body);
    return QuoteModel.fromJson(data);
  }

  Future<void> deleteQuote(int id) =>
      ApiClient.instance.delete('${AppConstants.quotesEndpoint}$id/');

  Future<InvoiceModel> convertToInvoice(int quoteId) async {
    final data = await ApiClient.instance.post(
        '${AppConstants.quotesEndpoint}$quoteId/convert_to_invoice/');
    return InvoiceModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getQuoteStats() async {
    final data = await ApiClient.instance.get('${AppConstants.quotesEndpoint}stats/');
    return data is Map<String, dynamic> ? data : {};
  }

  // ── Invoices ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getInvoices({int page = 1, String? status, bool? overdue}) async {
    final data = await ApiClient.instance.get(AppConstants.invoicesEndpoint, q: {
      'page': page,
      if (status != null) 'status': status,
      if (overdue == true) 'overdue': 'true',
    });
    if (data is List) {
      final r = _mapList(data, InvoiceModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], InvoiceModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<InvoiceModel> getInvoice(int id) async {
    final data = await ApiClient.instance.get('${AppConstants.invoicesEndpoint}$id/');
    return InvoiceModel.fromJson(data);
  }

  Future<InvoiceModel> createInvoice(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.invoicesEndpoint, body: body);
    return InvoiceModel.fromJson(data);
  }

  Future<PaymentModel> recordPayment(int invoiceId, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(
        '${AppConstants.invoicesEndpoint}$invoiceId/record_payment/', body: body);
    return PaymentModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getInvoiceStats() async {
    final data = await ApiClient.instance.get('${AppConstants.invoicesEndpoint}stats/');
    return data is Map<String, dynamic> ? data : {};
  }
}

// ─── Tickets ─────────────────────────────────────────────────────────────────
class TicketsService {
  static final TicketsService instance = TicketsService._();
  TicketsService._();

  Future<List<TicketCategoryModel>> getCategories() async {
    final data = await ApiClient.instance.get(AppConstants.ticketCategoriesEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, TicketCategoryModel.fromJson);
  }

  Future<Map<String, dynamic>> getTickets({int page = 1, String? status,
      String? priority, int? assignedTo, bool? overdue,
      bool? unassigned, bool? myTickets}) async {
    final data = await ApiClient.instance.get(AppConstants.ticketsEndpoint, q: {
      'page': page,
      if (status != null)       'status': status,
      if (priority != null)     'priority': priority,
      if (assignedTo != null)   'assigned_to': assignedTo,
      if (overdue == true)      'overdue': 'true',
      if (unassigned == true)   'unassigned': 'true',
      if (myTickets == true)    'my_tickets': 'true',
    });
    if (data is List) {
      final r = _mapList(data, TicketModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], TicketModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<TicketModel> getTicket(int id) async {
    final data = await ApiClient.instance.get('${AppConstants.ticketsEndpoint}$id/');
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> createTicket(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.ticketsEndpoint, body: body);
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> updateTicket(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.ticketsEndpoint}$id/', body: body);
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> resolve(int id) async {
    final data = await ApiClient.instance.post('${AppConstants.ticketsEndpoint}$id/resolve/');
    return TicketModel.fromJson(data);
  }

  Future<TicketModel> reopen(int id) async {
    final data = await ApiClient.instance.post('${AppConstants.ticketsEndpoint}$id/reopen/');
    return TicketModel.fromJson(data);
  }

  Future<void> submitCsat(int id, int score, {String? comment}) async {
    await ApiClient.instance.post('${AppConstants.ticketsEndpoint}$id/csat/',
        body: {'score': score, if (comment != null) 'comment': comment});
  }

  Future<void> addReply(int id, Map<String, dynamic> body) async {
    await ApiClient.instance.post('${AppConstants.ticketsEndpoint}$id/reply/', body: body);
  }

  Future<Map<String, dynamic>> getStats() async {
    final data = await ApiClient.instance.get('${AppConstants.ticketsEndpoint}stats/');
    return data is Map<String, dynamic> ? data : {};
  }
}

// ─── Tasks ────────────────────────────────────────────────────────────────────
class TasksService {
  static final TasksService instance = TasksService._();
  TasksService._();

  Future<Map<String, dynamic>> getTasks({int page = 1, String? status,
      bool? myTasks, bool? overdue, int? leadId, int? dealId}) async {
    final data = await ApiClient.instance.get(AppConstants.tasksEndpoint, q: {
      'page': page,
      if (status != null)    'status': status,
      if (myTasks == true)   'my_tasks': 'true',
      if (overdue == true)   'overdue': 'true',
      if (leadId != null)    'lead_id': leadId,
      if (dealId != null)    'deal_id': dealId,
    });
    if (data is List) {
      final r = _mapList(data, TaskModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], TaskModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<TaskModel> createTask(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.tasksEndpoint, body: body);
    return TaskModel.fromJson(data);
  }

  Future<TaskModel> updateTask(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.tasksEndpoint}$id/', body: body);
    return TaskModel.fromJson(data);
  }

  Future<void> completeTask(int id) =>
      ApiClient.instance.post('${AppConstants.tasksEndpoint}$id/complete/');

  Future<void> deleteTask(int id) =>
      ApiClient.instance.delete('${AppConstants.tasksEndpoint}$id/');

  Future<Map<String, dynamic>> getStats() async {
    final data = await ApiClient.instance.get('${AppConstants.tasksEndpoint}stats/');
    return data is Map<String, dynamic> ? data : {};
  }
}

// ─── Notifications ────────────────────────────────────────────────────────────
class NotificationsService {
  static final NotificationsService instance = NotificationsService._();
  NotificationsService._();

  Future<List<NotificationModel>> getNotifications() async {
    final data = await ApiClient.instance.get(AppConstants.notificationsEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, NotificationModel.fromJson);
  }

  Future<int> getUnreadCount() async {
    try {
      final data = await ApiClient.instance.get('${AppConstants.notificationsEndpoint}unread_count/');
      return _asInt(data['count']);
    } catch (_) { return 0; }
  }

  Future<void> markRead(int id) =>
      ApiClient.instance.post('${AppConstants.notificationsEndpoint}$id/mark_read/');

  Future<void> markAllRead() =>
      ApiClient.instance.post('${AppConstants.notificationsEndpoint}mark_all_read/');
}

// ─── Workflows ────────────────────────────────────────────────────────────────
class WorkflowsService {
  static final WorkflowsService instance = WorkflowsService._();
  WorkflowsService._();

  Future<List<WorkflowModel>> getWorkflows({bool? active}) async {
    final data = await ApiClient.instance.get(AppConstants.workflowsEndpoint,
        q: {if (active == true) 'active': 'true'});
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, WorkflowModel.fromJson);
  }

  Future<WorkflowModel> createWorkflow(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.workflowsEndpoint, body: body);
    return WorkflowModel.fromJson(data);
  }

  Future<WorkflowModel> updateWorkflow(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.workflowsEndpoint}$id/', body: body);
    return WorkflowModel.fromJson(data);
  }

  Future<void> toggleActive(int id) =>
      ApiClient.instance.post('${AppConstants.workflowsEndpoint}$id/toggle_active/');

  Future<void> deleteWorkflow(int id) =>
      ApiClient.instance.delete('${AppConstants.workflowsEndpoint}$id/');

  Future<void> setConditions(int id, List<Map<String, dynamic>> conditions) =>
      ApiClient.instance.post('${AppConstants.workflowsEndpoint}$id/set_conditions/',
          body: {'conditions': conditions});

  Future<void> setActions(int id, List<Map<String, dynamic>> actions) =>
      ApiClient.instance.post('${AppConstants.workflowsEndpoint}$id/set_actions/',
          body: {'actions': actions});
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
class DashboardService {
  static final DashboardService instance = DashboardService._();
  DashboardService._();

  Future<DashboardStats> getStats({String? dateRange}) async {
    try {
      final data = await ApiClient.instance.get(AppConstants.dashboardStatsEndpoint,
          q: {if (dateRange != null) 'date_range': dateRange});
      final raw = (data is Map && data['results'] is Map)
          ? data['results']
          : (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty)
              ? (data['results'] as List).first
              : data;
      if (raw is Map<String, dynamic>) return DashboardStats.fromJson(raw);
      return DashboardStats.empty();
    } catch (_) { return DashboardStats.empty(); }
  }

  Future<List<KPITargetModel>> getKpiTargets() async {
    final data = await ApiClient.instance.get(AppConstants.kpiTargetsEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, KPITargetModel.fromJson);
  }

  Future<KPITargetModel> createKpiTarget(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.kpiTargetsEndpoint, body: body);
    return KPITargetModel.fromJson(data);
  }
}

// ─── Communications ───────────────────────────────────────────────────────────
class CommsService {
  static final CommsService instance = CommsService._();
  CommsService._();

  Future<Map<String, dynamic>> getEmails({int page = 1, String? status, String? search}) async {
    final data = await ApiClient.instance.get(AppConstants.emailsEndpoint, q: {
      'page': page, if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    if (data is List) {
      final r = _mapList(data, EmailModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], EmailModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<List<EmailConfigModel>> getEmailConfigs() async {
    final data = await ApiClient.instance.get(AppConstants.emailConfigsEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, EmailConfigModel.fromJson);
  }

  Future<void> createEmailConfig(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailConfigsEndpoint, body: body);

  Future<void> updateEmailConfig(int id, Map<String, dynamic> body) =>
      ApiClient.instance.patch('${AppConstants.emailConfigsEndpoint}$id/', body: body);

  Future<Map<String, dynamic>> getTemplates({int page = 1, String? search}) async {
    final data = await ApiClient.instance.get(AppConstants.emailTemplatesEndpoint,
        q: {'page': page, if (search != null) 'search': search});
    if (data is List) {
      final results = _mapList(data, EmailTemplateModel.fromJson);
      return {'results': results, 'count': results.length};
    }
    return {
      'results': _mapList(data['results'], EmailTemplateModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<void> createTemplate(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailTemplatesEndpoint, body: body);

  Future<void> updateTemplate(int id, Map<String, dynamic> body) =>
      ApiClient.instance.patch('${AppConstants.emailTemplatesEndpoint}$id/', body: body);

  Future<void> deleteTemplate(int id) =>
      ApiClient.instance.delete('${AppConstants.emailTemplatesEndpoint}$id/');

  Future<Map<String, dynamic>> getCampaigns({int page = 1}) async {
    final data = await ApiClient.instance.get(AppConstants.emailCampaignsEndpoint, q: {'page': page});
    if (data is List) {
      final results = _mapList(data, EmailCampaignModel.fromJson);
      return {'results': results, 'count': results.length};
    }
    return {
      'results': _mapList(data['results'], EmailCampaignModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<void> createCampaign(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailCampaignsEndpoint, body: body);

  Future<List<EmailSequenceModel>> getSequences() async {
    final data = await ApiClient.instance.get(AppConstants.emailSequencesEndpoint);
    final list = data is List ? data : (data is Map ? (data['results'] as List? ?? []) : []);
    return _mapList(list, EmailSequenceModel.fromJson);
  }

  Future<void> createSequence(Map<String, dynamic> body) =>
      ApiClient.instance.post(AppConstants.emailSequencesEndpoint, body: body);
}

// ─── Users ────────────────────────────────────────────────────────────────────
class UsersService {
  static final UsersService instance = UsersService._();
  UsersService._();

  Future<Map<String, dynamic>> getUsers({int page = 1, String? search, String? role}) async {
    final data = await ApiClient.instance.get(AppConstants.usersEndpoint, q: {
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null) 'role': role,
    });
    if (data is List) {
      final r = _mapList(data, UserModel.fromJson);
      return {'results': r, 'count': r.length};
    }
    return {
      'results': _mapList(data['results'], UserModel.fromJson),
      'count': _asInt(data['count']),
    };
  }

  Future<UserModel> createUser(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post(AppConstants.usersEndpoint, body: body);
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.patch('${AppConstants.usersEndpoint}$id/', body: body);
    return UserModel.fromJson(data);
  }
}
