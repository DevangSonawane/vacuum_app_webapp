import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/ui/ui_providers.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/application/auth_notifier.dart';
import '../../clients/application/clients_notifier.dart';
import '../../amc/application/amc_notifier.dart';
import '../../erp/application/erp_quotations_notifier.dart';
import '../../jobs/application/jobs_notifier.dart';
import '../../reports/application/reports_notifier.dart';
import '../../technicians/application/technicians_notifier.dart';
import '../../users/application/users_notifier.dart';
import '../../notifications/application/notifications_notifier.dart';
import '../../notifications/presentation/notifications_menu.dart';
import 'account_menu.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _drawerWidth = 256.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1024;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppColors.sidebar,
              child: SafeArea(
                child: _Sidebar(onNavigate: () => Navigator.pop(context)),
              ),
            ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _TopBar(showHamburger: !isDesktop),
      ),
      body: Row(
        children: [
          if (isDesktop)
            const SizedBox(
              width: _drawerWidth,
              child: SafeArea(child: _Sidebar()),
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
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleForLocation(location);
    final width = MediaQuery.sizeOf(context).width;
    final showSearch = !_hideSearchForLocation(location);

    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xCC030712)
        : const Color(0xCCFFFFFF);
    final border = Theme.of(context).dividerColor.withValues(alpha: 0.12);

    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Material(
          color: bg,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: border)),
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
                    if (width >= 420) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        fit: FlexFit.loose,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'VDTI Service Hub',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    if (showSearch)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const _SearchField(),
                        ),
                      ),
                    if (!showSearch) const Spacer(),
                    const _NotificationBell(),
                    const SizedBox(width: 4),
                    Container(
                      width: 1,
                      height: 24,
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                    ),
                    const SizedBox(width: 4),
                    if (user != null)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => AccountMenu.open(
                          context,
                          user: user,
                          isAdmin: isAdmin,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              AppAvatar(
                                initials: initialsFromName(user.fullName),
                                size: AppAvatarSize.sm,
                              ),
                              const SizedBox(width: 8),
                              if (width >= 620)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 140,
                                  ),
                                  child: Text(
                                    user.firstName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      AppButton(
                        label: 'Sign out',
                        variant: AppButtonVariant.danger,
                        onPressed: () =>
                            ref.read(authProvider.notifier).logout(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hideSearchForLocation(String location) {
    return location.startsWith('/technicians') ||
        location.startsWith('/clients') ||
        location.startsWith('/jobs') ||
        location.startsWith('/reports') ||
        location.startsWith('/amc');
  }

  String _titleForLocation(String location) {
    if (location == '/') return 'Dashboard';
    if (location == '/technicians/new') return 'Add Technician';
    if (location.startsWith('/technicians')) return 'Technicians';
    if (location == '/clients/new') return 'Add Client';
    if (location.startsWith('/clients')) return 'Clients';
    if (location == '/jobs/new') return 'Raise Work Order';
    if (location.startsWith('/jobs')) return 'Visit Scheduled';
    if (location == '/reports/new') return 'New Report';
    if (location.startsWith('/reports')) return 'Service Reports';
    if (location.startsWith('/quotations')) return 'Quotations';
    if (location == '/amc/new') return 'Add Contract';
    if (location.startsWith('/amc')) return 'AMC Contracts';
    if (location == '/attendance') return 'Employees';
    if (location.startsWith('/attendance')) return 'Attendance';
    if (location.startsWith('/email')) return 'Email Settings';
    if (location.startsWith('/activity')) return 'Activity History';
    if (location.startsWith('/users')) return 'Users';
    if (location.startsWith('/profile')) return 'Profile';
    if (location.startsWith('/settings')) return 'Settings';
    return 'VDTI Service Hub';
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final s = ref.watch(notificationsProvider).valueOrNull;
        final count = s?.unreadCount ?? 0;
        final connected = s?.connected ?? false;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => NotificationsMenu.open(context),
              iconSize: 20,
              icon: const Icon(Icons.notifications_none),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? AppColors.emerald500 : AppColors.gray400,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.red500,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(searchQueryProvider),
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchQueryProvider, (_, next) {
      if (_controller.text != next) _controller.text = next;
    });

    final location = GoRouterState.of(context).matchedLocation;

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: _hintForLocation(location),
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111827)
            : AppColors.gray50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.blue600),
        ),
      ),
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          _dispatchSearch(context, ref, location, value.trim());
        });
      },
    );
  }

  String _hintForLocation(String location) {
    if (location.startsWith('/users')) return 'Search users…';
    if (location.startsWith('/technicians')) return 'Search technicians…';
    if (location.startsWith('/clients')) return 'Search clients…';
    if (location.startsWith('/jobs')) return 'Search work orders…';
    if (location.startsWith('/reports')) return 'Search reports…';
    if (location.startsWith('/activity')) return 'Search activity…';
    if (location.startsWith('/quotations')) return 'Search quotations…';
    return 'Search…';
  }

  void _dispatchSearch(
    BuildContext context,
    WidgetRef ref,
    String location,
    String query,
  ) {
    if (location.startsWith('/users')) {
      ref.read(usersProvider.notifier).search(query);
      return;
    }

    if (location.startsWith('/technicians')) {
      ref.read(techniciansProvider.notifier).search(query);
      return;
    }

    if (location.startsWith('/clients')) {
      ref.read(clientsProvider.notifier).filter(search: query);
      return;
    }

    if (location.startsWith('/amc')) {
      ref.read(amcProvider.notifier).search(query);
      return;
    }

    if (location.startsWith('/quotations')) {
      ref
          .read(erpQuotationsProvider.notifier)
          .applyFilters(search: query, page: 1);
      return;
    }

    if (location.startsWith('/jobs')) {
      ref.read(jobsProvider.notifier).search(query);
      return;
    }

    if (location.startsWith('/reports')) {
      ref.read(reportsProvider.notifier).search(query);
      return;
    }

    if (location.startsWith('/activity')) {
      ref.read(searchQueryProvider.notifier).state = query;
      return;
    }

    // Leave the keyboard open on pages without a routed search implementation.
    // Those screens can still use the shared search text as a source of truth
    // without forcing focus away after every character.
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({this.onNavigate});

  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider).valueOrNull;
    final role = auth?.user?.role.toLowerCase();

    final location = GoRouterState.of(context).matchedLocation;
    final items = _navItems
        .where((i) => !i.adminOnly || role == 'admin')
        .where((i) => !i.hideForRoles.contains(role))
        .toList();

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
              await Future<void>.delayed(Duration.zero);
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
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/branding/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VDTI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.blue600 : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.blue600.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: active ? Colors.white : AppColors.blue200,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
    this.hideForRoles = const [],
  });

  final String label;
  final String route;
  final IconData icon;
  final bool adminOnly;
  final List<String> hideForRoles;
}

