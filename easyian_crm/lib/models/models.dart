// lib/models/models.dart
// ignore_for_file: prefer_const_constructors

// ─── Helpers ──────────────────────────────────────────────────────────────────
int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

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
    required this.role, required this.roleDisplayName, required this.isActive,
    this.dateJoined});

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin    => role == 'admin' || role == 'superadmin';
  bool get isManager  => role == 'sales_manager' || isAdmin;

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: _toInt(j['id']), username: j['username'] ?? '', email: j['email'] ?? '',
    firstName: j['first_name'] ?? '', lastName: j['last_name'] ?? '',
    phone: j['phone'], department: j['department'],
    role: j['role'] ?? 'sales_rep',
    roleDisplayName: j['role_display_name'] ?? j['role'] ?? '',
    isActive: j['is_active'] ?? true, dateJoined: j['date_joined'],
  );
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
    jobTitle: j['job_title'], status: j['status'] ?? 'new',
    priority: j['priority'] ?? 'warm',
    sourceName: j['source_name'] ?? (j['source'] is Map ? j['source']['name'] : null),
    assignedToName: j['assigned_to_name'],
    sourceId: j['source'] is int ? j['source'] : (j['source'] is Map ? _toInt(j['source']['id'], fallback: -1) : _toInt(j['source_id'], fallback: -1)) == -1 ? null : _toInt(j['source_id']),
    assignedToId: j['assigned_to'] is int ? j['assigned_to'] : null,
    address: j['address'], city: j['city'], state: j['state'],
    country: j['country'] ?? 'India', postalCode: j['postal_code'],
    requirements: j['requirements'], notes: j['notes'],
    lastContacted: j['last_contacted'],
    budget: j['budget'] != null ? _toDouble(j['budget']) : null,
    isHot: j['priority'] == 'hot', isOverdue: j['is_overdue'] ?? false,
    createdAt: j['created_at'] ?? '', updatedAt: j['updated_at'] ?? '',
  );
}

class LeadSourceModel {
  final int id;
  final String name;
  final bool isActive;
  LeadSourceModel({required this.id, required this.name, required this.isActive});
  factory LeadSourceModel.fromJson(Map<String, dynamic> j) =>
      LeadSourceModel(id: _toInt(j['id']), name: j['name'] ?? '', isActive: j['is_active'] ?? true);
}

class LeadActivityModel {
  final int id, leadId;
  final String activityType, subject, createdAt;
  final String? description, userName;
  LeadActivityModel({required this.id, required this.leadId, required this.activityType,
    required this.subject, required this.createdAt, this.description, this.userName});
  factory LeadActivityModel.fromJson(Map<String, dynamic> j) => LeadActivityModel(
    id: _toInt(j['id']), leadId: _toInt(j['lead']),
    activityType: j['activity_type'] ?? 'note', subject: j['subject'] ?? '',
    description: j['description'], userName: j['user_name'], createdAt: j['created_at'] ?? '',
  );
}

// ─── Contact & Company ────────────────────────────────────────────────────────
class CompanyModel {
  final int id;
  final String name;
  final String? website, phone, email, industry, employeeSize, city, state, gstin, pan;
  final double? annualRevenue;
  final int contactsCount;
  final String createdAt;

  CompanyModel({required this.id, required this.name, this.website, this.phone,
    this.email, this.industry, this.employeeSize, this.city, this.state,
    this.gstin, this.pan, this.annualRevenue, required this.contactsCount,
    required this.createdAt});

  factory CompanyModel.fromJson(Map<String, dynamic> j) => CompanyModel(
    id: _toInt(j['id']), name: j['name'] ?? '',
    website: j['website'], phone: j['phone'], email: j['email'],
    industry: j['industry'], employeeSize: j['employee_size'],
    city: j['city'], state: j['state'], gstin: j['gstin'], pan: j['pan'],
    annualRevenue: j['annual_revenue'] != null ? _toDouble(j['annual_revenue']) : null,
    contactsCount: _toInt(j['contacts_count']),
    createdAt: j['created_at'] ?? '',
  );
}

class ContactModel {
  final int id;
  final String firstName, createdAt;
  final String? lastName, email, phone, mobile, whatsapp, jobTitle, department;
  final String? companyName, ownerName, city, state, pan, linkedin;
  final int? companyId;
  final List<String> tags;
  final bool isActive, doNotContact;
  final String? lastContacted;

