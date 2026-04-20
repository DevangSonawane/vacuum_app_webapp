import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/notifications_notifier.dart';
import '../domain/app_notification.dart';

class NotificationsMenu {
  static Future<void> open(BuildContext context) async {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.12),
        builder: (ctx) => const _DesktopOverlay(),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => const _MenuBody(isBottomSheet: true),
    );
  }
}

class _DesktopOverlay extends StatelessWidget {
  const _DesktopOverlay();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 62, right: 12),
          child: GestureDetector(
            onTap: () {}, // absorb
            child: Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 8,
              clipBehavior: Clip.antiAlias,
              child: const SizedBox(
                width: 420,
                child: _MenuBody(isBottomSheet: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuBody extends ConsumerWidget {
  const _MenuBody({required this.isBottomSheet});

  final bool isBottomSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return notifications.when(
      loading: () => SizedBox(
        height: isBottomSheet ? MediaQuery.sizeOf(context).height * 0.7 : 460,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: isBottomSheet ? MediaQuery.sizeOf(context).height * 0.7 : 460,
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load',
          description: e.toString(),
        ),
      ),
      data: (s) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: isBottomSheet
                ? MediaQuery.sizeOf(context).height * 0.86
                : 520,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _ConnectionDot(connected: s.connected),
                    const SizedBox(width: 10),
                    AppButton(
                      label: 'Refresh',
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.refresh_outlined),
                      onPressed: () =>
                          ref.read(notificationsProvider.notifier).refresh(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${s.unreadCount} unread',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Mark all read',
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.outline,
                      onPressed: () async {
                        await ref
                            .read(notificationsProvider.notifier)
                            .markAllRead();
                        if (!context.mounted) return;
                        AppToast.show(
                          context,
                          message: 'Marked all as read',
                          type: AppToastType.success,
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    AppButton(
                      label: 'Clear all',
                      size: AppButtonSize.sm,
                      variant: AppButtonVariant.secondary,
                      onPressed: () async {
                        await ref
                            .read(notificationsProvider.notifier)
                            .clearAll();
                        if (!context.mounted) return;
                        AppToast.show(
                          context,
                          message: 'Cleared notifications',
                          type: AppToastType.info,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: s.items.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: EmptyState(
                            icon: Icons.notifications_none,
                            title: 'No notifications',
                            description: 'You are all caught up.',
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: s.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 6),
                        itemBuilder: (context, i) => _NotificationTile(
                          n: s.items[i],
                          onTap: () async {
                            await ref
                                .read(notificationsProvider.notifier)
                                .markRead(s.items[i]);
                            if (!context.mounted) return;
                            _navigateFromNotification(context, s.items[i]);
                          },
                        ),
                      ),
              ),
              const Divider(height: 1),
              BottomSafeArea(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/activity');
                    },
                    child: const Text('View all notifications →'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateFromNotification(BuildContext context, AppNotification n) {
    final entityType = (n.entityType ?? '').toLowerCase();
    final entityId = (n.entityId ?? '').toString();
    Navigator.of(context).pop();

    if (entityType == 'job' && entityId.isNotEmpty) {
      context.go('/jobs/$entityId');
      return;
    }
    if (entityType == 'report' && entityId.isNotEmpty) {
      context.go('/reports/$entityId');
      return;
    }
    if (entityType == 'amc') {
      context.go('/amc');
      return;
    }
    // fallback
    AppToast.show(
      context,
      message: 'Opened notification',
      type: AppToastType.info,
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.emerald500 : AppColors.gray400;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          connected ? 'Live' : 'Offline',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap});
  final AppNotification n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = notificationMeta(n.event);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : Colors.white;
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(meta.icon, color: meta.color, size: 20),
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
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(n.timestamp),
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 11,
                          ),
                        ),
                        if (!n.read) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.red500,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
