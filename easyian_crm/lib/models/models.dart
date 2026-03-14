// ─── User ─────────────────────────────────────────────────────────────────────
class UserModel {
  final int id;
  final String username, email, firstName, lastName;
  final String? phone, department;
  final String role, roleDisplayName;
  final bool isActive;
  final String? dateJoined;

  UserModel({required this.id, required this.username, required this.email,
    required this.firstName, required this.lastName, this.phone, this.department,
    required this.role, required this.roleDisplayName, required this.isActive, this.dateJoined});

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isManager => role == 'sales_manager' || isAdmin;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: _toInt(j['id']), username: j['username'] ?? '', email: j['email'] ?? '',
    firstName: j['first_name'] ?? '', lastName: j['last_name'] ?? '',
    phone: j['phone'], department: j['department'],
    role: j['role'] ?? 'sales_rep', roleDisplayName: j['role_display_name'] ?? j['role'] ?? '',
    isActive: j['is_active'] ?? true, dateJoined: j['date_joined'],
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName, 'last_name': lastName, 'email': email,
    'username': username, 'phone': phone, 'department': department,
    'role': role, 'is_active': isActive,
  };
}

// ─── Lead ─────────────────────────────────────────────────────────────────────
class LeadModel {
  final int id;
  final String firstName, email, status, priority, createdAt, updatedAt;
  final String? lastName, phone, company, jobTitle, sourceName, assignedToName;
  final int? sourceId, assignedToId;
  final String? address, city, state, country, postalCode, requirements, notes, lastContacted;
  final double? budget;
  final bool isHot, isOverdue;

  LeadModel({required this.id, required this.firstName, required this.email,
    required this.status, required this.priority, required this.createdAt,
    required this.updatedAt, this.lastName, this.phone, this.company, this.jobTitle,
    this.sourceName, this.assignedToName, this.sourceId, this.assignedToId,
    this.address, this.city, this.state, this.country, this.postalCode,
    this.requirements, this.notes, this.lastContacted, this.budget,
    required this.isHot, required this.isOverdue});

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory LeadModel.fromJson(Map<String, dynamic> j) => LeadModel(
    id: _toInt(j['id']), firstName: j['first_name'] ?? '', email: j['email'] ?? '',
    lastName: j['last_name'], phone: j['phone'], company: j['company'],
    jobTitle: j['job_title'], status: j['status'] ?? 'new', priority: j['priority'] ?? 'warm',
    sourceId: _toIntNullable(j['source']), sourceName: j['source_name'], assignedToId: _toIntNullable(j['assigned_to']),
    assignedToName: j['assigned_to_name'], address: j['address'], city: j['city'],
    state: j['state'], country: j['country'], postalCode: j['postal_code'],
    budget: j['budget'] != null ? double.tryParse(j['budget'].toString()) : null,
    requirements: j['requirements'], notes: j['notes'], isHot: j['is_hot'] ?? false,
    isOverdue: j['is_overdue'] ?? false, lastContacted: j['last_contacted'],
    createdAt: j['created_at'] ?? '', updatedAt: j['updated_at'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'first_name': firstName, 'last_name': lastName, 'email': email, 'phone': phone,
    'company': company, 'job_title': jobTitle, 'status': status, 'priority': priority,
    'source': sourceId, 'assigned_to': assignedToId, 'address': address, 'city': city,
    'state': state, 'country': country, 'postal_code': postalCode, 'budget': budget,
    'requirements': requirements, 'notes': notes,
  };
}

class LeadSourceModel {
  final int id; final String name; final bool isActive;
  LeadSourceModel({required this.id, required this.name, required this.isActive});
  factory LeadSourceModel.fromJson(Map<String, dynamic> j) =>
      LeadSourceModel(id: _toInt(j['id']), name: j['name'] ?? '', isActive: j['is_active'] ?? true);
}

class LeadActivityModel {
  final int id, leadId, userId;
  final String activityType, subject, createdAt;
  final String? description, userName;
  LeadActivityModel({required this.id, required this.leadId, required this.userId,
    required this.activityType, required this.subject, required this.createdAt,
    this.description, this.userName});
  factory LeadActivityModel.fromJson(Map<String, dynamic> j) => LeadActivityModel(
    id: _toInt(j['id']), leadId: _toInt(j['lead']), userId: _toInt(j['user']),
    activityType: j['activity_type'] ?? 'note', subject: j['subject'] ?? '',
    description: j['description'], userName: j['user_name'], createdAt: j['created_at'] ?? '',
  );
}

// ─── Email models ─────────────────────────────────────────────────────────────
class EmailConfigModel {
  final int id, userId, smtpPort, dailyLimit;
  final String name, provider, smtpHost, smtpUsername, fromEmail, fromName, createdAt;
  final String? replyTo;
  final bool useTls, useSsl, isDefault, isActive;
  EmailConfigModel({required this.id, required this.userId, required this.name,
    required this.provider, required this.smtpHost, required this.smtpPort,
    required this.smtpUsername, required this.fromEmail, required this.fromName,
    this.replyTo, required this.useTls, required this.useSsl, required this.isDefault,
    required this.isActive, required this.dailyLimit, required this.createdAt});
  factory EmailConfigModel.fromJson(Map<String, dynamic> j) => EmailConfigModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), name: j['name'] ?? '',
    provider: j['provider'] ?? 'smtp', smtpHost: j['smtp_host'] ?? '',
    smtpPort: _toInt(j['smtp_port'], fallback: 587), smtpUsername: j['smtp_username'] ?? '',
    fromEmail: j['from_email'] ?? '', fromName: j['from_name'] ?? '',
    replyTo: j['reply_to'], useTls: j['use_tls'] ?? true, useSsl: j['use_ssl'] ?? false,
    isDefault: j['is_default'] ?? false, isActive: j['is_active'] ?? true,
    dailyLimit: _toInt(j['daily_limit'], fallback: 500), createdAt: j['created_at'] ?? '',
  );
}

