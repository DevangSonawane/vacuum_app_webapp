class DashboardData {
  const DashboardData({
    required this.stats,
    required this.jobStatusBreakdown,
    required this.monthlyStats,
    required this.revenueTrend,
    required this.quickOverview,
    required this.recentJobs,
    required this.todayVisits,
    required this.upcomingVisits,
    required this.technicianProfile,
  });

  final DashboardStats stats;
  final List<JobStatusSlice> jobStatusBreakdown;
  final List<MonthlyStat> monthlyStats;
  final List<RevenueTrendPoint> revenueTrend;
  final QuickOverview quickOverview;
  final List<RecentJob> recentJobs;
  final List<DashboardVisit> todayVisits;
  final List<DashboardVisit> upcomingVisits;
  final TechnicianDashboardProfile? technicianProfile;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      stats: DashboardStats.fromJson(_asMap(json['stats'])),
      jobStatusBreakdown: _asList(
        json['job_status_breakdown'],
      ).map((e) => JobStatusSlice.fromJson(_asMap(e))).toList(),
      monthlyStats: _asList(
        json['monthly_stats'],
      ).map((e) => MonthlyStat.fromJson(_asMap(e))).toList(),
      revenueTrend: _asList(
        json['revenue_trend'],
      ).map((e) => RevenueTrendPoint.fromJson(_asMap(e))).toList(),
      quickOverview: QuickOverview.fromJson(_asMap(json['quick_overview'])),
      recentJobs: _asList(
        json['recent_jobs'],
      ).map((e) => RecentJob.fromJson(_asMap(e))).toList(),
      todayVisits: _asList(
        json['today_visits'],
      ).map((e) => DashboardVisit.fromJson(_asMap(e))).toList(),
      upcomingVisits: _asList(
        json['upcoming_visits'],
      ).map((e) => DashboardVisit.fromJson(_asMap(e))).toList(),
      technicianProfile: json['technician_profile'] == null
          ? null
          : TechnicianDashboardProfile.fromJson(
              _asMap(json['technician_profile']),
            ),
    );
  }
}

class TechnicianDashboardProfile {
  const TechnicianDashboardProfile({
    required this.name,
    required this.avatar,
    required this.specialization,
    required this.rating,
  });

  final String name;
  final String avatar;
  final String specialization;
  final num rating;

  factory TechnicianDashboardProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianDashboardProfile(
      name: (json['name'] ?? '').toString(),
      avatar: (json['avatar'] ?? '').toString(),
      specialization: (json['specialization'] ?? '').toString(),
      rating: _asNum(json['rating']),
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.activeJobs,
    required this.totalClients,
    required this.activeTechnicians,
    required this.totalTechnicians,
    required this.revenueApproved,
    required this.momActiveJobs,
    required this.momClients,
    required this.momRevenue,
    required this.todayVisits,
    required this.weekVisits,
    required this.openJobs,
    required this.closedJobs,
    required this.pendingReports,
    required this.totalRevenue,
  });

  final int activeJobs;
  final int totalClients;
  final int activeTechnicians;
  final int totalTechnicians;
  final num revenueApproved;
  final num momActiveJobs;
  final num momClients;
  final num momRevenue;
  final int todayVisits;
  final int weekVisits;
  final int openJobs;
  final int closedJobs;
  final int pendingReports;
  final num totalRevenue;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeJobs: _asInt(json['active_jobs']),
      totalClients: _asInt(json['total_clients']),
      activeTechnicians: _asInt(json['active_technicians']),
      totalTechnicians: _asInt(json['total_technicians']),
      revenueApproved: _asNum(json['revenue_approved']),
      momActiveJobs: _asNum(json['mom_active_jobs']),
      momClients: _asNum(json['mom_clients']),
      momRevenue: _asNum(json['mom_revenue']),
      todayVisits: _asInt(json['today_visits']),
      weekVisits: _asInt(json['week_visits']),
      openJobs: _asInt(json['open_jobs']),
      closedJobs: _asInt(json['closed_jobs']),
      pendingReports: _asInt(json['pending_reports']),
      totalRevenue: _asNum(json['total_revenue']),
    );
  }
}

