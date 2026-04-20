import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/activity_notifier.dart';
import '../domain/activity_item.dart';

const _filters = ['All', 'job', 'client', 'report', 'technician', 'amc', 'user'];

final activitySearchProvider = StateProvider<String>((_) => '');

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
            _ActivityFiltersRow(
              active: data.typeFilter,
              onChanged: (f) => ref.read(activityProvider.notifier).setFilter(f),
            ),
            const SizedBox(height: 12),
            _ActivitySearchField(
              value: ref.watch(activitySearchProvider),
              onChanged: (v) => ref.read(activitySearchProvider.notifier).state = v,
              onClear: () => ref.read(activitySearchProvider.notifier).state = '',
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final q = ref.watch(activitySearchProvider).trim().toLowerCase();
                final items = q.length >= 2
                    ? data.items.where((it) {
                        final action = it.action.toLowerCase();
                        final by = it.user.toLowerCase();
                        final entity = (it.entityId ?? '').toLowerCase();
                        return action.contains(q) || by.contains(q) || entity.contains(q);
                      }).toList()
                    : data.items;

                if (data.items.isEmpty && q.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    title: 'No activity yet',
                    description: 'Actions will show up here.',
                  );
                }

                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    title: 'No activity found',
                    description: 'No activity logs match your current filter.',
                  );
                }

                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.12), height: 1),
                    itemBuilder: (context, i) => _ActivityRow(
                      item: items[i],
                      onTap: () => _onTap(context, items[i]),
                    ),
                  ),
                );
              },
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
    final typeLabel = _filterLabel(item.type);
    final hasEntity = (item.entityId ?? '').isNotEmpty;
    final clickable = hasEntity && (item.type == 'job' || item.type == 'report');
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
                        const Text('·', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                        const SizedBox(width: 8),
                      ] else
                        const Spacer(),
                      Text(tsText, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
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
      'client' => (Icons.groups_outlined, const Color(0xFFD1FAE5), AppColors.emerald500),
      'amc' => (Icons.verified_user_outlined, const Color(0xFFF3E8FF), AppColors.purple500),
      'report' => (Icons.description_outlined, const Color(0xFFF3F4F6), AppColors.gray500),
      'technician' => (Icons.engineering_outlined, const Color(0xFFFEE2E2), AppColors.red500),
      'user' => (Icons.person_outline, const Color(0xFFE0E7FF), const Color(0xFF4F46E5)),
      'email_settings' => (Icons.mail_outline, const Color(0xFFCFFAFE), const Color(0xFF0891B2)),
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
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
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
  const _FilterPill({required this.label, required this.selected, required this.onTap});

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
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _ActivitySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