class EmailTemplateModel {
  final int id, userId, usageCount;
  final String name, templateType, subject, bodyHtml, createdAt;
  final String? bodyText, lastUsed;
  final bool isShared, isActive;
  EmailTemplateModel({required this.id, required this.userId, required this.name,
    required this.templateType, required this.subject, required this.bodyHtml,
    this.bodyText, required this.isShared, required this.isActive,
    required this.usageCount, this.lastUsed, required this.createdAt});
  factory EmailTemplateModel.fromJson(Map<String, dynamic> j) => EmailTemplateModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), name: j['name'] ?? '',
    templateType: j['template_type'] ?? 'general', subject: j['subject'] ?? '',
    bodyHtml: j['body_html'] ?? '', bodyText: j['body_text'],
    isShared: j['is_shared'] ?? false, isActive: j['is_active'] ?? true,
    usageCount: _toInt(j['usage_count']), lastUsed: j['last_used'], createdAt: j['created_at'] ?? '',
  );
}

class EmailCampaignModel {
  final int id, userId, totalRecipients, sentCount, openCount, clickCount, failedCount;
  final String name, status, createdAt;
  final String? description, scheduledAt, startedAt, completedAt;
  EmailCampaignModel({required this.id, required this.userId, required this.name,
    required this.status, required this.createdAt, this.description,
    required this.totalRecipients, required this.sentCount, required this.openCount,
    required this.clickCount, required this.failedCount,
    this.scheduledAt, this.startedAt, this.completedAt});
  double get openRate => sentCount > 0 ? (openCount / sentCount) * 100 : 0;
  double get progress => totalRecipients > 0 ? (sentCount / totalRecipients) * 100 : 0;
  factory EmailCampaignModel.fromJson(Map<String, dynamic> j) => EmailCampaignModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), name: j['name'] ?? '',
    description: j['description'], status: j['status'] ?? 'draft',
    totalRecipients: _toInt(j['total_recipients']), sentCount: _toInt(j['sent_count'] ?? j['emails_sent']),
    openCount: _toInt(j['open_count']), clickCount: _toInt(j['click_count']),
    failedCount: _toInt(j['failed_count'] ?? j['emails_failed']), scheduledAt: j['scheduled_at'],
    startedAt: j['started_at'], completedAt: j['completed_at'], createdAt: j['created_at'] ?? '',
  );
}

