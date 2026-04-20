import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_settings_notifier.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/user.dart';

class AccountMenu {
  const AccountMenu._();

  static Future<void> open(
    BuildContext context, {
    required User user,
    required bool isAdmin,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      builder: (ctx) => _AccountMenuOverlay(user: user, isAdmin: isAdmin),
    );
  }
}

class _AccountMenuOverlay extends StatelessWidget {
  const _AccountMenuOverlay({required this.user, required this.isAdmin});

  final User user;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final menuWidth = math.min(320.0, width - 24);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 62, right: 12),
          child: GestureDetector(
            onTap: () {}, // absorb
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 10),
                  child: Transform.scale(
                    scale: 0.95 + (0.05 * t),
                    alignment: Alignment.topRight,
                    child: child,
                  ),
                ),
              ),
              child: _AccountMenuCard(
                user: user,
                isAdmin: isAdmin,
                width: menuWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountMenuCard extends ConsumerWidget {
  const _AccountMenuCard({
    required this.user,
    required this.isAdmin,
    required this.width,
  });

  final User user;
  final bool isAdmin;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final border = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final hint = Theme.of(context).hintColor;
    final darkMode = ref.watch(appSettingsProvider).valueOrNull ?? false;

    return Material(
      color: scheme.surface,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints.tightFor(width: width),
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border.all(color: border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  children: [
                    AppAvatar(
                      initials: initialsFromName(user.fullName),
                      size: AppAvatarSize.md,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hint,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _RolePill(role: user.role),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.person_outline,
                      label: 'Profile',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/profile');
                      },
                    ),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/settings');
                      },
                    ),
                    if (isAdmin)
                      _MenuTile(
                        icon: Icons.group_outlined,
                        label: 'User Management',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/users');
                        },
                      ),
                    const SizedBox(height: 4),
                    Divider(height: 1, color: border),
                    const SizedBox(height: 4),
                    _MenuTile(
                      icon: darkMode
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: darkMode ? 'Light Mode' : 'Dark Mode',
                      trailing: Switch.adaptive(
                        value: darkMode,
                        onChanged: (_) => ref
                            .read(appSettingsProvider.notifier)
                            .toggleDarkMode(),
                      ),
                      onTap: () => ref
                          .read(appSettingsProvider.notifier)
                          .toggleDarkMode(),
                    ),
                    const SizedBox(height: 4),
                    Divider(height: 1, color: border),
                    const SizedBox(height: 4),
                    _MenuTile(
                      icon: Icons.logout,
                      iconColor: AppColors.red500,
                      label: 'Sign Out',
                      labelColor: AppColors.red500,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    final fg = Theme.of(context).hintColor;
    final label = role.isEmpty
        ? 'User'
        : role[0].toUpperCase() + role.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hover = Theme.of(context).brightness == Brightness.dark
        ? AppColors.blue600.withValues(alpha: 0.16)
        : const Color(0xFFDBEAFE);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        hoverColor: hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: iconColor ?? Theme.of(context).iconTheme.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
