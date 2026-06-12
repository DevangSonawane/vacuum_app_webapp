import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/reports_notifier.dart';
import '../domain/report.dart';

const _reportStatuses = ['Pending', 'Approved', 'Rejected'];

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);
    final canApprove = role == 'admin';

    final state = ref.watch(reportsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(reportsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Inspection & Service Reports',
              subtitle: state.whenOrNull(
                data: (d) => '${d.items.length} reports',
              ),
              action: canEdit
              ? AppButton(
                      label: 'New Report',
                      onPressed: () => context.push('/reports/new'),
                    )
              : null,
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _ReportsSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: e.toString(),
              ),
              data: (data) {
                final counts = <String, int>{
                  for (final s in _reportStatuses)
                    s: data.items.where((r) => r.status == s).length,
                };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterTabs(
                      value: data.statusFilter,
                      counts: counts,
                      onChanged: (s) =>
                          ref.read(reportsProvider.notifier).setFilter(s),
                    ),
                    const SizedBox(height: 16),
                    if (data.items.isEmpty)
                      const EmptyState(
                        icon: Icons.description_outlined,
                        title: 'No reports found',
                        description:
                            'Create a new report or adjust the filter.',
                      )
                    else
                      Builder(
                        builder: (context) {
                          final width = MediaQuery.sizeOf(context).width;
                          final cols = width >= 720 ? 2 : 1;
                          // Use a fixed tile height so cards don't overflow on
                          // smaller devices / with more metadata pills.
                          final tileHeight = cols == 1 ? 255.0 : 230.0;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: tileHeight,
                            ),
                            itemCount: data.items.length,
                            itemBuilder: (context, i) {
                              final r = data.items[i];
                              return _ReportCard(
                                report: r,
                                canApprove: canApprove && r.status == 'Pending',
                                onTap: () => context.go('/reports/${r.id}'),
                                onApprove: () =>
                                    _setStatus(context, ref, r.id, 'Approved'),
                                onReject: () =>
                                    _setStatus(context, ref, r.id, 'Rejected'),
                              );
                            },
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    WidgetRef ref,
    String id,
    String status,
  ) async {
    final ok = await ref
        .read(reportsProvider.notifier)
        .updateStatus(id, status);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Report $status' : 'Operation failed',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.value,
    required this.counts,
    required this.onChanged,
  });

  final String value;
  final Map<String, int> counts;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['All', ..._reportStatuses];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(t),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: value == t
                        ? (isDark ? AppColors.gray800 : const Color(0xFFDBEAFE))
                        : Colors.transparent,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        t,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: value == t
                              ? (isDark ? Colors.white : AppColors.blue600)
                              : Theme.of(context).hintColor,
                        ),
                      ),
                      if (t != 'All') ...[
                        const SizedBox(width: 8),
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
                            '${counts[t] ?? 0}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.canApprove,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final Report report;
  final bool canApprove;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final docCount = report.technicalReportCount > 0
        ? report.technicalReportCount
        : report.technicalReports.length;
    final pills = <Widget>[
      if ((report.poNumber ?? '').trim().isNotEmpty)
        _Pill(
          label: 'PO-${report.poNumber!.trim()}',
          icon: Icons.inventory_2_outlined,
          bg: const Color(0xFFF3E8FF),
          fg: AppColors.purple500,
        ),
      if ((report.location ?? '').trim().isNotEmpty)
        _Pill(
          label: report.location!.trim(),
          icon: Icons.place_outlined,
          bg: const Color(0xFFD1FAE5),
          fg: AppColors.emerald500,
        ),
      if ((report.serialNo ?? '').trim().isNotEmpty)
        _Pill(
          label: report.serialNo!.trim(),
          icon: Icons.tag_outlined,
          bg: const Color(0xFFF3F4F6),
          fg: AppColors.gray700,
        ),
      if (report.jobTitle.trim().isNotEmpty)
        _Pill(
          label: report.jobTitle.trim(),
          icon: Icons.handyman_outlined,
          bg: const Color(0xFFEFF6FF),
          fg: AppColors.blue600,
        ),
    ];
    return AppCard(
      hover: true,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    report.id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      color: AppColors.blue600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(label: report.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                report.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
              if (pills.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: pills),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (report.imageCount > 0 || report.images.isNotEmpty)
                    _Meta(
                      icon: Icons.image_outlined,
                      text:
                          '${report.imageCount > 0 ? report.imageCount : report.images.length} photos',
                    ),
                  if ((report.clientEmail ?? '').trim().isNotEmpty)
                    _Meta(
                      icon: Icons.mail_outline,
                      text: report.clientEmail!.trim(),
                    ),
                  if (docCount > 0)
                    _Meta(
                      icon: Icons.description_outlined,
                      text: '$docCount docs',
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${report.technicianName} • ${_shortDate(report.reportDate) ?? '—'}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ),
              if (canApprove) ...[
                TextButton.icon(
                  onPressed: onApprove,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 26),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    foregroundColor: AppColors.emerald500,
                  ),
                  icon: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.emerald500,
                    size: 18,
                  ),
                  label: const Text(
                    'Approve',
                    style: TextStyle(color: AppColors.emerald500, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: onReject,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 26),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -4,
                      vertical: -4,
                    ),
                    foregroundColor: AppColors.red500,
                  ),
                  icon: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.red500,
                    size: 18,
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: AppColors.red500, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.gray400),
        const SizedBox(width: 6),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

String? _shortDate(String? iso) {
  if (iso == null) return null;
  final v = iso.trim();
  if (v.isEmpty) return null;
  return v.length >= 10 ? v.substring(0, 10) : v;
}

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: ShimmerBox(height: 36, borderRadius: 999)),
            SizedBox(width: 8),
            Expanded(child: ShimmerBox(height: 36, borderRadius: 999)),
          ],
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < 6; i++) ...[
          const AppCard(child: ShimmerBox(height: 160)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
