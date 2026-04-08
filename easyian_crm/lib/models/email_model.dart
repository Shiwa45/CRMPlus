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

class EmailConfigModel {
  final int id;
  final int userId;
  final String name;
  final String provider;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String fromEmail;
  final String fromName;
  final String? replyTo;
  final bool useTls;
  final bool useSsl;
  final bool isDefault;
  final bool isActive;
  final int dailyLimit;
  final String createdAt;

  EmailConfigModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.provider,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.fromEmail,
    required this.fromName,
    this.replyTo,
    required this.useTls,
    required this.useSsl,
    required this.isDefault,
    required this.isActive,
    required this.dailyLimit,
    required this.createdAt,
  });

  factory EmailConfigModel.fromJson(Map<String, dynamic> json) {
    return EmailConfigModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user']),
      name: json['name'] ?? '',
      provider: json['provider'] ?? 'smtp',
      smtpHost: json['smtp_host'] ?? '',
      smtpPort: _toInt(json['smtp_port'], fallback: 587),
      smtpUsername: json['smtp_username'] ?? '',
      fromEmail: json['from_email'] ?? '',
      fromName: json['from_name'] ?? '',
      replyTo: json['reply_to'],
      useTls: json['use_tls'] ?? true,
      useSsl: json['use_ssl'] ?? false,
      isDefault: json['is_default'] ?? false,
      isActive: json['is_active'] ?? true,
      dailyLimit: _toInt(json['daily_limit'], fallback: 500),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class EmailTemplateModel {
  final int id;
  final int userId;
  final String name;
  final String templateType;
  final String subject;
  final String bodyHtml;
  final String? bodyText;
  final bool isShared;
  final bool isActive;
  final int usageCount;
  final String? lastUsed;
  final String createdAt;

  EmailTemplateModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.templateType,
    required this.subject,
    required this.bodyHtml,
    this.bodyText,
    required this.isShared,
    required this.isActive,
    required this.usageCount,
    this.lastUsed,
    required this.createdAt,
  });

  factory EmailTemplateModel.fromJson(Map<String, dynamic> json) {
    return EmailTemplateModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user']),
      name: json['name'] ?? '',
      templateType: json['template_type'] ?? 'general',
      subject: json['subject'] ?? '',
      bodyHtml: json['body_html'] ?? '',
      bodyText: json['body_text'],
      isShared: json['is_shared'] ?? false,
      isActive: json['is_active'] ?? true,
      usageCount: _toInt(json['usage_count']),
      lastUsed: json['last_used'],
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'template_type': templateType,
    'subject': subject,
    'body_html': bodyHtml,
    'body_text': bodyText,
    'is_shared': isShared,
    'is_active': isActive,
  };
}

class EmailCampaignModel {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String status;
  final int? configId;
  final String? configName;
  final int? templateId;
  final String? templateName;
  final int totalRecipients;
  final int sentCount;
  final int openCount;
  final int clickCount;
  final int failedCount;
  final String? scheduledAt;
  final String? startedAt;
  final String? completedAt;
  final String createdAt;

  EmailCampaignModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.status,
    this.configId,
    this.configName,
    this.templateId,
    this.templateName,
    required this.totalRecipients,
    required this.sentCount,
    required this.openCount,
    required this.clickCount,
    required this.failedCount,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
  });

  double get openRate => sentCount > 0 ? (openCount / sentCount) * 100 : 0;
  double get clickRate => openCount > 0 ? (clickCount / openCount) * 100 : 0;
  double get progress => totalRecipients > 0 ? (sentCount / totalRecipients) * 100 : 0;

  factory EmailCampaignModel.fromJson(Map<String, dynamic> json) {
    return EmailCampaignModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user']),
      name: json['name'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'draft',
      configId: _toIntNullable(json['config']),
      configName: json['config_name'],
      templateId: _toIntNullable(json['template']),
      templateName: json['template_name'],
      totalRecipients: _toInt(json['total_recipients']),
      sentCount: _toInt(json['sent_count']),
      openCount: _toInt(json['open_count']),
      clickCount: _toInt(json['click_count']),
      failedCount: _toInt(json['failed_count']),
      scheduledAt: json['scheduled_at'],
      startedAt: json['started_at'],
      completedAt: json['completed_at'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class EmailModel {
  final int id;
  final int userId;
  final int? leadId;
  final String? leadName;
  final int? templateId;
  final int? campaignId;
  final String subject;
  final String toEmail;
  final String status;
  final String? errorMessage;
  final String? sentAt;
  final String? openedAt;
  final int retryCount;
  final String createdAt;

  EmailModel({
    required this.id,
    required this.userId,
    this.leadId,
    this.leadName,
    this.templateId,
    this.campaignId,
    required this.subject,
    required this.toEmail,
    required this.status,
    this.errorMessage,
    this.sentAt,
    this.openedAt,
    required this.retryCount,
    required this.createdAt,
  });

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    return EmailModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user']),
      leadId: _toIntNullable(json['lead']),
      leadName: json['lead_name'],
      templateId: _toIntNullable(json['template']),
      campaignId: _toIntNullable(json['campaign']),
      subject: json['subject'] ?? '',
      toEmail: json['to_email'] ?? '',
      status: json['status'] ?? 'pending',
      errorMessage: json['error_message'],
      sentAt: json['sent_at'],
      openedAt: json['opened_at'],
      retryCount: _toInt(json['retry_count']),
      createdAt: json['created_at'] ?? '',
    );
  }
}

class EmailSequenceModel {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final bool isActive;
  final int stepsCount;
  final String createdAt;

  EmailSequenceModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.isActive,
    required this.stepsCount,
    required this.createdAt,
  });

  factory EmailSequenceModel.fromJson(Map<String, dynamic> json) {
    return EmailSequenceModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user']),
      name: json['name'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
      stepsCount: _toInt(json['steps_count']),
      createdAt: json['created_at'] ?? '',
    );
  }
}