const _navItems = <_NavDescriptor>[
  _NavDescriptor(
    label: 'Dashboard',
    route: '/',
    icon: Icons.dashboard_outlined,
    adminOnly: false,
  ),
  _NavDescriptor(
    label: 'Technicians',
    route: '/technicians',
    icon: Icons.engineering_outlined,
    adminOnly: false,
    hideForRoles: ['technician', 'engineer', 'labour'],
  ),
  _NavDescriptor(
    label: 'Clients',
    route: '/clients',
    icon: Icons.groups_outlined,
    adminOnly: false,
    hideForRoles: ['technician', 'engineer', 'labour'],
  ),
  _NavDescriptor(
    label: 'Visit Scheduled',
    route: '/jobs',
    icon: Icons.work_outline,
    adminOnly: false,
  ),
  _NavDescriptor(
    label: 'Service Reports',
    route: '/reports',
    icon: Icons.assignment_outlined,
    adminOnly: false,
  ),
  _NavDescriptor(
    label: 'AMC Contracts',
    route: '/amc',
    icon: Icons.verified_user_outlined,
    adminOnly: false,
    hideForRoles: ['technician', 'engineer', 'labour'],
  ),
  _NavDescriptor(
    label: 'Quotations',
    route: '/quotations',
    icon: Icons.request_quote_outlined,
    adminOnly: true,
  ),
  _NavDescriptor(
    label: 'Attendance',
    route: '/attendance',
    icon: Icons.access_time,
    adminOnly: false,
    hideForRoles: ['technician', 'engineer', 'labour'],
  ),
  _NavDescriptor(
    label: 'Email Settings',
    route: '/email',
    icon: Icons.mail_outline,
    adminOnly: true,
  ),
  _NavDescriptor(
    label: 'Activity History',
    route: '/activity',
    icon: Icons.description_outlined,
    adminOnly: true,
  ),
  _NavDescriptor(
    label: 'Users',
    route: '/users',
    icon: Icons.manage_accounts_outlined,
    adminOnly: true,
  ),
];
