import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/revenue.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../application/dashboard_notifier.dart';
import '../domain/dashboard_data.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    return dashboard.when(
      loading: () => const _DashboardSkeleton(),
      error: (error, _) => _DashboardError(message: error.toString()),
      data: (data) => _DashboardBody(data: data),
    );
  }
}

class _DashboardError extends ConsumerWidget {
  const _DashboardError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor)),
            const SizedBox(height: 12),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.outline,
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1024 ? 4 : 2;
    final stats = data.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Dashboard',
            subtitle: "Welcome back — here's what's happening today.",
            action: IconButton(
              tooltip: 'Refresh',
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width < 520 ? 1.6 : 1.9,
            children: [
              StatCard(
                title: 'Active Jobs',
                value: stats.activeJobs.toString(),
                icon: Icons.work_outline,
                gradient: StatCard.blue,
                changePercent: stats.momActiveJobs,
              ),
              StatCard(
                title: 'Total Clients',
                value: stats.totalClients.toString(),
                icon: Icons.groups_outlined,
                gradient: StatCard.emerald,
                changePercent: stats.momClients,
              ),
              StatCard(
                title: 'Technicians',
                value: stats.activeTechnicians.toString(),
                icon: Icons.engineering_outlined,
                gradient: StatCard.purple,
                subtitle: '${stats.totalTechnicians} total',
              ),
              StatCard(
                title: 'Revenue (Approved)',
                value: fmtRevenue(stats.revenueApproved),
                icon: Icons.currency_rupee,
                gradient: StatCard.amber,
                changePercent: stats.momRevenue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _JobsAndRevenueCard(items: data.monthlyStats),
          const SizedBox(height: 16),
          _JobStatusCard(items: data.jobStatusBreakdown),
          const SizedBox(height: 16),
          _RevenueTrendCard(items: data.revenueTrend),
          const SizedBox(height: 16),
          _QuickOverviewCard(items: data.quickOverview),
          const SizedBox(height: 16),
          _RecentJobsCard(
            items: data.recentJobs,
            onViewAll: () => context.go('/jobs'),
            onJobTap: (id) => context.go('/jobs/$id'),
          ),
        ],
      ),
    );
  }
}

class _JobsAndRevenueCard extends StatelessWidget {
  const _JobsAndRevenueCard({required this.items});
  final List<MonthlyStat> items;