  ContactModel({required this.id, required this.firstName, required this.createdAt,
    this.lastName, this.email, this.phone, this.mobile, this.whatsapp,
    this.jobTitle, this.department, this.companyName, this.ownerName,
    this.city, this.state, this.pan, this.linkedin, this.companyId,
    required this.tags, required this.isActive, required this.doNotContact,
    this.lastContacted});

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory ContactModel.fromJson(Map<String, dynamic> j) => ContactModel(
    id: _toInt(j['id']), firstName: j['first_name'] ?? '',
    lastName: j['last_name'], email: j['email'], phone: j['phone'],
    mobile: j['mobile'], whatsapp: j['whatsapp'],
    jobTitle: j['job_title'], department: j['department'],
    companyName: j['company_name'], ownerName: j['owner_name'],
    city: j['city'], state: j['state'], pan: j['pan'], linkedin: j['linkedin'],
    companyId: j['company'] is int ? j['company'] : null,
    tags: (j['tags'] as List? ?? []).map((e) => e.toString()).toList(),
    isActive: j['is_active'] ?? true, doNotContact: j['do_not_contact'] ?? false,
    lastContacted: j['last_contacted'], createdAt: j['created_at'] ?? '',
  );
}

// ─── Pipeline & Deals ─────────────────────────────────────────────────────────
class PipelineStageModel {
  final int id, order, probability;
  final String name, color;
  final bool isWon, isLost;
  final int dealsCount;
  final double dealsValue;

  PipelineStageModel({required this.id, required this.name, required this.order,
    required this.probability, required this.color, required this.isWon,
    required this.isLost, required this.dealsCount, required this.dealsValue});

  factory PipelineStageModel.fromJson(Map<String, dynamic> j) => PipelineStageModel(
    id: _toInt(j['id']), name: j['name'] ?? '', order: _toInt(j['order']),
    probability: _toInt(j['probability']), color: j['color'] ?? '#6366f1',
    isWon: j['is_won'] ?? false, isLost: j['is_lost'] ?? false,
    dealsCount: _toInt(j['deals_count']), dealsValue: _toDouble(j['deals_value']),
  );
}

class PipelineModel {
  final int id;
  final String name;
  final String? description;
  final bool isDefault, isActive;
  final List<PipelineStageModel> stages;
  final int dealsCount;
  final double totalValue;

  PipelineModel({required this.id, required this.name, this.description, required this.isDefault,
    required this.isActive, required this.stages, required this.dealsCount,
    required this.totalValue});

  factory PipelineModel.fromJson(Map<String, dynamic> j) => PipelineModel(
    id: _toInt(j['id']), name: j['name'] ?? '',
    description: j['description'],
    isDefault: j['is_default'] ?? false, isActive: j['is_active'] ?? true,
    stages: (j['stages'] as List? ?? [])
        .map((s) => PipelineStageModel.fromJson(s as Map<String, dynamic>)).toList(),
    dealsCount: _toInt(j['deals_count']),
    totalValue: _toDouble(j['total_value']),
  );
}

class DealModel {
  final int id;
  final String title, priority, currency, createdAt, updatedAt;
  final String? stageName, pipelineName, contactName, companyName, ownerName;
  final int? stageId, pipelineId, contactId, companyId, ownerId;
  final int stageProbability;
  final String stageColor;
  final double value, weightedValue;
  final String? closeDate, wonAt, lostAt, description;
  final List<String> tags;

  DealModel({required this.id, required this.title, required this.priority,
    required this.currency, required this.createdAt, required this.updatedAt,
    this.stageName, this.pipelineName, this.contactName, this.companyName,
    this.ownerName, this.stageId, this.pipelineId, this.contactId,
    this.companyId, this.ownerId, required this.stageProbability,
    required this.stageColor, required this.value, required this.weightedValue,
    this.closeDate, this.wonAt, this.lostAt, this.description, required this.tags});

  bool get isWon  => wonAt != null;
  bool get isLost => lostAt != null && wonAt == null;
  bool get isOpen => wonAt == null && lostAt == null;

