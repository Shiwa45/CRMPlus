int _toInt(dynamic v, {int fallback = 0}) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _toDouble(dynamic v, {double fallback = 0}) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

class DashboardStats {
  final int totalLeads;
  final int newLeads;
  final int wonLeads;
  final int lostLeads;
  final int overdueLeads;
  final double conversionRate;
  final double totalRevenue;
  final double avgDealSize;
  final int totalUsers;
  final int totalCampaigns;
  final int totalEmails;
  final Map<String, int> leadsByStatus;
  final Map<String, int> leadsByPriority;
  final List<MonthlyData> monthlyData;
  final List<FunnelData> funnelData;
  final List<SourcePerformance> sourcePerformance;

  DashboardStats({
    required this.totalLeads,
    required this.newLeads,
    required this.wonLeads,
    required this.lostLeads,
    required this.overdueLeads,
    required this.conversionRate,
    required this.totalRevenue,
    required this.avgDealSize,
    required this.totalUsers,
    required this.totalCampaigns,
    required this.totalEmails,
    required this.leadsByStatus,
    required this.leadsByPriority,
    required this.monthlyData,
    required this.funnelData,
    required this.sourcePerformance,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
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

    final leadsByStatus = parseMap(json['leads_by_status']);
    final leadsByPriority = parseMap(json['leads_by_priority']);

    List<MonthlyData> monthly = [];
    if (json['monthly_data'] is List) {
      monthly = (json['monthly_data'] as List)
          .map((e) => MonthlyData.fromJson(e))
          .toList();
    }

    List<FunnelData> funnel = [];
    if (json['funnel_data'] is List) {
      funnel = (json['funnel_data'] as List)
          .map((e) => FunnelData.fromJson(e))
          .toList();
    }

    List<SourcePerformance> sources = [];
    if (json['source_performance'] is List) {
      sources = (json['source_performance'] as List)
          .map((e) => SourcePerformance.fromJson(e))
          .toList();
    }

    return DashboardStats(
      totalLeads: _toInt(json['total_leads']),
      newLeads: _toInt(json['new_leads'] ?? json['new']),
      wonLeads: _toInt(json['won_leads'] ?? json['won']),
      lostLeads: _toInt(json['lost_leads'] ?? json['lost']),
      overdueLeads: _toInt(json['overdue_leads']),
      conversionRate: _toDouble(json['conversion_rate']),
      totalRevenue: _toDouble(json['total_revenue']),
      avgDealSize: _toDouble(json['avg_deal_size']),
      totalUsers: _toInt(json['total_users']),
      totalCampaigns: _toInt(json['total_campaigns']),
      totalEmails: _toInt(json['total_emails']),
      leadsByStatus: leadsByStatus,
      leadsByPriority: leadsByPriority,
      monthlyData: monthly,
      funnelData: funnel,
      sourcePerformance: sources,
    );
  }

  factory DashboardStats.empty() {
    return DashboardStats(
      totalLeads: 0,
      newLeads: 0,
      wonLeads: 0,
      lostLeads: 0,
      overdueLeads: 0,
      conversionRate: 0,
      totalRevenue: 0,
      avgDealSize: 0,
      totalUsers: 0,
      totalCampaigns: 0,
      totalEmails: 0,
      leadsByStatus: {},
      leadsByPriority: {},
      monthlyData: [],
      funnelData: [],
      sourcePerformance: [],
    );
  }
}

class MonthlyData {
  final String month;
  final String monthShort;
  final int total;
  final int won;
  final int lost;
  final double conversionRate;
  final double revenue;

  MonthlyData({
    required this.month,
    required this.monthShort,
    required this.total,
    required this.won,
    required this.lost,
    required this.conversionRate,
    required this.revenue,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['month'] ?? '',
      monthShort: json['month_short'] ?? '',
      total: _toInt(json['total']),
      won: _toInt(json['won']),
      lost: _toInt(json['lost']),
      conversionRate: _toDouble(json['conversion_rate']),
      revenue: _toDouble(json['revenue']),
    );
  }
}

class FunnelData {
  final String stage;
  final int count;
  final double percentage;

  FunnelData({
    required this.stage,
    required this.count,
    required this.percentage,
  });

  factory FunnelData.fromJson(Map<String, dynamic> json) {
    return FunnelData(
      stage: json['stage'] ?? '',
      count: _toInt(json['count']),
      percentage: _toDouble(json['percentage']),
    );
  }
}

class SourcePerformance {
  final String name;
  final int totalLeads;
  final int wonLeads;
  final double conversionRate;

  SourcePerformance({
    required this.name,
    required this.totalLeads,
    required this.wonLeads,
    required this.conversionRate,
  });

  factory SourcePerformance.fromJson(Map<String, dynamic> json) {
    return SourcePerformance(
      name: json['name'] ?? '',
      totalLeads: _toInt(json['total_leads']),
      wonLeads: _toInt(json['won_leads']),
      conversionRate: _toDouble(json['conversion_rate']),
    );
  }
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
  });

  factory KPITargetModel.fromJson(Map<String, dynamic> json) {
    return KPITargetModel(
      id: _toInt(json['id']),
      userId: _toInt(json['user']),
      kpiType: json['kpi_type'] ?? '',
      targetValue: _toDouble(json['target_value']),
      currentValue: _toDouble(json['current_value']),
      periodStart: json['period_start'] ?? '',
      periodEnd: json['period_end'] ?? '',
      isActive: json['is_active'] ?? true,
      completionPercentage: _toDouble(json['completion_percentage']),
      isAchieved: json['is_achieved'] ?? false,
    );
  }
}