class EmailModel {
  final int id, userId, retryCount;
  final String subject, toEmail, status, createdAt;
  final String? errorMessage, sentAt, openedAt;
  final int? leadId, templateId, campaignId;
  final String? leadName;
  EmailModel({required this.id, required this.userId, required this.subject,
    required this.toEmail, required this.status, required this.createdAt,
    required this.retryCount, this.errorMessage, this.sentAt, this.openedAt,
    this.leadId, this.leadName, this.templateId, this.campaignId});
  factory EmailModel.fromJson(Map<String, dynamic> j) => EmailModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), subject: j['subject'] ?? '',
    toEmail: j['to_email'] ?? '', status: j['status'] ?? 'pending',
    errorMessage: j['error_message'], sentAt: j['sent_at'], openedAt: j['opened_at'],
    leadId: _toIntNullable(j['lead']), leadName: j['lead_name'], templateId: _toIntNullable(j['template']),
    campaignId: _toIntNullable(j['campaign']), retryCount: _toInt(j['retry_count']), createdAt: j['created_at'] ?? '',
  );
}

class EmailSequenceModel {
  final int id, userId, stepsCount;
  final String name, createdAt;
  final String? description;
  final bool isActive;
  EmailSequenceModel({required this.id, required this.userId, required this.name,
    required this.isActive, required this.stepsCount, required this.createdAt, this.description});
  factory EmailSequenceModel.fromJson(Map<String, dynamic> j) => EmailSequenceModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), name: j['name'] ?? '',
    description: j['description'], isActive: j['is_active'] ?? true,
    stepsCount: _toInt(j['steps_count']), createdAt: j['created_at'] ?? '',
  );
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? _toIntNullable(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double _toDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

class DashboardStats {
  final int totalLeads, newLeads, wonLeads, lostLeads, overdueLeads, totalUsers, totalCampaigns, totalEmails;
  final double conversionRate, totalRevenue, avgDealSize;
  final Map<String, int> leadsByStatus, leadsByPriority;
  final List<MonthlyData> monthlyData;
  final List<FunnelData> funnelData;
  final List<SourcePerformance> sourcePerformance;

  DashboardStats({required this.totalLeads, required this.newLeads, required this.wonLeads,
    required this.lostLeads, required this.overdueLeads, required this.conversionRate,
    required this.totalRevenue, required this.avgDealSize, required this.totalUsers,
    required this.totalCampaigns, required this.totalEmails, required this.leadsByStatus,
    required this.leadsByPriority, required this.monthlyData, required this.funnelData,
    required this.sourcePerformance});

  factory DashboardStats.fromJson(Map<String, dynamic> j) {
    Map<String, int> parseMap(dynamic raw) {
      final out = <String, int>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          int? val;
          if (v is num) val = v.toInt();
          else if (v is String) val = int.tryParse(v);
          else if (v is Map && v['count'] is num) val = (v['count'] as num).toInt();
          if (val != null) out[k.toString()] = val;
        });
        return out;
      }
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final key = item['status'] ?? item['priority'] ?? item['name'] ?? item['label'];
            final v = item['count'] ?? item['value'];
            if (key != null) {
              final parsed = v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
              if (parsed != null) out[key.toString()] = parsed;
            }
          }
        }
      }
      return out;
    }
    return DashboardStats(
      totalLeads: _toInt(j['total_leads']),
      newLeads: _toInt(j['new_leads'] ?? j['new']),
      wonLeads: _toInt(j['won_leads'] ?? j['won']),
      lostLeads: _toInt(j['lost_leads'] ?? j['lost']),
      overdueLeads: _toInt(j['overdue_leads']),
      conversionRate: _toDouble(j['conversion_rate']),
      totalRevenue: _toDouble(j['total_revenue']),
      avgDealSize: _toDouble(j['avg_deal_size']),
      totalUsers: _toInt(j['total_users']),
      totalCampaigns: _toInt(j['total_campaigns']),
      totalEmails: _toInt(j['total_emails']),
      leadsByStatus: parseMap(j['leads_by_status']),
      leadsByPriority: parseMap(j['leads_by_priority']),
      monthlyData: (j['monthly_data'] as List? ?? []).map((e) => MonthlyData.fromJson(e)).toList(),
      funnelData: (j['funnel_data'] as List? ?? []).map((e) => FunnelData.fromJson(e)).toList(),
      sourcePerformance: (j['source_performance'] as List? ?? []).map((e) => SourcePerformance.fromJson(e)).toList(),
    );
  }
  factory DashboardStats.empty() => DashboardStats(
    totalLeads: 0, newLeads: 0, wonLeads: 0, lostLeads: 0, overdueLeads: 0,
    conversionRate: 0, totalRevenue: 0, avgDealSize: 0, totalUsers: 0,
    totalCampaigns: 0, totalEmails: 0, leadsByStatus: {}, leadsByPriority: {},
    monthlyData: [], funnelData: [], sourcePerformance: [],
  );
}