  factory DealModel.fromJson(Map<String, dynamic> j) => DealModel(
    id: _toInt(j['id']), title: j['title'] ?? '',
    priority: j['priority'] ?? 'medium', currency: j['currency'] ?? 'INR',
    stageName: j['stage_name'], pipelineName: j['pipeline_name'],
    contactName: j['contact_name'], companyName: j['company_name'],
    ownerName: j['owner_name'],
    stageId: j['stage'] is int ? j['stage'] : null,
    pipelineId: j['pipeline'] is int ? j['pipeline'] : null,
    contactId: j['contact'] is int ? j['contact'] : null,
    companyId: j['company'] is int ? j['company'] : null,
    ownerId: j['owner'] is int ? j['owner'] : null,
    stageProbability: _toInt(j['stage_probability']),
    stageColor: j['stage_color'] ?? '#6366f1',
    value: _toDouble(j['value']),
    weightedValue: _toDouble(j['weighted_value']),
    closeDate: j['close_date'], wonAt: j['won_at'], lostAt: j['lost_at'],
    description: j['description'],
    tags: (j['tags'] as List? ?? []).map((e) => e.toString()).toList(),
    createdAt: j['created_at'] ?? '', updatedAt: j['updated_at'] ?? '',
  );
}

class KanbanColumnModel {
  final PipelineStageModel stage;
  final List<DealModel> deals;
  final double totalValue;

  KanbanColumnModel({required this.stage, required this.deals, required this.totalValue});

  factory KanbanColumnModel.fromJson(Map<String, dynamic> j) => KanbanColumnModel(
    stage: PipelineStageModel.fromJson(j['stage'] as Map<String, dynamic>),
    deals: (j['deals'] as List? ?? [])
        .map((d) => DealModel.fromJson(d as Map<String, dynamic>)).toList(),
    totalValue: _toDouble(j['total_value']),
  );
}

// ─── Quotes & Invoices ────────────────────────────────────────────────────────
class ProductModel {
  final int id;
  final String name, code, productType, unit;
  final String? description, hsnSacCode;
  final double unitPrice;
  final int gstRate;
  final bool isActive;

  ProductModel({required this.id, required this.name, required this.code,
    required this.productType, required this.unit, this.description, this.hsnSacCode,
    required this.unitPrice, required this.gstRate, required this.isActive});

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
    id: _toInt(j['id']), name: j['name'] ?? '', code: j['code'] ?? '',
    productType: j['product_type'] ?? 'service', unit: j['unit'] ?? 'nos',
    description: j['description'], hsnSacCode: j['hsn_sac_code'],
    unitPrice: _toDouble(j['unit_price']), gstRate: _toInt(j['gst_rate']),
    isActive: j['is_active'] ?? true,
  );
}

class TaxProfileModel {
  final int id;
  final String name, gstin, pan, city, state;
  final String? phone, email, bankName, upiId;

  TaxProfileModel({required this.id, required this.name, required this.gstin,
    required this.pan, required this.city, required this.state,
    this.phone, this.email, this.bankName, this.upiId});

  factory TaxProfileModel.fromJson(Map<String, dynamic> j) => TaxProfileModel(
    id: _toInt(j['id']), name: j['name'] ?? '', gstin: j['gstin'] ?? '',
    pan: j['pan'] ?? '', city: j['city'] ?? '', state: j['state'] ?? '',
    phone: j['phone'], email: j['email'], bankName: j['bank_name'], upiId: j['upi_id'],
  );
}

class QuoteItemModel {
  final int id, gstRate, order;
  final String name, unit;
  final String? description, hsnSacCode;
  final double quantity, unitPrice, discountPct, cessRate, amount;
  final int? productId;

  QuoteItemModel({required this.id, required this.gstRate, required this.order,
    required this.name, required this.unit, this.description, this.hsnSacCode,
    required this.quantity, required this.unitPrice, required this.discountPct,
    required this.cessRate, required this.amount, this.productId});

  factory QuoteItemModel.fromJson(Map<String, dynamic> j) => QuoteItemModel(
    id: _toInt(j['id']),
    gstRate: _toInt(j['gst_rate'] ?? j['tax_rate']),
    order: _toInt(j['order']),
    name: (j['name'] ?? j['description'] ?? 'Item').toString(),
    unit: j['unit'] ?? 'nos',
    description: j['description'], hsnSacCode: j['hsn_sac_code'],
    quantity: _toDouble(j['quantity']), unitPrice: _toDouble(j['unit_price']),
    discountPct: _toDouble(j['discount_pct']), cessRate: _toDouble(j['cess_rate']),
    amount: _toDouble(j['amount']),
    productId: j['product'] is int ? j['product'] : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'description': description, 'hsn_sac_code': hsnSacCode,
    'quantity': quantity, 'unit': unit, 'unit_price': unitPrice,
    'discount_pct': discountPct, 'gst_rate': gstRate, 'cess_rate': cessRate,
    'order': order, if (productId != null) 'product': productId,
  };
}

