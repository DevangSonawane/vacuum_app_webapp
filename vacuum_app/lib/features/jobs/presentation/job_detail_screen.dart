import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/jobs_notifier.dart';
import '../domain/job.dart';
import 'close_job_sheet.dart';

const _pipeline = ['Raised', 'Assigned', 'In Progress', 'Closed'];

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  AsyncValue<Job?> _job = const AsyncLoading();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _job = const AsyncLoading());
    final j = await ref.read(jobsProvider.notifier).fetchDetail(widget.id);
    if (!mounted) return;
    setState(() => _job = AsyncData(j));
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canRaise = !['technician', 'labour'].contains(role);

    return Scaffold(
      body: _job.when(
        loading: () => const _JobDetailSkeleton(),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Failed to load',
          description: friendlyErrorMessage(e),
        ),
        data: (job) {
          if (job == null) {
            return const EmptyState(
              icon: Icons.work_outline,
              title: 'Not found',
              description: 'Job not available.',
            );
          }
          final next = _nextStatus(job.status);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.id,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              color: AppColors.blue600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _HeaderCard(job: job),
                const SizedBox(height: 16),
                _InfoGrid(job: job),
                const SizedBox(height: 16),
                if (job.description.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  AppCard(child: Text(job.description)),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Pipeline',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _Stepper(current: job.status),
                const SizedBox(height: 16),
                Text(
                  'Verification Photos (${job.images.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (job.images.isEmpty)
                  Text(
                    'No photos',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.sizeOf(context).width >= 600
                          ? 3
                          : 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: job.images.length,
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: job.images[i].fileUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ShimmerBox(height: 80),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Reports (${job.reports.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (job.reports.isEmpty)
                  Text(
                    'No reports',
                    style: TextStyle(color: Theme.of(context).hintColor),
                  )
                else
                  Column(
                    children: [
                      for (final r in job.reports)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            onTap: () => context.go('/reports/${r.id}'),
                            child: Row(
                              children: [
                                Text(
                                  r.id,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blue600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                StatusBadge(label: r.status),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                if (job.status == 'Closed')
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: AppColors.emerald500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'This job is closed',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                job.closedDate != null
                                    ? 'Closed on ${_shortDate(job.closedDate)}'
                                    : 'No closed date recorded',
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
                  )
                else if (canRaise && next != null)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        AppButton(
                          label: job.status == 'In Progress'
                              ? 'Close Job with Verification'
                              : 'Advance to $next',
                          expanded: true,
                          onPressed: () async {
                            if (job.status == 'In Progress') {
                              await _openCloseSheet(context, ref, job: job);
                              return;
                            }
                            final ok = await ref
                                .read(jobsProvider.notifier)
                                .advanceStatus(job.id, next);
                            if (!context.mounted) return;
                            if (!ok) {
                              AppToast.show(
                                context,
                                message: 'Failed to advance',
                                type: AppToastType.error,
                              );
                              return;
                            }
                            await _load();
                            if (!context.mounted) return;
                            AppToast.show(
                              context,
                              message: 'Moved to $next',
                              type: AppToastType.success,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _nextStatus(String current) => switch (current) {
    'Raised' => 'Assigned',
    'Assigned' => 'In Progress',
    'In Progress' => 'Closed',
    _ => null,
  };

  Future<void> _openCloseSheet(
    BuildContext context,
    WidgetRef ref, {
    required Job job,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => CloseJobSheet(
        jobId: job.id,
        title: job.title,
        onClose: (files) async {
          final confirmed = await showConfirmDialog(
            context,
            title: 'Close Job',
            body: 'Close this job now? You can close without photos if needed.',
            confirmLabel: 'Close',
            confirmVariant: AppButtonVariant.primary,
          );
          if (!confirmed || !context.mounted) return;

          final okUploads = await ref
              .read(jobsProvider.notifier)
              .uploadAndLinkImages(job.id, files);
          final okStatus = await ref
              .read(jobsProvider.notifier)
              .advanceStatus(job.id, 'Closed');

          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: (okUploads && okStatus)
                ? 'Job closed'
                : 'Failed to close job',
            type: (okUploads && okStatus)
                ? AppToastType.success
                : AppToastType.error,
          );
          if (okUploads && okStatus) {
            await _load();
          }
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.work_outline, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.clientName.isNotEmpty ? job.clientName : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${job.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amount',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(label: job.status),
                _HeroChip(label: job.priority),
                if (job.category.isNotEmpty) _HeroChip(label: job.category),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 600 ? 2 : 1;

    final items = <({String label, String value, IconData icon})>[
      (
        label: 'Client',
        value: job.clientName.isNotEmpty ? job.clientName : '—',
        icon: Icons.groups_outlined,
      ),
      (
        label: 'Technician',
        value: job.technicianName.isNotEmpty ? job.technicianName : '—',
        icon: Icons.engineering_outlined,
      ),
      (
        label: 'Amount',
        value: '₹${job.amount.toStringAsFixed(0)}',
        icon: Icons.currency_rupee,
      ),
      (
        label: 'Raised',
        value: _shortDate(job.raisedDate),
        icon: Icons.calendar_today_outlined,
      ),
      (
        label: 'Scheduled',
        value: _shortDate(job.scheduledDate),
        icon: Icons.event_outlined,
      ),
      (
        label: 'Closed',
        value: _shortDate(job.closedDate),
        icon: Icons.check_circle_outline,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: cols == 1 ? 5.0 : 4.4,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111827)
              : AppColors.gray50,
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
                color: Theme.of(context).dividerColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(items[i].icon, size: 18, color: AppColors.blue600),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    items[i].label.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.w800),
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

class _Stepper extends StatelessWidget {
  const _Stepper({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _pipeline.indexOf(current);
    return Row(
      children: [
        for (int i = 0; i < _pipeline.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: i <= currentIndex
                    ? const Color(0xFFDBEAFE)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  _pipeline[i],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: i <= currentIndex
                        ? AppColors.blue600
                        : Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
          ),
          if (i != _pipeline.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward,
                size: 14,
                color: AppColors.gray400,
              ),
            ),
        ],
      ],
    );
  }
}

String _shortDate(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return '—';
  return v.length >= 10 ? v.substring(0, 10) : v;
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _JobDetailSkeleton extends StatelessWidget {
  const _JobDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppCard(child: ShimmerBox(height: 120)),
          SizedBox(height: 16),
          AppCard(child: ShimmerBox(height: 140)),
          SizedBox(height: 16),
          AppCard(child: ShimmerBox(height: 80)),
          SizedBox(height: 16),
          AppCard(child: ShimmerBox(height: 120)),
        ],
      ),
    );
  }
}