  @override
  Widget build(BuildContext context) {
    final maxY = items.isEmpty
        ? 1.0
        : (items.map((e) => e.jobsRaised > e.jobsCompleted ? e.jobsRaised : e.jobsCompleted).reduce(
                (a, b) => a > b ? a : b,
              ) +
            2).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jobs & Revenue', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Last 6 months',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.trending_up, color: AppColors.blue600, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= items.length) return const SizedBox.shrink();
                        final month = items[i].month.replaceAll(' 20', " '");
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(month, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < items.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: items[i].jobsRaised.toDouble(),
                          width: 10,
                          color: const Color(0xFFBFDBFE),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: items[i].jobsCompleted.toDouble(),
                          width: 10,
                          color: AppColors.blue600,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobStatusCard extends StatelessWidget {
  const _JobStatusCard({required this.items});
  final List<JobStatusSlice> items;

  Color _colorFor(String status) {
    return switch (status) {
      'Raised' => AppColors.purple500,
      'Assigned' => AppColors.blue500,
      'In Progress' => AppColors.amber500,
      'Closed' => AppColors.emerald500,
      _ => AppColors.gray400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (p, e) => p + e.count);
    final sections = items
        .where((e) => e.count > 0)
        .map(
          (e) => PieChartSectionData(
            value: e.count.toDouble(),
            color: _colorFor(e.status),
            radius: 40,
            showTitle: false,
          ),
        )
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Job Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 50,
                        sectionsSpace: 2,
                        sections: sections.isEmpty
                            ? [
                                PieChartSectionData(
                                  value: 1,
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
                                  radius: 40,
                                  showTitle: false,
                                )
                              ]
                            : sections,
                      ),
                    ),
                    Text(
                      total.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (final s in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colorFor(s.status),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.status,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              s.count.toString(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard({required this.items});
  final List<RevenueTrendPoint> items;

  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[
      for (int i = 0; i < items.length; i++) FlSpot(i.toDouble(), items[i].revenue.toDouble()),
    ];

    final maxY = items.isEmpty
        ? 1.0
        : (items.map((e) => e.revenue).reduce((a, b) => a > b ? a : b) * 1.15).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Trend', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, meta) => Text(
                        '₹${(v / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= items.length) return const SizedBox.shrink();
                        final month = items[i].month.replaceAll(' 20', " '");
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(month, style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: AppColors.blue600,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickOverviewCard extends StatelessWidget {
  const _QuickOverviewCard({required this.items});
  final QuickOverview items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Overview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Jobs This Month',
            item: items.jobsThisMonth,
            color: AppColors.blue600,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Jobs Completed',
            item: items.jobsCompleted,
            color: AppColors.emerald500,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'Active Technicians',
            item: items.activeTechnicians,
            color: AppColors.purple500,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'AMC Active',
            item: items.amcActive,
            color: AppColors.amber500,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.item, required this.color});

  final String label;
  final QuickOverviewItem item;
  final Color color;

  int _pct(int v, int t) => t <= 0 ? 0 : ((v / t) * 100).round().clamp(0, 100);

  @override
  Widget build(BuildContext context) {
    final pct = _pct(item.value, item.target);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${item.value}/${item.target}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: t,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentJobsCard extends StatelessWidget {
  const _RecentJobsCard({required this.items, required this.onViewAll, required this.onJobTap});

  final List<RecentJob> items;
  final VoidCallback onViewAll;
  final ValueChanged<String> onJobTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Recent Work Orders', style: Theme.of(context).textTheme.titleMedium)),
              TextButton.icon(
                onPressed: onViewAll,
                icon: const Text('View all', style: TextStyle(fontSize: 12)),
                label: const Icon(Icons.chevron_right, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No recent jobs', style: TextStyle(color: Theme.of(context).hintColor))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 42,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 56,
                columns: const [
                  DataColumn(label: Text('Job ID')),
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Priority')),
                  DataColumn(label: Text('Amount')),
                ],
                rows: [
                  for (final job in items)
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            job.id,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              color: AppColors.blue600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              job.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        DataCell(Text(job.clientName?.isNotEmpty == true ? job.clientName! : '—')),
                        DataCell(StatusBadge(label: job.status)),
                        DataCell(StatusBadge(label: job.priority)),
                        DataCell(Text('₹${job.amount.toStringAsFixed(0)}')),
                      ],
                      onSelectChanged: (_) => onJobTap(job.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1024 ? 4 : 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 220, height: 24, borderRadius: 10),
          const SizedBox(height: 6),
          const ShimmerBox(width: 320, height: 14, borderRadius: 8),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width < 520 ? 1.6 : 1.9,
            children: const [
              AppCard(child: ShimmerBox(height: 92)),
              AppCard(child: ShimmerBox(height: 92)),
              AppCard(child: ShimmerBox(height: 92)),
              AppCard(child: ShimmerBox(height: 92)),
            ],
          ),
          const SizedBox(height: 16),
          const AppCard(child: ShimmerBox(height: 220)),
          const SizedBox(height: 16),
          const AppCard(child: ShimmerBox(height: 220)),
          const SizedBox(height: 16),
          const AppCard(child: ShimmerBox(height: 180)),
          const SizedBox(height: 16),
          const AppCard(child: ShimmerBox(height: 200)),
          const SizedBox(height: 16),
          const AppCard(child: ShimmerBox(height: 220)),
        ],
      ),
    );
  }
}