class QuoteModel {
  final int id;
  final String quoteNumber, title, status, currency, quoteDate, createdAt;
  final String? contactName, companyName, ownerName, taxProfileName;
  final String? validUntil;
  final double subtotal, discountPct, taxableAmount, cgstTotal, sgstTotal,
      igstTotal, cessTotal, grandTotal;
  final List<QuoteItemModel> items;

  QuoteModel({required this.id, required this.quoteNumber, required this.title,
    required this.status, required this.currency, required this.quoteDate,
    required this.createdAt, this.contactName, this.companyName, this.ownerName,
    this.taxProfileName, this.validUntil, required this.subtotal,
    required this.discountPct, required this.taxableAmount, required this.cgstTotal,
    required this.sgstTotal, required this.igstTotal, required this.cessTotal,
    required this.grandTotal, required this.items});

  factory QuoteModel.fromJson(Map<String, dynamic> j) => QuoteModel(
    id: _toInt(j['id']), quoteNumber: j['quote_number'] ?? '',
    title: j['title'] ?? '', status: j['status'] ?? 'draft',
    currency: j['currency'] ?? 'INR',
    quoteDate: j['quote_date'] ?? (j['created_at'] ?? ''),
    createdAt: j['created_at'] ?? '',
    contactName: j['contact_name'], companyName: j['company_name'],
    ownerName: j['owner_name'], taxProfileName: j['tax_profile_name'],
    validUntil: j['valid_until'],
    subtotal: _toDouble(j['subtotal']),
    discountPct: _toDouble(j['discount_pct']),
    taxableAmount: _toDouble(j['taxable_amount'] ?? j['subtotal']),
    cgstTotal: _toDouble(j['cgst_total']),
    sgstTotal: _toDouble(j['sgst_total']),
    igstTotal: _toDouble(j['igst_total']),
    cessTotal: _toDouble(j['cess_total']),
    grandTotal: _toDouble(j['grand_total'] ?? j['total']),
    items: (j['items'] as List? ?? [])
        .map((i) => QuoteItemModel.fromJson(i as Map<String, dynamic>)).toList(),
  );
}

class PaymentModel {
  final int id;
  final String method, status, paymentDate;
  final double amount;
  final String? transactionId, reference, notes, recordedByName;

  PaymentModel({required this.id, required this.method, required this.status,
    required this.paymentDate, required this.amount, this.transactionId,
    this.reference, this.notes, this.recordedByName});

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id: _toInt(j['id']), method: j['method'] ?? 'upi', status: j['status'] ?? 'confirmed',
    paymentDate: j['payment_date'] ?? '', amount: _toDouble(j['amount']),
    transactionId: j['transaction_id'], reference: j['reference'],
    notes: j['notes'], recordedByName: j['recorded_by_name'] ?? j['received_by_name'],
  );
}

class InvoiceItemModel {
  final int id, order;
  final String description;
  final double quantity, unitPrice, discountPct, taxRate, amount;
  final int? productId;

  InvoiceItemModel({
    required this.id,
    required this.order,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discountPct,
    required this.taxRate,
    required this.amount,
    this.productId,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> j) => InvoiceItemModel(
    id: _toInt(j['id']),
    order: _toInt(j['order']),
    description: (j['description'] ?? '').toString(),
    quantity: _toDouble(j['quantity']),
    unitPrice: _toDouble(j['unit_price']),
    discountPct: _toDouble(j['discount_pct']),
    taxRate: _toDouble(j['tax_rate']),
    amount: _toDouble(j['amount']),
    productId: j['product'] is int ? j['product'] : null,
  );
}

class InvoiceModel {
  final int id;
  final String invoiceNumber, status, currency, invoiceDate, createdAt;
  final String? contactName, companyName, ownerName, dueDate;
  final double grandTotal, amountPaid, amountDue;
  final bool isEinvoice;
  final List<PaymentModel> payments;
  final List<InvoiceItemModel> items;

  InvoiceModel({required this.id, required this.invoiceNumber, required this.status,
    required this.currency, required this.invoiceDate, required this.createdAt,
    this.contactName, this.companyName, this.ownerName, this.dueDate,
    required this.grandTotal, required this.amountPaid, required this.amountDue,
    required this.isEinvoice, required this.payments, required this.items});

