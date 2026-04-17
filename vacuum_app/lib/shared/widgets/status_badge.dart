import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.$2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color) _colorsFor(String value) {
    switch (value) {
      case 'Active':
      case 'Closed':
      case 'Approved':
      case 'Present':
        return (AppColors.emerald500.withValues(alpha: 0.15), AppColors.emerald500);
      case 'Inactive':
      case 'Low':
        return (AppColors.gray200, AppColors.gray700);
      case 'On Leave':
      case 'In Progress':
      case 'Pending':
      case 'Late':
        return (AppColors.amber500.withValues(alpha: 0.15), AppColors.amber500);
      case 'Raised':
      case 'Medium':
        return (AppColors.purple500.withValues(alpha: 0.15), AppColors.purple500);
      case 'Assigned':
      case 'High':
        return (AppColors.blue600.withValues(alpha: 0.15), AppColors.blue600);
      case 'Rejected':
      case 'Critical':
      case 'Absent':
        return (AppColors.red500.withValues(alpha: 0.15), AppColors.red500);
      case 'Expiring Soon':
        return (AppColors.orange500.withValues(alpha: 0.15), AppColors.orange500);
      default:
        return (AppColors.gray200, AppColors.gray700);
    }
  }
}
