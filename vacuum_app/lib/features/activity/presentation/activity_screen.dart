import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/activity_notifier.dart';
import '../domain/activity_item.dart';

const _filters = ['All', 'job', 'client', 'report', 'technician', 'amc', 'user'];

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

    final state = ref.watch(activityProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Failed to load', description: e.toString()),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Activity History',
              action: IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.read(activityProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => ref.read(activityProvider.notifier).setFilter(f),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: data.typeFilter == f ? const Color(0xFFDBEAFE) : Colors.transparent,
                            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.16)),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: data.typeFilter == f ? AppColors.blue600 : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (data.items.isEmpty)
              const EmptyState(
                icon: Icons.history,
                title: 'No activity yet',
                description: 'Actions will show up here.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.items.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
                itemBuilder: (context, i) => _ActivityRow(
                  item: data.items[i],
                  onTap: () => _onTap(context, data.items[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, ActivityItem item) {
    final id = item.entityId;
    if (id == null || id.isEmpty) return;

    if (item.type == 'job') {
      context.go('/jobs/$id');
      return;
    }
    if (item.type == 'report') {
      context.go('/reports/$id');
      return;
    }

    AppToast.show(context, message: 'Navigation for ${item.type} not wired yet.', type: AppToastType.info);
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, required this.onTap});

  final ActivityItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = _typeStyle(item.type);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'by ${item.user}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                        ),
                      ),
                      Text(
                        relativeTime(item.timestamp),
                        style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if ((item.entityId ?? '').isNotEmpty) ...[
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
      'client' => (Icons.groups_outlined, const Color(0xFFD1FAE5), AppColors.emerald500),
      'amc' => (Icons.verified_user_outlined, const Color(0xFFF3E8FF), AppColors.purple500),
      'report' => (Icons.description_outlined, const Color(0xFFF3F4F6), AppColors.gray500),
      'technician' => (Icons.engineering_outlined, const Color(0xFFFEE2E2), AppColors.red500),
      'user' => (Icons.person_outline, const Color(0xFFE0E7FF), const Color(0xFF4F46E5)),
      'email_settings' => (Icons.mail_outline, const Color(0xFFCFFAFE), const Color(0xFF0891B2)),
      _ => (Icons.history, const Color(0xFFF3F4F6), AppColors.gray500),
    };
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