  factory InvoiceModel.fromJson(Map<String, dynamic> j) => InvoiceModel(
    id: _toInt(j['id']), invoiceNumber: j['invoice_number'] ?? '',
    status: j['status'] ?? 'draft', currency: j['currency'] ?? 'INR',
    invoiceDate: j['invoice_date'] ?? j['issue_date'] ?? (j['created_at'] ?? ''),
    createdAt: j['created_at'] ?? '',
    contactName: j['contact_name'], companyName: j['company_name'],
    ownerName: j['owner_name'], dueDate: j['due_date'],
    grandTotal: _toDouble(j['grand_total'] ?? j['total']),
    amountPaid: _toDouble(j['amount_paid']),
    amountDue: _toDouble(j['amount_due']),
    isEinvoice: j['is_einvoice'] ?? false,
    payments: (j['payments'] as List? ?? [])
        .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>)).toList(),
    items: (j['items'] as List? ?? [])
        .map((i) => InvoiceItemModel.fromJson(i as Map<String, dynamic>)).toList(),
  );
}

// ─── Tickets ──────────────────────────────────────────────────────────────────
class TicketCategoryModel {
  final int id;
  final String name, color;
  TicketCategoryModel({required this.id, required this.name, required this.color});
  factory TicketCategoryModel.fromJson(Map<String, dynamic> j) =>
      TicketCategoryModel(id: _toInt(j['id']), name: j['name'] ?? '', color: j['color'] ?? '#6366f1');
}

class TicketReplyModel {
  final int id;
  final String body, replyType, createdAt;
  final String? authorName;
  final bool isPublic;
  TicketReplyModel({required this.id, required this.body, required this.replyType,
    required this.createdAt, this.authorName, required this.isPublic});
  factory TicketReplyModel.fromJson(Map<String, dynamic> j) => TicketReplyModel(
    id: _toInt(j['id']), body: j['body'] ?? '',
    replyType: j['reply_type'] ?? 'reply', createdAt: j['created_at'] ?? '',
    authorName: j['author_name'], isPublic: j['is_public'] ?? true,
  );
}

class TicketModel {
  final int id;
  final String ticketNumber, subject, status, priority, channel, createdAt;
  final String? contactName, companyName, categoryName, categoryColor, assignedToName;
  final String? firstResponseDue, resolutionDue, resolvedAt;
  final bool slaBreached, isOverdue, responseOverdue;
  final int? csatScore;
  final int repliesCount;
  final List<TicketReplyModel> replies;

  TicketModel({required this.id, required this.ticketNumber, required this.subject,
    required this.status, required this.priority, required this.channel,
    required this.createdAt, this.contactName, this.companyName, this.categoryName,
    this.categoryColor, this.assignedToName, this.firstResponseDue, this.resolutionDue,
    this.resolvedAt, required this.slaBreached, required this.isOverdue,
    required this.responseOverdue, this.csatScore, required this.repliesCount,
    required this.replies});

  factory TicketModel.fromJson(Map<String, dynamic> j) => TicketModel(
    id: _toInt(j['id']), ticketNumber: j['ticket_number'] ?? '#${_toInt(j['id'])}',
    subject: j['subject'] ?? '', status: j['status'] ?? 'open',
    priority: j['priority'] ?? 'medium', channel: j['channel'] ?? j['source'] ?? 'manual',
    createdAt: j['created_at'] ?? '',
    contactName: j['contact_name'], companyName: j['company_name'],
    categoryName: j['category_name'], categoryColor: j['category_color'],
    assignedToName: j['assigned_to_name'],
    firstResponseDue: j['first_response_due'],
    resolutionDue: j['resolution_due'], resolvedAt: j['resolved_at'],
    slaBreached: j['sla_breached'] ?? false,
    isOverdue: j['is_overdue'] ?? false,
    responseOverdue: j['response_overdue'] ?? false,
    csatScore: j['csat_score'],
    repliesCount: _toInt(j['replies_count']),
    replies: (j['replies'] as List? ?? [])
        .map((r) => TicketReplyModel.fromJson(r as Map<String, dynamic>)).toList(),
  );
}

// ─── Tasks ────────────────────────────────────────────────────────────────────
class TaskModel {
  final int id;
  final String title, taskType, status, priority, createdAt;
  final String? description, dueDate, assignedToName, completedAt;
  final bool isOverdue;
  final int? leadId, dealId, contactId, ticketId;

  TaskModel({required this.id, required this.title, required this.taskType,
    required this.status, required this.priority, required this.createdAt,
    this.description, this.dueDate, this.assignedToName, this.completedAt,
    required this.isOverdue, this.leadId, this.dealId, this.contactId, this.ticketId});