class MonthlyData {
  final String month, monthShort;
  final int total, won, lost;
  final double conversionRate, revenue;
  MonthlyData({required this.month, required this.monthShort, required this.total,
    required this.won, required this.lost, required this.conversionRate, required this.revenue});
  factory MonthlyData.fromJson(Map<String, dynamic> j) => MonthlyData(
    month: j['month'] ?? '', monthShort: j['month_short'] ?? '',
    total: _toInt(j['total']), won: _toInt(j['won']), lost: _toInt(j['lost']),
    conversionRate: _toDouble(j['conversion_rate']), revenue: _toDouble(j['revenue']),
  );
}

class FunnelData {
  final String stage; final int count; final double percentage;
  FunnelData({required this.stage, required this.count, required this.percentage});
  factory FunnelData.fromJson(Map<String, dynamic> j) => FunnelData(
    stage: j['stage'] ?? '', count: _toInt(j['count']), percentage: _toDouble(j['percentage']),
  );
}

class SourcePerformance {
  final String name; final int totalLeads, wonLeads; final double conversionRate;
  SourcePerformance({required this.name, required this.totalLeads, required this.wonLeads, required this.conversionRate});
  factory SourcePerformance.fromJson(Map<String, dynamic> j) => SourcePerformance(
    name: j['name'] ?? '', totalLeads: _toInt(j['total_leads']),
    wonLeads: _toInt(j['won_leads']), conversionRate: _toDouble(j['conversion_rate']),
  );
}

class KPITargetModel {
  final int id, userId;
  final String kpiType, periodStart, periodEnd;
  final double targetValue, currentValue, completionPercentage;
  final bool isActive, isAchieved;
  KPITargetModel({required this.id, required this.userId, required this.kpiType,
    required this.targetValue, required this.currentValue, required this.periodStart,
    required this.periodEnd, required this.isActive, required this.completionPercentage,
    required this.isAchieved});
  factory KPITargetModel.fromJson(Map<String, dynamic> j) => KPITargetModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), kpiType: j['kpi_type'] ?? '',
    targetValue: _toDouble(j['target_value']), currentValue: _toDouble(j['current_value']),
    periodStart: j['period_start'] ?? '', periodEnd: j['period_end'] ?? '',
    isActive: j['is_active'] ?? true, completionPercentage: _toDouble(j['completion_percentage']),
    isAchieved: j['is_achieved'] ?? false,
  );
}
