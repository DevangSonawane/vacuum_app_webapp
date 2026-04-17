import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class BrandingPanel extends StatelessWidget {
  const BrandingPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });

  final String title;
  final String subtitle;
  final List<(IconData icon, String title, String description)> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.construction, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VDTI Service Hub',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.blue400, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, height: 1.05),
          ),
          const SizedBox(height: 12),
          Text(
            'Internal CRM & field operations dashboard for Vacuum Drying Technology India LLP.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          for (final bullet in bullets) ...[
            _Bullet(icon: bullet.$1, title: bullet.$2, description: bullet.$3),
            const SizedBox(height: 14),
          ],
          const Spacer(),
          Text(
            '© 2024 Vacuum Drying Technology India LLP.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.blue400, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