  factory TaskModel.fromJson(Map<String, dynamic> j) => TaskModel(
    id: _toInt(j['id']), title: j['title'] ?? '',
    taskType: j['task_type'] ?? 'follow_up', status: j['status'] ?? 'todo',
    priority: j['priority'] ?? 'medium', createdAt: j['created_at'] ?? '',
    description: j['description'], dueDate: j['due_date'],
    assignedToName: j['assigned_to_name'], completedAt: j['completed_at'],
    isOverdue: j['is_overdue'] ?? false,
    leadId: j['lead_id'], dealId: j['deal_id'],
    contactId: j['contact_id'], ticketId: j['ticket_id'],
  );
}

// ─── Notification ─────────────────────────────────────────────────────────────
class NotificationModel {
  final int id;
  final String notifType, title, body, createdAt;
  final bool isRead;
  final String? link;

  NotificationModel({required this.id, required this.notifType, required this.title,
    required this.body, required this.createdAt, required this.isRead, this.link});

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id: _toInt(j['id']), notifType: j['notif_type'] ?? 'system',
    title: j['title'] ?? '', body: j['body'] ?? '',
    createdAt: j['created_at'] ?? '', isRead: j['is_read'] ?? false,
    link: j['link'],
  );
}

// ─── Workflow ─────────────────────────────────────────────────────────────────
class WorkflowModel {
  final int id, runCount;
  final String name, trigger, createdAt;
  final String? description, lastRunAt;
  final bool isActive;

  WorkflowModel({required this.id, required this.runCount, required this.name,
    required this.trigger, required this.createdAt, this.description, this.lastRunAt,
    required this.isActive});

  factory WorkflowModel.fromJson(Map<String, dynamic> j) => WorkflowModel(
    id: _toInt(j['id']), runCount: _toInt(j['run_count']),
    name: j['name'] ?? '', trigger: j['trigger'] ?? '',
    createdAt: j['created_at'] ?? '', description: j['description'],
    lastRunAt: j['last_run_at'], isActive: j['is_active'] ?? true,
  );
}

// ─── Dashboard Stats (extended) ───────────────────────────────────────────────
class DashboardStats {
  final int totalLeads, newLeads, wonLeads, lostLeads, overdueLeads;
  final double conversionRate, totalRevenue, avgDealSize;
  final int totalUsers, totalCampaigns, totalEmails;
  final Map<String, int> leadsByStatus, leadsByPriority;
  final List<MonthlyData> monthlyData;
  final List<FunnelData> funnelData;
  final List<SourcePerformance> sourcePerformance;
  // New
  final int totalContacts, totalCompanies, openDeals, wonDealsCount;
  final double pipelineValue, weightedPipeline, totalInvoiced, totalCollected, totalOutstanding;
  final int openTickets, overdueTickets, myTasksOverdue;
  final double avgCsat;

