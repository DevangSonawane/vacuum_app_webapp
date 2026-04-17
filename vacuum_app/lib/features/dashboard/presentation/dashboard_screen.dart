import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1200 ? 4 : (width >= 820 ? 2 : 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Dashboard',
            subtitle: 'Overview of service operations',
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: const [
              _StatCard(title: 'Total Jobs', value: '40', icon: Icons.work_outline, color: AppColors.blue600),
              _StatCard(
                title: 'Completed',
                value: '22',
                icon: Icons.check_circle_outline,
                color: AppColors.emerald500,
              ),
              _StatCard(title: 'Pending Reports', value: '7', icon: Icons.assignment_outlined, color: AppColors.amber500),
              _StatCard(title: 'Revenue', value: '₹ 3.2L', icon: Icons.currency_rupee, color: AppColors.purple500),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              StatusBadge(label: 'Raised'),
              SizedBox(width: 8),
              StatusBadge(label: 'Assigned'),
              SizedBox(width: 8),
              StatusBadge(label: 'In Progress'),
              SizedBox(width: 8),
              StatusBadge(label: 'Closed'),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent Work Orders', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                ..._rows(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rows(BuildContext context) {
    final rows = const [
      ('JOB-001', 'Routine inspection', 'Closed', '₹ 12,000'),
      ('JOB-002', 'Generator repair', 'In Progress', '₹ 18,500'),
      ('JOB-003', 'Dryer installation', 'Assigned', '₹ 42,000'),
      ('JOB-004', 'AMC visit', 'Raised', '₹ 9,000'),
      ('JOB-005', 'Leak check', 'Closed', '₹ 4,500'),
    ];

    return [
      for (final row in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  row.$1,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue600,
                  ),
                ),
              ),
              Expanded(
                child: Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              StatusBadge(label: row.$3),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: Text(row.$4, textAlign: TextAlign.right)),
            ],
          ),
        ),
      Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
    ]..removeLast();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hover: true,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
