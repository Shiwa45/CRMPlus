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

class LeadModel {
  final int id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? company;
  final String? jobTitle;
  final String status;
  final String priority;
  final int? sourceId;
  final String? sourceName;
  final int? assignedToId;
  final String? assignedToName;
  final int? createdById;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? budget;
  final String? requirements;
  final String? notes;
  final bool isHot;
  final bool isOverdue;
  final String? lastContacted;
  final String createdAt;
  final String updatedAt;

  LeadModel({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.company,
    this.jobTitle,
    required this.status,
    required this.priority,
    this.sourceId,
    this.sourceName,
    this.assignedToId,
    this.assignedToName,
    this.createdById,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.budget,
    this.requirements,
    this.notes,
    required this.isHot,
    required this.isOverdue,
    this.lastContacted,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: _toInt(json['id']),
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      company: json['company'],
      jobTitle: json['job_title'],
      status: json['status'] ?? 'new',
      priority: json['priority'] ?? 'warm',
      sourceId: _toIntNullable(json['source']),
      sourceName: json['source_name'],
      assignedToId: _toIntNullable(json['assigned_to']),
      assignedToName: json['assigned_to_name'],
      createdById: _toIntNullable(json['created_by']),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'] ?? 'India',
      postalCode: json['postal_code'],
      budget: json['budget'] != null ? _toDouble(json['budget']) : null,
      requirements: json['requirements'],
      notes: json['notes'],
      isHot: json['is_hot'] ?? false,
      isOverdue: json['is_overdue'] ?? false,
      lastContacted: json['last_contacted'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'phone': phone,
    'company': company,
    'job_title': jobTitle,
    'status': status,
    'priority': priority,
    'source': sourceId,
    'assigned_to': assignedToId,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'postal_code': postalCode,
    'budget': budget,
    'requirements': requirements,
    'notes': notes,
  };

  LeadModel copyWith({
    String? status,
    String? priority,
    int? assignedToId,
    String? notes,
  }) {
    return LeadModel(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      company: company,
      jobTitle: jobTitle,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      sourceId: sourceId,
      sourceName: sourceName,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName,
      createdById: createdById,
      address: address,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      budget: budget,
      requirements: requirements,
      notes: notes ?? this.notes,
      isHot: isHot,
      isOverdue: isOverdue,
      lastContacted: lastContacted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class LeadSourceModel {
  final int id;
  final String name;
  final String? description;
  final bool isActive;

  LeadSourceModel({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
  });

  factory LeadSourceModel.fromJson(Map<String, dynamic> json) {
    return LeadSourceModel(
      id: _toInt(json['id']),
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }
}

class LeadActivityModel {
  final int id;
  final int leadId;
  final int userId;
  final String? userName;
  final String activityType;
  final String subject;
  final String? description;
  final String createdAt;

  LeadActivityModel({
    required this.id,
    required this.leadId,
    required this.userId,
    this.userName,
    required this.activityType,
    required this.subject,
    this.description,
    required this.createdAt,
  });

  factory LeadActivityModel.fromJson(Map<String, dynamic> json) {
    return LeadActivityModel(
      id: _toInt(json['id']),
      leadId: _toInt(json['lead']),
      userId: _toInt(json['user']),
      userName: json['user_name'],
      activityType: json['activity_type'] ?? 'note',
      subject: json['subject'] ?? '',
      description: json['description'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'lead': leadId,
    'activity_type': activityType,
    'subject': subject,
    'description': description,
  };
}

class LeadStats {
  final int total;
  final int newLeads;
  final int contacted;
  final int qualified;
  final int won;
  final int lost;
  final int hot;
  final int warm;
  final int cold;
  final double conversionRate;

  LeadStats({
    required this.total,
    required this.newLeads,
    required this.contacted,
    required this.qualified,
    required this.won,
    required this.lost,
    required this.hot,
    required this.warm,
    required this.cold,
    required this.conversionRate,
  });

  factory LeadStats.fromJson(Map<String, dynamic> json) {
    return LeadStats(
      total: _toInt(json['total']),
      newLeads: _toInt(json['new']),
      contacted: _toInt(json['contacted']),
      qualified: _toInt(json['qualified']),
      won: _toInt(json['won']),
      lost: _toInt(json['lost']),
      hot: _toInt(json['hot']),
      warm: _toInt(json['warm']),
      cold: _toInt(json['cold']),
      conversionRate: _toDouble(json['conversion_rate']),
    );
  }
}