  DashboardStats({
    required this.totalLeads, required this.newLeads, required this.wonLeads,
    required this.lostLeads, required this.overdueLeads, required this.conversionRate,
    required this.totalRevenue, required this.avgDealSize,
    required this.totalUsers, required this.totalCampaigns, required this.totalEmails,
    required this.leadsByStatus, required this.leadsByPriority,
    required this.monthlyData, required this.funnelData, required this.sourcePerformance,
    this.totalContacts = 0, this.totalCompanies = 0,
    this.openDeals = 0, this.wonDealsCount = 0,
    this.pipelineValue = 0, this.weightedPipeline = 0,
    this.totalInvoiced = 0, this.totalCollected = 0, this.totalOutstanding = 0,
    this.openTickets = 0, this.overdueTickets = 0, this.myTasksOverdue = 0,
    this.avgCsat = 0,
  });

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
      }
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final key = item['status'] ?? item['priority'] ?? item['name'];
            final v   = item['count'] ?? item['value'];
            if (key != null) {
              final parsed = v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);
              if (parsed != null) out[key.toString()] = parsed;
            }
          }
        }
      }
      return out;
    }

    final deals   = j['deals']   as Map<String, dynamic>? ?? {};
    final revenue = j['revenue'] as Map<String, dynamic>? ?? {};
    final tickets = j['tickets'] as Map<String, dynamic>? ?? {};
    final contacts = j['contacts'] as Map<String, dynamic>? ?? {};
    final tasks   = j['tasks']   as Map<String, dynamic>? ?? {};

    return DashboardStats(
      totalLeads: _toInt(j['total_leads']),
      newLeads:   _toInt(j['new_leads'] ?? j['new']),
      wonLeads:   _toInt(j['won_leads']  ?? j['won']),
      lostLeads:  _toInt(j['lost_leads'] ?? j['lost']),
      overdueLeads: _toInt(j['overdue_leads']),
      conversionRate: _toDouble(j['conversion_rate']),
      totalRevenue:   _toDouble(j['total_revenue']),
      avgDealSize:    _toDouble(j['avg_deal_size']),
      totalUsers:     _toInt(j['total_users']),
      totalCampaigns: _toInt(j['total_campaigns']),
      totalEmails:    _toInt(j['total_emails']),
      leadsByStatus:   parseMap(j['leads_by_status']),
      leadsByPriority: parseMap(j['leads_by_priority']),
      monthlyData: (j['monthly_data'] as List? ?? [])
          .whereType<Map>()
          .map((e) => MonthlyData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      funnelData:  (j['funnel_data']  as List? ?? [])
          .whereType<Map>()
          .map((e) => FunnelData.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      sourcePerformance: (j['source_performance'] as List? ?? [])
          .whereType<Map>()
          .map((e) => SourcePerformance.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      totalContacts:  _toInt(contacts['total_contacts']),
      totalCompanies: _toInt(contacts['total_companies']),
      openDeals:      _toInt(deals['open']),
      wonDealsCount:  _toInt(deals['won_period']),
      pipelineValue:  _toDouble(deals['pipeline_value']),
      weightedPipeline: _toDouble(deals['weighted_pipeline']),
      totalInvoiced:    _toDouble(revenue['total_invoiced']),
      totalCollected:   _toDouble(revenue['total_collected']),
      totalOutstanding: _toDouble(revenue['outstanding']),
      openTickets:      _toInt(tickets['open']),
      overdueTickets:   _toInt(tickets['overdue']),
      myTasksOverdue:   _toInt(tasks['overdue']),
      avgCsat:          _toDouble(tickets['avg_csat']),
    );
  }

  factory DashboardStats.empty() => DashboardStats(
    totalLeads: 0, newLeads: 0, wonLeads: 0, lostLeads: 0, overdueLeads: 0,
    conversionRate: 0, totalRevenue: 0, avgDealSize: 0,
    totalUsers: 0, totalCampaigns: 0, totalEmails: 0,
    leadsByStatus: {}, leadsByPriority: {},
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
    month: j['month'] ?? '', monthShort: j['month_short'] ?? j['month'] ?? '',
    total: _toInt(j['total'] ?? j['count']),
    won: _toInt(j['won']), lost: _toInt(j['lost']),
    conversionRate: _toDouble(j['conversion_rate']),
    revenue: _toDouble(j['revenue']),
  );
}

class FunnelData {
  final String stage; final int count; final double percentage;
  FunnelData({required this.stage, required this.count, required this.percentage});
  factory FunnelData.fromJson(Map<String, dynamic> j) => FunnelData(
    stage: j['stage'] ?? '', count: _toInt(j['count']),
    percentage: _toDouble(j['percentage']),
  );
}

class SourcePerformance {
  final String source; final int total, won; final double conversionRate;
  SourcePerformance({required this.source, required this.total, required this.won, required this.conversionRate});
  factory SourcePerformance.fromJson(Map<String, dynamic> j) => SourcePerformance(
    source: (j['source__name'] ?? j['source'] ?? 'Direct').toString(),
    total: _toInt(j['total']), won: _toInt(j['won']),
    conversionRate: _toDouble(j['conversion_rate']),
  );

  String get name => source;
  int get totalLeads => total;
  int get wonLeads => won;
}

// ─── Email models (existing — unchanged) ─────────────────────────────────────
class EmailConfigModel {
  final int id, userId, smtpPort, dailyLimit;
  final String name, provider, smtpHost, smtpUsername, fromEmail, fromName, createdAt;
  final String? replyTo;
  final bool useTls, useSsl, isDefault, isActive;
  EmailConfigModel({required this.id, required this.userId, required this.name,
    required this.provider, required this.smtpHost, required this.smtpPort,
    required this.smtpUsername, required this.fromEmail, required this.fromName,
    this.replyTo, required this.useTls, required this.useSsl,
    required this.isDefault, required this.isActive, required this.dailyLimit,
    required this.createdAt});
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
    usageCount: _toInt(j['usage_count']), lastUsed: j['last_used'],
    createdAt: j['created_at'] ?? '',
  );
}

