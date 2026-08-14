import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_notifier.dart';
import '../../notifications/application/notifications_notifier.dart';
import '../../notifications/domain/app_notification.dart';
import '../application/activity_notifier.dart';
import '../domain/activity_item.dart';

const _filters = [
  'All',
  'job',
  'client',
  'report',
  'technician',
  'amc',
  'user',
];

final activitySearchProvider = StateProvider<String>((_) => '');
final activityTabProvider = StateProvider<int>((_) => 0);
final _activityLoadingMoreProvider = StateProvider<bool>((_) => false);
final _notifFilterProvider = StateProvider<String>(
  (_) => 'all',
); // all | unread

final _activityTsFmt = DateFormat.yMMMd('en_IN').add_jm();

String _filterLabel(String value) {
  return switch (value) {
    'All' => 'All',
    'job' => 'Job',
    'client' => 'Client',
    'report' => 'Report',
    'technician' => 'Technician',
    'amc' => 'Amc',
    'user' => 'User',
    _ => '',
  };
}

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final isAdmin = role == 'admin';
    if (!isAdmin) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Admin only',
        description: 'You do not have access to Activity History.',
      );
    }

    final tab = ref.watch(activityTabProvider);
    final notif = ref.watch(notificationsProvider).valueOrNull;
    final notifUnread = notif?.unreadCount ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Activity History',
            action: IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                if (tab == 0) {
                  ref.read(activityProvider.notifier).refresh();
                } else {
                  ref.read(notificationsProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 12),
          _TabsRow(
            index: tab,
            unreadCount: notifUnread,
            connected: notif?.connected ?? false,
            onChanged: (i) => ref.read(activityTabProvider.notifier).state = i,
          ),
          const SizedBox(height: 12),
          if (tab == 0) const _ActivityLogTab() else const _NotificationsTab(),
        ],
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  const _TabsRow({
    required this.index,
    required this.unreadCount,
    required this.connected,
    required this.onChanged,
  });

  final int index;
  final int unreadCount;
  final bool connected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget tab({required int i, required String label, Widget? trailing}) {
      final active = index == i;
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active
                ? (isDark ? AppColors.gray800 : const Color(0xFFDBEAFE))
                : Colors.transparent,
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: active
                      ? (isDark ? Colors.white : AppColors.blue600)
                      : Theme.of(context).hintColor,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing],
            ],
          ),
        ),
      );
    }

    final wsColor = connected ? AppColors.emerald500 : AppColors.gray400;
    final wsLabel = connected ? 'Live' : 'Offline';
    return Row(
      children: [
        tab(i: 0, label: 'Activity Log'),
        const SizedBox(width: 10),
        tab(
          i: 1,
          label: 'Notifications',
          trailing: Row(
            children: [
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: wsColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: wsColor.withValues(alpha: 0.22)),
                ),
                child: Text(
                  wsLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: wsColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityLogTab extends ConsumerWidget {
  const _ActivityLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityProvider);
    return state.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load',
        description: friendlyErrorMessage(e),
      ),
      data: (data) {
        final q = ref.watch(activitySearchProvider).trim().toLowerCase();
        final filtered = q.length >= 2
            ? data.items.where((it) {
                final action = it.action.toLowerCase();
                final by = it.user.toLowerCase();
                final entity = (it.entityId ?? '').toLowerCase();
                return action.contains(q) ||
                    by.contains(q) ||
                    entity.contains(q);
              }).toList()
            : data.items;

        final showingText =
            'Showing ${data.items.length} of ${data.total} activities';
        final canLoadMore = data.page < data.totalPages;
        final loadingMore = ref.watch(_activityLoadingMoreProvider);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity history',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track actions, entity changes, and admin events in one stream.',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryPill(
                  label: 'Loaded',
                  value: data.items.length,
                  color: AppColors.blue600,
                ),
                _SummaryPill(
                  label: 'Total',
                  value: data.total,
                  color: AppColors.emerald500,
                ),
                _SummaryPill(
                  label: 'Page',
                  value: data.page,
                  color: AppColors.purple500,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ActivityFiltersRow(
              active: data.typeFilter,
              onChanged: (f) =>
                  ref.read(activityProvider.notifier).setFilter(f),
            ),
            const SizedBox(height: 12),
            _ActivitySearchField(
              value: ref.watch(activitySearchProvider),
              onChanged: (v) =>
                  ref.read(activitySearchProvider.notifier).state = v,
              onClear: () =>
                  ref.read(activitySearchProvider.notifier).state = '',
            ),
            const SizedBox(height: 10),
            Text(
              showingText,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
            const SizedBox(height: 12),
            if (data.items.isEmpty && q.isEmpty)
              const EmptyState(
                icon: Icons.history,
                title: 'No activity yet',
                description: 'Actions will show up here.',
              )
            else if (filtered.isEmpty)
              const EmptyState(
                icon: Icons.history,
                title: 'No activity found',
                description: 'No activity logs match your current filter.',
              )
            else ...[
              AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.12),
                    height: 1,
                  ),
                  itemBuilder: (context, i) => _ActivityRow(
                    item: filtered[i],
                    onTap: () => _onActivityTap(context, filtered[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (canLoadMore)
                AppButton(
                  label: loadingMore ? 'Loading…' : 'Load More',
                  variant: AppButtonVariant.secondary,
                  onPressed: loadingMore
                      ? null
                      : () async {
                          ref
                                  .read(_activityLoadingMoreProvider.notifier)
                                  .state =
                              true;
                          await ref.read(activityProvider.notifier).loadMore();
                          if (context.mounted) {
                            ref
                                    .read(_activityLoadingMoreProvider.notifier)
                                    .state =
                                false;
                          }
                        },
                ),
            ],
          ],
        );
      },
    );
  }

  void _onActivityTap(BuildContext context, ActivityItem item) {
    final id = item.entityId;
    if (id == null || id.isEmpty) return;
    final type = item.entityType ?? item.type;

    if (type == 'job') {
      context.go('/jobs/$id');
      return;
    }
    if (type == 'report') {
      context.go('/reports/$id');
      return;
    }

    AppToast.show(
      context,
      message: 'Navigation for $type not wired yet.',
      type: AppToastType.info,
    );
  }
}

class _NotificationsTab extends ConsumerWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final filter = ref.watch(_notifFilterProvider);

    return state.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Failed to load',
        description: friendlyErrorMessage(e),
      ),
      data: (data) {
        final unreadCount = data.unreadCount;
        final items = filter == 'unread'
            ? data.items.where((n) => !n.read).toList()
            : data.items;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      data.connected
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.connected
                              ? 'Live notifications from jobs, reports, and AMC updates.'
                              : 'Currently offline, but your unread queue is still preserved.',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryPill(
                  label: 'Unread',
                  value: unreadCount,
                  color: AppColors.blue600,
                ),
                _SummaryPill(
                  label: 'Total',
                  value: data.items.length,
                  color: AppColors.emerald500,
                ),
                _TextPill(
                  label: 'Connection',
                  value: data.connected ? 'Live' : 'Offline',
                  color: data.connected
                      ? AppColors.emerald500
                      : AppColors.gray400,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(
                  context,
                  label: 'All',
                  active: filter == 'all',
                  onTap: () =>
                      ref.read(_notifFilterProvider.notifier).state = 'all',
                ),
                const SizedBox(width: 10),
                _chip(
                  context,
                  label: unreadCount > 0 ? 'Unread ($unreadCount)' : 'Unread',
                  active: filter == 'unread',
                  onTap: () =>
                      ref.read(_notifFilterProvider.notifier).state = 'unread',
                ),
                const Spacer(),
                AppButton(
                  label: 'Mark all read',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.secondary,
                  onPressed: unreadCount == 0
                      ? null
                      : () => ref
                            .read(notificationsProvider.notifier)
                            .markAllRead(),
                ),
                const SizedBox(width: 10),
                AppButton(
                  label: 'Clear all',
                  size: AppButtonSize.sm,
                  variant: AppButtonVariant.danger,
                  onPressed: data.items.isEmpty
                      ? null
                      : () =>
                            ref.read(notificationsProvider.notifier).clearAll(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications',
                description: 'You are all caught up.',
              )
            else
              AppCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, i) => Divider(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.12),
                    height: 1,
                  ),
                  itemBuilder: (context, i) => _NotificationRow(
                    item: items[i],
                    onTap: () => _onNotificationTap(context, ref, items[i]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static Widget _chip(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active
              ? (isDark ? AppColors.gray800 : const Color(0xFFDBEAFE))
              : Colors.transparent,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: active
                ? (isDark ? Colors.white : AppColors.blue600)
                : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification n,
  ) {
    ref.read(notificationsProvider.notifier).markRead(n);

    final id = n.entityId;
    final type = n.entityType;
    if (id == null || id.isEmpty || type == null || type.isEmpty) return;

    if (type == 'job') {
      context.go('/jobs/$id');
      return;
    }
    if (type == 'report') {
      context.go('/reports/$id');
      return;
    }
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = notificationMeta(item.event);
    final tsText = relativeTime(item.timestamp.toIso8601String());
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(meta.icon, color: meta.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (!item.read) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.blue600,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        tsText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TypePill(
                        label: item.event.replaceAll('_', ' '),
                        color: meta.color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TextPill extends StatelessWidget {
  const _TextPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.onTap});

  final ActivityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = item.entityType ?? item.type;
    final (icon, bg, fg) = _typeStyle(type);
    final typeLabel = _filterLabel(type);
    final hasEntity = (item.entityId ?? '').isNotEmpty;
    final clickable = hasEntity && (type == 'job' || type == 'report');
    final userName = item.user.trim();
    final tsText = _formatTime(item.timestamp) ?? relativeTime(item.timestamp);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: clickable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: fg, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.action,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (userName.isNotEmpty) ...[
                        Expanded(
                          child: Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.blue600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '·',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray400,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else
                        const Spacer(),
                      Text(
                        tsText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (typeLabel.isNotEmpty) ...[
              const SizedBox(width: 10),
              _TypePill(label: typeLabel, color: fg),
            ],
            if (clickable) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.gray400),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, Color) _typeStyle(String type) {
    return switch (type) {
      'job' => (Icons.work_outline, const Color(0xFFDBEAFE), AppColors.blue600),
      'client' => (
        Icons.groups_outlined,
        const Color(0xFFD1FAE5),
        AppColors.emerald500,
      ),
      'amc' => (
        Icons.verified_user_outlined,
        const Color(0xFFF3E8FF),
        AppColors.purple500,
      ),
      'report' => (
        Icons.description_outlined,
        const Color(0xFFF3F4F6),
        AppColors.gray500,
      ),
      'technician' => (
        Icons.engineering_outlined,
        const Color(0xFFFEE2E2),
        AppColors.red500,
      ),
      'user' => (
        Icons.person_outline,
        const Color(0xFFE0E7FF),
        const Color(0xFF4F46E5),
      ),
      'email_settings' => (
        Icons.mail_outline,
        const Color(0xFFCFFAFE),
        const Color(0xFF0891B2),
      ),
      _ => (Icons.history, const Color(0xFFF3F4F6), AppColors.gray500),
    };
  }

  static String? _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return _activityTsFmt.format(dt);
    } catch (_) {
      return null;
    }
  }
}

class _ActivityFiltersRow extends StatelessWidget {
  const _ActivityFiltersRow({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in _filters)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _FilterPill(
                  label: _filterLabel(f),
                  selected: active == f,
                  onTap: () => onChanged(f),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? const Color(0xFF374151) : Colors.white;
    final selectedFg = isDark ? Colors.white : AppColors.gray900;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? selectedFg : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

class _ActivitySearchField extends StatefulWidget {
  const _ActivitySearchField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_ActivitySearchField> createState() => _ActivitySearchFieldState();
}

class _ActivitySearchFieldState extends State<_ActivitySearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _ActivitySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search activities…',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        suffixIcon: value.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                onPressed: widget.onClear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

String relativeTime(String iso) {
  try {
    final diff = DateTime.now().difference(DateTime.parse(iso));
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  } catch (_) {
    return '';
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color.withValues(alpha: isDark ? 0.18 : 0.10);
    final border = color.withValues(alpha: isDark ? 0.28 : 0.22);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
