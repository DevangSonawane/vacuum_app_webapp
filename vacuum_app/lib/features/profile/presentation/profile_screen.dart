import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../auth/application/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    if (user == null) {
      return const EmptyState(
        icon: Icons.person_outline,
        title: 'Profile unavailable',
        description: 'Please sign in again.',
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'My Profile',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              AppButton(
                label: 'Edit Profile',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.sm,
                onPressed: () => context.go('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _LeftCard(user: user)),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _RightCard(user: user)),
              ],
            )
          else ...[
            _LeftCard(user: user),
            const SizedBox(height: 12),
            _RightCard(user: user),
          ],
        ],
      ),
    );
  }
}

class _LeftCard extends StatelessWidget {
  const _LeftCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.blue600,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: AppAvatar(
              initials: initialsFromName(user.fullName),
              size: AppAvatarSize.lg,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (user.role ?? '').toString().toUpperCase(),
            style: const TextStyle(
              color: AppColors.blue600,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Status',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              const Spacer(),
              Row(
                children: const [
                  SizedBox(width: 8),
                  Icon(Icons.circle, size: 10, color: AppColors.emerald500),
                  SizedBox(width: 6),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Member since',
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              const Spacer(),
              const Text('2024', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RightCard extends StatelessWidget {
  const _RightCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 720 ? 2 : 1;
    final items = <({String label, String value, IconData icon})>[
      (
        label: 'Email Address',
        value: (user.email ?? '').toString().isEmpty ? '—' : user.email,
        icon: Icons.mail_outline,
      ),
      (
        label: 'Phone Number',
        value: (user.phoneNumber ?? '').toString().isEmpty
            ? '—'
            : user.phoneNumber,
        icon: Icons.phone_outlined,
      ),
      (
        label: 'Role',
        value: (user.role ?? '—').toString(),
        icon: Icons.shield_outlined,
      ),
      (label: 'Joining Date', value: '—', icon: Icons.calendar_today_outlined),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: cols == 1 ? 4.6 : 4.2,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _InfoItem(
              label: items[i].label,
              value: items[i].value,
              icon: items[i].icon,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1220) : AppColors.gray100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AppColors.blue600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