class EmailCampaignModel {
  final int id, userId, totalRecipients, sentCount, openCount, clickCount, failedCount;
  final String name, status, createdAt;
  final String? scheduledAt, startedAt, completedAt;
  final int? templateId;
  EmailCampaignModel({required this.id, required this.userId, required this.name,
    required this.status, required this.createdAt, required this.totalRecipients,
    required this.sentCount, required this.openCount, required this.clickCount,
    required this.failedCount, this.scheduledAt, this.startedAt, this.completedAt,
    this.templateId});
  factory EmailCampaignModel.fromJson(Map<String, dynamic> j) => EmailCampaignModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), name: j['name'] ?? '',
    status: j['status'] ?? 'draft', createdAt: j['created_at'] ?? '',
    totalRecipients: _toInt(j['total_recipients']), sentCount: _toInt(j['emails_sent']),
    openCount: _toInt(j['open_count'] ?? 0), clickCount: _toInt(j['click_count'] ?? 0),
    failedCount: _toInt(j['emails_failed']),
    scheduledAt: j['scheduled_at'], startedAt: j['started_at'],
    completedAt: j['completed_at'], templateId: j['template'] is int ? j['template'] : null,
  );

  String? get description => null;
  double get progress => totalRecipients == 0 ? 0 : (sentCount / totalRecipients) * 100;
  double get openRate => totalRecipients == 0 ? 0 : (openCount / totalRecipients) * 100;
}

class EmailModel {
  final int id;
  final String subject, status, createdAt;
  final String? toEmail, toName, openedAt, clickedAt, bouncedAt;
  final int? campaignId, leadId;
  EmailModel({required this.id, required this.subject, required this.status,
    required this.createdAt, this.toEmail, this.toName, this.openedAt,
    this.clickedAt, this.bouncedAt, this.campaignId, this.leadId});
  factory EmailModel.fromJson(Map<String, dynamic> j) => EmailModel(
    id: _toInt(j['id']), subject: j['subject'] ?? '', status: j['status'] ?? 'pending',
    createdAt: j['created_at'] ?? '', toEmail: j['to_email'], toName: j['to_name'],
    openedAt: j['opened_at'], clickedAt: j['clicked_at'], bouncedAt: j['bounced_at'],
    campaignId: j['campaign'] is int ? j['campaign'] : null,
    leadId: j['lead'] is int ? j['lead'] : null,
  );

  String? get leadName => toName;
  String? get sentAt => createdAt;
}

class EmailSequenceModel {
  final int id, userId, stepsCount, enrollmentsCount;
  final String name, status, createdAt;
  EmailSequenceModel({required this.id, required this.userId, required this.name,
    required this.status, required this.createdAt, required this.stepsCount,
    required this.enrollmentsCount});
  factory EmailSequenceModel.fromJson(Map<String, dynamic> j) => EmailSequenceModel(
    id: _toInt(j['id']), userId: _toInt(j['user']), name: j['name'] ?? '',
    status: j['status'] ?? 'draft', createdAt: j['created_at'] ?? '',
    stepsCount: _toInt(j['steps_count'] ?? 0),
    enrollmentsCount: _toInt(j['enrollments_count'] ?? 0),
  );

  String? get description => null;
  bool get isActive => status == 'active';
}

class KPITargetModel {
  final int id;
  final int userId;
  final String kpiType;
  final double targetValue;
  final double currentValue;
  final String periodStart;
  final String periodEnd;
  final bool isActive;
  final double completionPercentage;
  final bool isAchieved;
  final String createdAt;

  KPITargetModel({
    required this.id,
    required this.userId,
    required this.kpiType,
    required this.targetValue,
    required this.currentValue,
    required this.periodStart,
    required this.periodEnd,
    required this.isActive,
    required this.completionPercentage,
    required this.isAchieved,
    required this.createdAt,
  });

  factory KPITargetModel.fromJson(Map<String, dynamic> json) {
    return KPITargetModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user']),
      kpiType: json['kpi_type'] ?? json['metric_name'] ?? '',
      targetValue: _toDouble(json['target_value']),
      currentValue: _toDouble(json['current_value']),
      periodStart: json['period_start'] ?? '',
      periodEnd: json['period_end'] ?? '',
      isActive: json['is_active'] ?? true,
      completionPercentage: _toDouble(json['completion_percentage']),
      isAchieved: json['is_achieved'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}
