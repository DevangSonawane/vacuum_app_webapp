import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/app_settings_notifier.dart';
import '../../../core/ui/ui_providers.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/application/auth_notifier.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _drawerWidth = 256.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    return Scaffold(
      drawer: isDesktop ? null : Drawer(child: _Sidebar(onNavigate: () => Navigator.pop(context))),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _TopBar(showHamburger: !isDesktop),
      ),
      body: Row(
        children: [
          if (isDesktop)
            const SizedBox(
              width: _drawerWidth,
              child: _Sidebar(),
            ),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.showHamburger});

  final bool showHamburger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).valueOrNull;
    final user = auth?.user;
    final isAdmin = user?.role == 'admin';
    final title = _titleForLocation(GoRouterState.of(context).matchedLocation);

    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              if (showHamburger)
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Menu',
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu),
                  ),
                ),
              if (MediaQuery.sizeOf(context).width >= 420) ...[
                const SizedBox(width: 4),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
              const Spacer(),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width < 520 ? 220 : 320),
                child: const _SearchField(),
              ),
              const SizedBox(width: 10),
              _NotificationBell(
                count: 3,
                onTap: () =>
                    AppToast.show(context, message: 'Notifications coming soon…', type: AppToastType.info),
              ),
              const SizedBox(width: 8),
              if (user != null)
                PopupMenuButton<_UserMenuAction>(
                  tooltip: 'Account',
                  onSelected: (action) async {
                    switch (action) {
                      case _UserMenuAction.profile:
                        context.go('/profile');
                      case _UserMenuAction.settings:
                        context.go('/settings');
                      case _UserMenuAction.users:
                        context.go('/users');
                      case _UserMenuAction.toggleDark:
                        await ref.read(appSettingsProvider.notifier).toggleDarkMode();
                      case _UserMenuAction.logout:
                        await ref.read(authProvider.notifier).logout();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Row(
                        children: [
                          AppAvatar(initials: initialsFromName(user.fullName), size: AppAvatarSize.md),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: _UserMenuAction.profile,
                      child: Row(
                        children: [Icon(Icons.person_outline), SizedBox(width: 10), Text('Profile')],
                      ),
                    ),
                    const PopupMenuItem(
                      value: _UserMenuAction.settings,
                      child: Row(
                        children: [Icon(Icons.settings_outlined), SizedBox(width: 10), Text('Settings')],
                      ),
                    ),
                    if (isAdmin)
                      const PopupMenuItem(
                        value: _UserMenuAction.users,
                        child: Row(
                          children: [Icon(Icons.group_outlined), SizedBox(width: 10), Text('User Management')],
                        ),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: _UserMenuAction.toggleDark,
                      child: Row(
                        children: [
                          const Icon(Icons.dark_mode_outlined),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Toggle dark mode')),
                          Switch(
                            value: ref.watch(appSettingsProvider).valueOrNull ?? false,
                            onChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: _UserMenuAction.logout,
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.red500),
                          SizedBox(width: 10),
                          Text('Sign Out', style: TextStyle(color: AppColors.red500)),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    children: [
                      AppAvatar(initials: initialsFromName(user.fullName), size: AppAvatarSize.md),
                      const SizedBox(width: 10),
                      if (MediaQuery.sizeOf(context).width >= 620)
                        Text(user.firstName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      const Icon(Icons.expand_more),
                    ],
                  ),
                )
              else
                AppButton(
                  label: 'Sign out',
                  variant: AppButtonVariant.danger,
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForLocation(String location) {
    return switch (location) {
      '/' => 'Dashboard',
      '/technicians' => 'Technicians',
      '/clients' => 'Clients',
      '/jobs' => 'Work Orders',
      '/reports' => 'Service Reports',
      '/quotations' => 'Quotations',
      '/amc' => 'AMC Contracts',
      '/attendance' => 'Attendance',
      '/email' => 'Email Settings',
      '/activity' => 'Activity History',
      '/users' => 'Users',
      '/profile' => 'Profile',
      '/settings' => 'Settings',
      _ => 'VDTI Service Hub',
    };
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: onTap,
          icon: const Icon(Icons.notifications_none),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red500,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}

enum _UserMenuAction { profile, settings, users, toggleDark, logout }

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchQueryProvider, (_, next) {
      if (_controller.text != next) _controller.text = next;
    });

    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        hintText: 'Search…',
        prefixIcon: Icon(Icons.search),
        isDense: true,
      ),
      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({this.onNavigate});

  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).valueOrNull;
    final role = auth?.user?.role;

    final location = GoRouterState.of(context).matchedLocation;
    final items = _navItems.where((i) => !i.adminOnly || role == 'admin').toList();

    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        children: [
          _LogoBlock(onTap: () => context.go('/')),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: [
                for (final item in items)
                  _NavItem(
                    label: item.label,
                    icon: item.icon,
                    active: location == item.route,
                    onTap: () {
                      context.go(item.route);
                      onNavigate?.call();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Sign Out',
            variant: AppButtonVariant.danger,
            expanded: true,
            leading: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              onNavigate?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _LogoBlock extends StatelessWidget {
  const _LogoBlock({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.blue600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.construction, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VDTI',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Service Hub',
                    style: TextStyle(
                      color: AppColors.blue400,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.blue600 : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? Colors.white : AppColors.blue200, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.blue200,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (active) const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDescriptor {
  const _NavDescriptor({
    required this.label,
    required this.route,
    required this.icon,
    required this.adminOnly,
  });

  final String label;
  final String route;
  final IconData icon;
  final bool adminOnly;
}

const _navItems = <_NavDescriptor>[
  _NavDescriptor(label: 'Dashboard', route: '/', icon: Icons.dashboard_outlined, adminOnly: false),
  _NavDescriptor(label: 'Technicians', route: '/technicians', icon: Icons.engineering_outlined, adminOnly: false),
  _NavDescriptor(label: 'Clients', route: '/clients', icon: Icons.groups_outlined, adminOnly: false),
  _NavDescriptor(label: 'Work Orders', route: '/jobs', icon: Icons.work_outline, adminOnly: false),
  _NavDescriptor(label: 'Service Reports', route: '/reports', icon: Icons.assignment_outlined, adminOnly: false),
  _NavDescriptor(label: 'Quotations', route: '/quotations', icon: Icons.request_quote_outlined, adminOnly: false),
  _NavDescriptor(label: 'AMC Contracts', route: '/amc', icon: Icons.verified_user_outlined, adminOnly: false),
  _NavDescriptor(label: 'Attendance', route: '/attendance', icon: Icons.access_time, adminOnly: false),
  _NavDescriptor(label: 'Email Settings', route: '/email', icon: Icons.mail_outline, adminOnly: true),
  _NavDescriptor(label: 'Activity History', route: '/activity', icon: Icons.description_outlined, adminOnly: false),
  _NavDescriptor(label: 'Users', route: '/users', icon: Icons.manage_accounts_outlined, adminOnly: true),
];