class JobStatusSlice {
  const JobStatusSlice({required this.status, required this.count});
  final String status;
  final int count;

  factory JobStatusSlice.fromJson(Map<String, dynamic> json) {
    return JobStatusSlice(
      status: (json['status'] ?? '').toString(),
      count: _asInt(json['count']),
    );
  }
}

class MonthlyStat {
  const MonthlyStat({
    required this.month,
    required this.jobsAssigned,
    required this.jobsRaised,
    required this.jobsCompleted,
    required this.revenue,
  });

  final String month;
  final int jobsAssigned;
  final int jobsRaised;
  final int jobsCompleted;
  final num revenue;

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      month: (json['month'] ?? '').toString(),
      jobsAssigned: _asInt(json['jobs_assigned']),
      jobsRaised: _asInt(json['jobs_raised']),
      jobsCompleted: _asInt(json['jobs_completed']),
      revenue: _asNum(json['revenue']),
    );
  }
}

class RevenueTrendPoint {
  const RevenueTrendPoint({required this.month, required this.revenue});
  final String month;
  final num revenue;

  factory RevenueTrendPoint.fromJson(Map<String, dynamic> json) {
    return RevenueTrendPoint(
      month: (json['month'] ?? '').toString(),
      revenue: _asNum(json['revenue']),
    );
  }
}

class QuickOverview {
  const QuickOverview({
    required this.jobsThisMonth,
    required this.jobsCompleted,
    required this.activeTechnicians,
    required this.amcActive,
  });

  final QuickOverviewItem jobsThisMonth;
  final QuickOverviewItem jobsCompleted;
  final QuickOverviewItem activeTechnicians;
  final QuickOverviewItem amcActive;

  factory QuickOverview.fromJson(Map<String, dynamic> json) {
    return QuickOverview(
      jobsThisMonth: QuickOverviewItem.fromJson(
        _asMap(json['jobs_this_month']),
      ),
      jobsCompleted: QuickOverviewItem.fromJson(_asMap(json['jobs_completed'])),
      activeTechnicians: QuickOverviewItem.fromJson(
        _asMap(json['active_technicians']),
      ),
      amcActive: QuickOverviewItem.fromJson(_asMap(json['amc_active'])),
    );
  }
}

class QuickOverviewItem {
  const QuickOverviewItem({required this.value, required this.target});
  final int value;
  final int target;

  factory QuickOverviewItem.fromJson(Map<String, dynamic> json) {
    return QuickOverviewItem(
      value: _asInt(json['value']),
      target: _asInt(json['target']),
    );
  }
}

class RecentJob {
  const RecentJob({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.amount,
    required this.clientName,
  });

  final String id;
  final String title;
  final String status;
  final String priority;
  final num amount;
  final String? clientName;

  factory RecentJob.fromJson(Map<String, dynamic> json) {
    return RecentJob(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      priority: (json['priority'] ?? '').toString(),
      amount: _asNum(json['amount']),
      clientName: (json['client_name'] as Object?)?.toString(),
    );
  }
}

class DashboardVisit {
  const DashboardVisit({
    required this.id,
    required this.title,
    required this.status,
    required this.clientName,
    required this.siteLocation,
    required this.clientPhone,
    required this.scheduledDate,
  });

  final String id;
  final String title;
  final String status;
  final String? clientName;
  final String? siteLocation;
  final String? clientPhone;
  final String? scheduledDate;

  factory DashboardVisit.fromJson(Map<String, dynamic> json) {
    return DashboardVisit(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      clientName: (json['client_name'] as Object?)?.toString(),
      siteLocation: (json['site_location'] as Object?)?.toString(),
      clientPhone: (json['client_phone'] as Object?)?.toString(),
      scheduledDate: (json['scheduled_date'] as Object?)?.toString(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

num _asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse((value ?? '').toString()) ?? 0;
}

List<dynamic> _asList(Object? value) => value is List ? value : const [];

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return <String, dynamic>{};
}
