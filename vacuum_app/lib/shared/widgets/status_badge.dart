import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = badgeColors[label] ?? (AppColors.gray200, AppColors.gray700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static const badgeColors = <String, (Color, Color)>{
    'Active': (Color(0xFFD1FAE5), Color(0xFF065F46)),
    'Inactive': (Color(0xFFF3F4F6), Color(0xFF6B7280)),
    'On Leave': (Color(0xFFFEF3C7), Color(0xFF92400E)),
    'Raised': (Color(0xFFF3E8FF), Color(0xFF6B21A8)),
    'Assigned': (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
    'In Progress': (Color(0xFFFEF3C7), Color(0xFF92400E)),
    'Closed': (Color(0xFFD1FAE5), Color(0xFF065F46)),
    'Pending': (Color(0xFFFEF3C7), Color(0xFF92400E)),
    'Approved': (Color(0xFFD1FAE5), Color(0xFF065F46)),
    'Rejected': (Color(0xFFFEE2E2), Color(0xFF991B1B)),
    'Expiring Soon': (Color(0xFFFFEDD5), Color(0xFF9A3412)),
    'Critical': (Color(0xFFFEE2E2), Color(0xFF991B1B)),
    'High': (Color(0xFFFFEDD5), Color(0xFF9A3412)),
    'Medium': (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
    'Low': (Color(0xFFF3F4F6), Color(0xFF6B7280)),
    'Present': (Color(0xFFD1FAE5), Color(0xFF065F46)),
    'Absent': (Color(0xFFFEE2E2), Color(0xFF991B1B)),
    'Late': (Color(0xFFFEF3C7), Color(0xFF92400E)),
  };
}
