import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/error_message.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../amc/data/amc_repository.dart';
import '../../amc/domain/amc_contract.dart';
import '../../clients/data/clients_repository.dart';
import '../../technicians/data/technicians_repository.dart';
import '../../technicians/domain/technician.dart';
import '../application/jobs_notifier.dart';
import '../domain/job.dart';
import 'close_job_sheet.dart';

const _statuses = ['Raised', 'Assigned', 'In Progress', 'Closed', 'Cancelled'];
const _priorities = ['Low', 'Medium', 'High', 'Critical'];
const _categories = [
  'Service',
  'AMC Visit',
  'Breakdown',
  'Installation & Commissioning',
  'Inspection',
  'Workshop',
  'Trial',
  'Office',
  'Office Visit',
  'Vendor Visit',
  'Trial Pump Installation',
];

const _statusBorderColor = <String, Color>{
  'Raised': AppColors.purple500,
  'Assigned': AppColors.blue500,
  'In Progress': AppColors.amber500,
  'Closed': AppColors.emerald500,
  'Cancelled': AppColors.red500,
};

const _statusFlow = <String, String>{
  'Raised': 'Assigned',
  'Assigned': 'In Progress',
  'In Progress': 'Closed',
};

enum _JobAction { viewDetails, advance, cancel }

class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(jobsProvider.notifier).search(query.trim());
    });
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[(month - 1).clamp(0, 11)];
  }

  void _openExportDialog(BuildContext context) {
    final now = DateTime.now();
    final techniciansFuture = TechniciansRepository(
      dio: ref.read(dioProvider),
    ).fetchTechnicians(limit: 200, search: '');
    int month = now.month;
    int year = now.year;
    int? day;
    int? technicianId;
    String? status;
    String? category;
    bool exporting = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return FutureBuilder<List<Technician>>(
          future: techniciansFuture,
          builder: (context, snapshot) {
            final technicians = snapshot.data ?? const <Technician>[];
            final loadingTechnicians =
                snapshot.connectionState == ConnectionState.waiting;
            final technicianLoadFailed = snapshot.hasError;

            return StatefulBuilder(
              builder: (context, setLocalState) {
                Future<void> exportNow() async {
                  if (exporting || loadingTechnicians || technicianLoadFailed) {
                    return;
                  }
                  setLocalState(() => exporting = true);
                  try {
                    final ok = await _downloadVisitScheduleExcel(
                      month: month,
                      year: year,
                      day: day,
                      technicianId: technicianId,
                      status: status,
                      category: category,
                    );
                    if (ok && navigator.mounted) {
                      navigator.pop();
                    }
                  } finally {
                    if (navigator.mounted) {
                      setLocalState(() => exporting = false);
                    }
                  }
                }

                final yearOptions = [year - 1, year, year + 1]
                    .map((y) => AppDropdownItem<int?>(value: y, label: '$y'))
                    .toList(growable: false);
                final monthOptions = List.generate(
                  12,
                  (i) => AppDropdownItem<int?>(
                    value: i + 1,
                    label: _monthName(i + 1),
                  ),
                );
                final dayOptions = [
                  const AppDropdownItem<int?>(value: null, label: 'All Days'),
                  ...List.generate(
                    31,
                    (i) => AppDropdownItem<int?>(
                      value: i + 1,
                      label: 'Day ${i + 1}',
                    ),
                  ),
                ];
                final techOptions = technicians
                    .map(
                      (t) => AppDropdownItem<int?>(
                        value: t.id,
                        label: t.phone.isNotEmpty
                            ? '${t.name} • ${t.phone}'
                            : t.name,
                      ),
                    )
                    .toList(growable: false);
                final statusOptions = [
                  const AppDropdownItem<String?>(
                    value: null,
                    label: 'All Status',
                  ),
                  ..._statuses.map(
                    (s) => AppDropdownItem<String?>(value: s, label: s),
                  ),
                ];
                final categoryOptions = [
                  const AppDropdownItem<String?>(
                    value: null,
                    label: 'All Categories',
                  ),
                  ..._categories.map(
                    (c) => AppDropdownItem<String?>(value: c, label: c),
                  ),
                ];

                return AlertDialog(
                  title: const Text('Export Visit Schedule'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (loadingTechnicians)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading technicians...',
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (technicianLoadFailed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Unable to load technicians for filtering.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          )
                        else ...[
                          Text(
                            'Download an Excel report of scheduled visits for the selected month.',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppDropdownField<int?>(
                                  label: 'Month',
                                  value: month,
                                  items: monthOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setLocalState(() => month = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppDropdownField<int?>(
                                  label: 'Year',
                                  value: year,
                                  items: yearOptions,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setLocalState(() => year = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppDropdownField<int?>(
                            label: 'Day (optional)',
                            value: day,
                            items: dayOptions,
                            allowNull: true,
                            nullLabel: 'All Days (full month)',
                            onChanged: (value) =>
                                setLocalState(() => day = value),
                          ),
                          const SizedBox(height: 12),
                          AppDropdownField<int?>(
                            label: 'Technician (optional)',
                            value: technicianId,
                            items: techOptions,
                            allowNull: true,
                            nullLabel: 'All Technicians',
                            onChanged: (value) =>
                                setLocalState(() => technicianId = value),
                          ),
                          const SizedBox(height: 12),
                          AppDropdownField<String?>(
                            label: 'Status (optional)',
                            value: status,
                            items: statusOptions,
                            allowNull: true,
                            nullLabel: 'All Status',
                            onChanged: (value) =>
                                setLocalState(() => status = value),
                          ),
                          const SizedBox(height: 12),
                          AppDropdownField<String?>(
                            label: 'Category (optional)',
                            value: category,
                            items: categoryOptions,
                            allowNull: true,
                            nullLabel: 'All Categories',
                            onChanged: (value) =>
                                setLocalState(() => category = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: exporting
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed:
                          (exporting ||
                              loadingTechnicians ||
                              technicianLoadFailed)
                          ? null
                          : exportNow,
                      child: exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Download Excel'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  bool _canCancelJob(String role) => ['admin', 'manager'].contains(role);

  bool _canDeleteJob(String role) => role == 'admin';

  Future<bool> _downloadVisitScheduleExcel({
    required int month,
    required int year,
    int? day,
    int? technicianId,
    String? status,
    String? category,
  }) async {
    final dio = ref.read(dioProvider);
    try {
      final params = <String, dynamic>{'month': month, 'year': year};
      if (day != null) params['day'] = day;
      if (technicianId != null) params['technician_id'] = technicianId;
      if (status != null && status.trim().isNotEmpty) {
        params['status'] = status.trim();
      }
      if (category != null && category.trim().isNotEmpty) {
        params['category'] = category.trim();
      }

      final res = await dio.get(
        'reports/visit-schedule/excel',
        queryParameters: params,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = res.data;
      if (bytes is! List) {
        throw Exception('Invalid Excel response from server.');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'visit-schedule-$year-${month.toString().padLeft(2, '0')}.xlsx';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(List<int>.from(bytes), flush: true);

      final opened = await OpenFile.open(file.path);
      if (opened.type != ResultType.done) {
        throw Exception(opened.message);
      }

      if (!mounted) return false;
      AppToast.show(
        context,
        message: 'Excel downloaded!',
        type: AppToastType.success,
      );
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      AppToast.show(
        context,
        message: e.response?.data is Map
            ? (e.response?.data['message']?.toString() ?? 'Export failed')
            : 'Export failed',
        type: AppToastType.error,
      );
      return false;
    } catch (e) {
      if (!mounted) return false;
      AppToast.show(context, message: e.toString(), type: AppToastType.error);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final lowerRole = role.toLowerCase();
    final canRaise = !['technician', 'labour'].contains(lowerRole);
    final canCancel = _canCancelJob(lowerRole);
    final canDelete = _canDeleteJob(lowerRole);
    final isAdmin = lowerRole == 'admin';

    final state = ref.watch(jobsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(jobsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
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
                    child: const Icon(Icons.work_outline, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit Scheduled',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Raised, assigned, in progress, and closed jobs stay visible in one dense list.',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canRaise || isAdmin) ...[
                    const SizedBox(width: 12),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            if (isAdmin)
                              AppButton(
                                label: 'Export Excel',
                                size: AppButtonSize.sm,
                                variant: AppButtonVariant.secondary,
                                leading: const Icon(Icons.download_outlined),
                                onPressed: () => _openExportDialog(context),
                              ),
                            if (canRaise)
                              AppButton(
                                label: '+ Raise Job',
                                size: AppButtonSize.sm,
                                onPressed: () => context.push('/jobs/new'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search work orders...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _JobsSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: friendlyErrorMessage(e),
              ),
              data: (data) {
                final counts = <String, int>{
                  for (final s in _statuses)
                    s: data.items.where((j) => j.status == s).length,
                };
                final activeCount = data.items
                    .where((j) => j.status != 'Closed')
                    .length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatPill(
                      label: 'Active',
                      value: activeCount,
                      color: AppColors.blue500,
                    ),
                    const SizedBox(height: 12),
                    _FilterTabs(
                      value: data.statusFilter,
                      counts: counts,
                      onChanged: (s) =>
                          ref.read(jobsProvider.notifier).setFilter(s),
                    ),
                    const SizedBox(height: 16),
                    if (data.items.isEmpty)
                      const EmptyState(
                        icon: Icons.work_outline,
                        title: 'No work orders',
                        description: 'Raise a new job or adjust the filter.',
                      )
                    else if (data.statusFilter == 'All')
                      _KanbanAllView(
                        jobs: data.items,
                        canRaise: canRaise,
                        canCancel: canCancel,
                        canDelete: canDelete,
                        onTap: (id) => context.go('/jobs/$id'),
                        onAdvance: (job) =>
                            _advanceOrClose(context, ref, job, canRaise),
                        onCancel: (job) =>
                            _confirmCancelJob(context, ref, job, canCancel),
                        onDelete: (job) =>
                            _confirmDeleteJob(context, ref, job, canDelete),
                      )
                    else
                      _FilteredListView(
                        jobs: data.items,
                        canRaise: canRaise,
                        canCancel: canCancel,
                        canDelete: canDelete,
                        onTap: (id) => context.go('/jobs/$id'),
                        onAdvance: (job) =>
                            _advanceOrClose(context, ref, job, canRaise),
                        onCancel: (job) =>
                            _confirmCancelJob(context, ref, job, canCancel),
                        onDelete: (job) =>
                            _confirmDeleteJob(context, ref, job, canDelete),
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

  Future<void> _advanceOrClose(
    BuildContext context,
    WidgetRef ref,
    Job job,
    bool canRaise,
  ) async {
    if (!canRaise || job.status == 'Closed') return;
    final next = _statusFlow[job.status];
    if (next == null) return;
    if (job.status == 'In Progress') {
      await _openCloseSheet(context, ref, jobId: job.id, title: job.title);
      return;
    }
    final ok = await ref
        .read(jobsProvider.notifier)
        .advanceStatus(job.id, next);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Moved to $next' : 'Failed to advance',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  Future<void> _confirmDeleteJob(
    BuildContext context,
    WidgetRef ref,
    Job job,
    bool canDelete,
  ) async {
    if (!canDelete) {
      AppToast.show(
        context,
        message: 'You do not have permission to delete jobs.',
        type: AppToastType.error,
      );
      return;
    }
    if (job.status != 'Assigned') {
      AppToast.show(
        context,
        message: 'Only assigned jobs can be deleted.',
        type: AppToastType.error,
      );
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Job',
      body: 'Delete ${job.title}? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(jobsProvider.notifier).deleteJob(job.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Job deleted' : 'Failed to delete job',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  Future<void> _confirmCancelJob(
    BuildContext context,
    WidgetRef ref,
    Job job,
    bool canCancel,
  ) async {
    if (!canCancel) {
      AppToast.show(
        context,
        message: 'You do not have permission to cancel visits.',
        type: AppToastType.error,
      );
      return;
    }
    if (job.status == 'Closed' || job.status == 'Cancelled') {
      AppToast.show(
        context,
        message: 'This visit cannot be cancelled.',
        type: AppToastType.error,
      );
      return;
    }

    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => const _CancelVisitDialog(
        title: 'Cancel Visit',
        body:
            'The visit will be marked as cancelled and the client will be '
            'notified.',
        hintText: 'e.g. Client requested reschedule',
        cancelLabel: 'Keep Visit',
        confirmLabel: 'Cancel Visit',
      ),
    );
    if (reason == null || !context.mounted) return;

    final ok = await ref
        .read(jobsProvider.notifier)
        .cancelJob(job.id, reason: reason);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Visit cancelled' : 'Failed to cancel visit',
      type: ok ? AppToastType.success : AppToastType.error,
    );
  }

  Future<void> _openCloseSheet(
    BuildContext context,
    WidgetRef ref, {
    required String jobId,
    required String title,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => CloseJobSheet(
        jobId: jobId,
        title: title,
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
              .uploadAndLinkImages(jobId, files);
          final okStatus = await ref
              .read(jobsProvider.notifier)
              .advanceStatus(jobId, 'Closed');

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
        },
      ),
    );
  }
}

class JobCreateScreen extends ConsumerWidget {
  const JobCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/jobs');
      }
    }

    return _RaiseJobSheet(
      asSheet: false,
      dio: ref.read(dioProvider),
      onSubmit: (payload) async {
        final ok = await ref.read(jobsProvider.notifier).create(payload);
        if (!context.mounted) return;
        if (ok) close();
        AppToast.show(
          context,
          message: ok ? 'Work order raised!' : 'Operation failed',
          type: ok ? AppToastType.success : AppToastType.error,
        );
      },
    );
  }
}

class _CancelVisitDialog extends StatefulWidget {
  const _CancelVisitDialog({
    required this.title,
    required this.body,
    required this.hintText,
    required this.cancelLabel,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String hintText;
  final String cancelLabel;
  final String confirmLabel;

  @override
  State<_CancelVisitDialog> createState() => _CancelVisitDialogState();
}

class _CancelVisitDialogState extends State<_CancelVisitDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Cancel reason',
                hintText: widget.hintText,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(widget.cancelLabel),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
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
    final tabs = ['All', ..._statuses];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in tabs)
          Builder(
            builder: (context) {
              final selected = value == t;
              final accent = t == 'All'
                  ? AppColors.blue600
                  : _statusBorderColor[t] ?? AppColors.gray500;
              final background = selected
                  ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                  : (isDark
                        ? const Color(0xFF111827)
                        : const Color(0xFFF9FAFB));
              final borderColor = selected
                  ? accent.withValues(alpha: 0.28)
                  : AppColors.gray200;

              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: background,
                    border: Border.all(color: borderColor),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.14),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: selected
                              ? accent
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
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: Text(
                            '${counts[t] ?? 0}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? accent
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _KanbanAllView extends StatelessWidget {
  const _KanbanAllView({
    required this.jobs,
    required this.canRaise,
    required this.canCancel,
    required this.canDelete,
    required this.onTap,
    required this.onAdvance,
    required this.onCancel,
    required this.onDelete,
  });

  final List<Job> jobs;
  final bool canRaise;
  final bool canCancel;
  final bool canDelete;
  final ValueChanged<String> onTap;
  final ValueChanged<Job> onAdvance;
  final ValueChanged<Job> onCancel;
  final ValueChanged<Job> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final status in _statuses) ...[
          _StatusSection(
            status: status,
            items: jobs.where((j) => j.status == status).toList(),
            canRaise: canRaise,
            canCancel: canCancel,
            canDelete: canDelete,
            onTap: onTap,
            onAdvance: onAdvance,
            onCancel: onCancel,
            onDelete: onDelete,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.status,
    required this.items,
    required this.canRaise,
    required this.canCancel,
    required this.canDelete,
    required this.onTap,
    required this.onAdvance,
    required this.onCancel,
    required this.onDelete,
  });

  final String status;
  final List<Job> items;
  final bool canRaise;
  final bool canCancel;
  final bool canDelete;
  final ValueChanged<String> onTap;
  final ValueChanged<Job> onAdvance;
  final ValueChanged<Job> onCancel;
  final ValueChanged<Job> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(label: status),
            const SizedBox(width: 8),
            Text(
              '${items.length}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text('No items', style: TextStyle(color: Theme.of(context).hintColor))
        else
          Column(
            children: [
              for (final job in items) ...[
                _JobCardVertical(
                  job: job,
                  canRaise: canRaise,
                  canCancel: canCancel,
                  canDelete: canDelete,
                  onTap: () => onTap(job.id),
                  onAdvance: () => onAdvance(job),
                  onCancel: () => onCancel(job),
                  onLongPress: canDelete ? () => onDelete(job) : null,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }
}

class _FilteredListView extends StatelessWidget {
  const _FilteredListView({
    required this.jobs,
    required this.canRaise,
    required this.canCancel,
    required this.canDelete,
    required this.onTap,
    required this.onAdvance,
    required this.onCancel,
    required this.onDelete,
  });

  final List<Job> jobs;
  final bool canRaise;
  final bool canCancel;
  final bool canDelete;
  final ValueChanged<String> onTap;
  final ValueChanged<Job> onAdvance;
  final ValueChanged<Job> onCancel;
  final ValueChanged<Job> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final job in jobs) ...[
          _JobCardHorizontal(
            job: job,
            canRaise: canRaise,
            canCancel: canCancel,
            canDelete: canDelete,
            onTap: () => onTap(job.id),
            onAdvance: () => onAdvance(job),
            onCancel: () => onCancel(job),
            onLongPress: canDelete ? () => onDelete(job) : null,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _JobCardVertical extends StatelessWidget {
  const _JobCardVertical({
    required this.job,
    required this.canRaise,
    required this.canCancel,
    required this.canDelete,
    required this.onTap,
    required this.onAdvance,
    required this.onCancel,
    required this.onLongPress,
  });

  final Job job;
  final bool canRaise;
  final bool canCancel;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onAdvance;
  final VoidCallback onCancel;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final border = _statusBorderColor[job.status] ?? AppColors.gray200;
    final next = _statusFlow[job.status];
    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: border, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.id,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(label: job.status),
                        if (canRaise)
                          _JobOverflowMenuButton(
                            job: job,
                            canRaise: canRaise,
                            canCancel: canCancel,
                            onViewDetails: onTap,
                            onAdvance: onAdvance,
                            onCancel: onCancel,
                            nextStatus: next,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(label: job.priority),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MetaRow(
              icon: Icons.groups_outlined,
              text: job.clientName.isNotEmpty ? job.clientName : '—',
            ),
            _MetaRow(
              icon: Icons.engineering_outlined,
              text: job.technicianDisplayName.isNotEmpty
                  ? job.technicianDisplayName
                  : 'Unassigned',
            ),
            _MetaRow(
              icon: Icons.calendar_today_outlined,
              text: _jobScheduleText(job) ?? '—',
            ),
            if (job.amount > 0) ...[
              const SizedBox(height: 6),
              Text(
                '₹${job.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JobCardHorizontal extends StatelessWidget {
  const _JobCardHorizontal({
    required this.job,
    required this.canRaise,
    required this.canCancel,
    required this.canDelete,
    required this.onTap,
    required this.onAdvance,
    required this.onCancel,
    required this.onLongPress,
  });

  final Job job;
  final bool canRaise;
  final bool canCancel;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onAdvance;
  final VoidCallback onCancel;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final border = _statusBorderColor[job.status] ?? AppColors.gray200;
    final next = _statusFlow[job.status];
    return AppCard(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: border, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    job.clientName.isNotEmpty ? job.clientName : '—',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      StatusBadge(label: job.priority),
                      if (job.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).dividerColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            job.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge(label: job.status),
                    if (canRaise)
                      _JobOverflowMenuButton(
                        job: job,
                        canRaise: canRaise,
                        canCancel: canCancel,
                        onViewDetails: onTap,
                        onAdvance: onAdvance,
                        onCancel: onCancel,
                        nextStatus: next,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${job.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobOverflowMenuButton extends StatelessWidget {
  const _JobOverflowMenuButton({
    required this.job,
    required this.canRaise,
    required this.canCancel,
    required this.onViewDetails,
    required this.onAdvance,
    required this.onCancel,
    required this.nextStatus,
  });

  final Job job;
  final bool canRaise;
  final bool canCancel;
  final VoidCallback onViewDetails;
  final VoidCallback onAdvance;
  final VoidCallback onCancel;
  final String? nextStatus;

  @override
  Widget build(BuildContext context) {
    final canAdvance = nextStatus != null && job.status != 'Cancelled';
    final canCancelVisit =
        canCancel && ['Raised', 'Assigned'].contains(job.status);

    return PopupMenuButton<_JobAction>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_horiz, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) {
        switch (action) {
          case _JobAction.viewDetails:
            onViewDetails();
            break;
          case _JobAction.advance:
            onAdvance();
            break;
          case _JobAction.cancel:
            onCancel();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<_JobAction>(
          value: _JobAction.viewDetails,
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18),
              SizedBox(width: 10),
              Text('View Details'),
            ],
          ),
        ),
        if (canAdvance)
          PopupMenuItem<_JobAction>(
            value: _JobAction.advance,
            child: Row(
              children: [
                Icon(
                  job.status == 'In Progress'
                      ? Icons.camera_alt_outlined
                      : Icons.arrow_forward,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  job.status == 'In Progress'
                      ? 'Close Job'
                      : 'Move to $nextStatus',
                ),
              ],
            ),
          ),
        if (canCancelVisit)
          const PopupMenuItem<_JobAction>(
            value: _JobAction.cancel,
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, size: 18, color: AppColors.red500),
                SizedBox(width: 10),
                Text('Cancel Visit'),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.gray400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
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

String? _shortDate(String? iso) {
  if (iso == null) return null;
  final v = iso.trim();
  if (v.isEmpty) return null;
  return v.length >= 10 ? v.substring(0, 10) : v;
}

String? _jobScheduleText(Job job) {
  final start = _shortDate(job.startDate);
  final end = _shortDate(job.endDate);
  if (start != null && end != null) return '$start → $end';
  if (start != null) return start;
  if (end != null) return end;
  return _shortDate(job.scheduledDate);
}

class _RaiseJobSheet extends StatefulWidget {
  const _RaiseJobSheet({
    required this.dio,
    required this.onSubmit,
    this.asSheet = true,
  });

  final Dio dio;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;
  final bool asSheet;

  @override
  State<_RaiseJobSheet> createState() => _RaiseJobSheetState();
}

class _RaiseJobSheetState extends State<_RaiseJobSheet> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();

  bool _loading = false;
  String _dateMode = 'single';
  DateTime? _scheduledDate;
  DateTime? _startDate;
  DateTime? _endDate;

  int? _clientId;
  final List<int> _techIds = [];
  String? _amcId;
  String _priority = _priorities[1];
  String _category = _categories.first;

  List<({int id, String name})> _clients = const [];
  List<({int id, String name, String phone})> _techs = const [];
  List<AmcContract> _amcContracts = const [];
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _fetchDropdowns();
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _fetchDropdowns() async {
    setState(() => _fetching = true);
    try {
      final clientsRepo = ClientsRepository(dio: widget.dio);
      final techRepo = TechniciansRepository(dio: widget.dio);
      final amcRepo = AmcRepository(dio: widget.dio);
      final clients = await clientsRepo.fetchClients(
        limit: 100,
        search: '',
        type: '',
      );
      final techs = await techRepo.fetchTechnicians(
        limit: 100,
        search: '',
        status: 'Active',
      );
      final amcContracts = await amcRepo.fetchContracts(limit: 200);

      _clients = [for (final c in clients) (id: c.id, name: c.name)];
      _techs = [
        for (final t in techs) (id: t.id, name: t.name, phone: t.phone),
      ];
      _amcContracts = amcContracts;
      if (_clients.isNotEmpty) _clientId ??= _clients.first.id;
    } catch (_) {
      // ignore - will show empty dropdown
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<List<({int id, String name})>> _searchClients(String query) async {
    final search = query.trim();
    final clientsRepo = ClientsRepository(dio: widget.dio);
    final clients = await clientsRepo.fetchClients(
      limit: search.isEmpty ? 100 : 50,
      search: search,
      type: '',
    );
    return [for (final c in clients) (id: c.id, name: c.name)];
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_title.text.trim().isEmpty || _clientId == null) {
      AppToast.show(
        context,
        message: 'Job title and client are required.',
        type: AppToastType.error,
      );
      return;
    }

    if (_dateMode == 'range') {
      if (_startDate == null || _endDate == null) {
        AppToast.show(
          context,
          message: 'Start date and end date are required for a date range.',
          type: AppToastType.error,
        );
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        AppToast.show(
          context,
          message: 'End date must be on or after the start date.',
          type: AppToastType.error,
        );
        return;
      }
    }

    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'client_id': _clientId,
      'priority': _priority,
      'category': _category,
      if (_techIds.isNotEmpty) 'technician_ids': _techIds,
      if (_amcId != null && _amcId!.trim().isNotEmpty) 'amc_id': _amcId,
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (num.tryParse(_amount.text.trim()) != null)
        'amount': num.parse(_amount.text.trim()),
    };

    if (_dateMode == 'single') {
      if (_scheduledDate != null) {
        payload['scheduled_date'] = _scheduledDate!.toIso8601String().substring(
          0,
          10,
        );
      }
    } else {
      if (_startDate != null) {
        payload['start_date'] = _startDate!.toIso8601String().substring(0, 10);
      }
      if (_endDate != null) {
        payload['end_date'] = _endDate!.toIso8601String().substring(0, 10);
      }
    }

    await widget.onSubmit(payload);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    void close() {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/jobs');
      }
    }

    final visibleAmcContracts = [..._amcContracts]
      ..sort((a, b) => a.id.compareTo(b.id));
    AmcContract? selectedAmc;
    final selId = _amcId?.trim();
    if (selId != null && selId.isNotEmpty) {
      for (final a in _amcContracts) {
        if (a.id == selId) {
          selectedAmc = a;
          break;
        }
      }
    }

    Widget content(ScrollController? scroll) => SingleChildScrollView(
      controller: scroll,
      padding: EdgeInsets.fromLTRB(
        16,
        widget.asSheet ? 0 : 16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: !widget.asSheet,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.asSheet) ...[
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: _loading ? null : close,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Raise Work Order',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                'Raise Work Order',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (_fetching)
              const AppCard(child: ShimmerBox(height: 120))
            else ...[
              _field('Job Title *', _title, hint: 'Routine inspection'),
              const SizedBox(height: 12),
              _searchableClientDropdown(
                label: 'Client *',
                value: _clientId,
                items: _clients,
                enabled: !_loading,
                onChanged: (v) {
                  if (_clientId != v) {
                    setState(() {
                      _clientId = v;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              _multiTechnicianPicker(
                label: 'Assign Technicians',
                selectedIds: _techIds,
                items: _techs,
                enabled: !_loading,
                onChanged: (ids) => setState(() {
                  _techIds
                    ..clear()
                    ..addAll(ids);
                }),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dropdown(
                      label: 'Priority',
                      value: _priority,
                      items: _priorities,
                      onChanged: (v) =>
                          setState(() => _priority = v ?? _priority),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown(
                      label: 'Category',
                      value: _category,
                      items: _categories,
                      onChanged: (v) =>
                          setState(() => _category = v ?? _category),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dateModeToggle(),
              const SizedBox(height: 10),
              if (_dateMode == 'single')
                _datePicker(
                  context,
                  label: 'Scheduled Date',
                  value: _scheduledDate,
                  hint: 'Select date',
                  onPicked: (picked) => setState(() => _scheduledDate = picked),
                )
              else
                _dateRangePicker(context),
              const SizedBox(height: 12),
              _field(
                'Amount (₹)',
                _amount,
                hint: '12000',
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _searchableDropdownAmc(
                label: 'Linked AMC Contract (optional)',
                value: _amcId,
                items: visibleAmcContracts,
                onChanged: (v) => setState(() => _amcId = v),
              ),
              if (selectedAmc != null) ...[
                const SizedBox(height: 8),
                _amcBadgeStrip(selectedAmc),
              ],
              const SizedBox(height: 12),
              _field('Description', _description, hint: 'Notes…', lines: 3),
              const SizedBox(height: 20),
              BottomSafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.secondary,
                        expanded: true,
                        onPressed: _loading ? null : close,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Raise Work Order',
                        expanded: true,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!widget.asSheet) return content(null);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => content(scroll),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboard,
    int lines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          enabled: !_loading,
          keyboardType: keyboard,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return AppDropdownField<String>(
      label: label,
      value: value,
      items: [for (final o in items) AppDropdownItem(value: o, label: o)],
      enabled: !_loading,
      onChanged: onChanged,
    );
  }

  Widget _searchableClientDropdown({
    required String label,
    required int? value,
    required List<({int id, String name})> items,
    required bool enabled,
    required ValueChanged<int?> onChanged,
  }) {
    return _AsyncSearchableClientDropdown(
      label: label,
      value: value,
      initialItems: items,
      enabled: enabled,
      searchClients: _searchClients,
      onChanged: onChanged,
    );
  }

  Widget _multiTechnicianPicker({
    required String label,
    required List<({int id, String name, String phone})> items,
    required List<int> selectedIds,
    required bool enabled,
    required ValueChanged<List<int>> onChanged,
  }) {
    return _MultiTechnicianPicker(
      label: label,
      items: items,
      selectedIds: selectedIds,
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  Widget _searchableDropdownAmc({
    required String label,
    required String? value,
    required List<AmcContract> items,
    required ValueChanged<String?> onChanged,
  }) {
    return _SearchableDropdownString(
      label: label,
      value: (value?.trim().isEmpty ?? true) ? null : value,
      items: items
          .map((a) => (value: a.id, label: _amcLabel(a)))
          .toList(growable: false),
      enabled: !_loading,
      allowNull: true,
      nullLabel: '— Not linked to an AMC —',
      onChanged: onChanged,
    );
  }

  Widget _amcBadgeStrip(AmcContract a) {
    Color statusBg;
    Color statusFg;
    switch (a.status) {
      case 'Active':
        statusBg = const Color(0xFFECFDF5);
        statusFg = const Color(0xFF047857);
        break;
      case 'Expiring Soon':
        statusBg = const Color(0xFFFFFBEB);
        statusFg = const Color(0xFFB45309);
        break;
      default:
        statusBg = const Color(0xFFF3F4F6);
        statusFg = const Color(0xFF6B7280);
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? const Color(0xFF111827) : Colors.white;

    Widget chip(String text, {Color? bg, Color? fg}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if ((a.poNumber ?? '').trim().isNotEmpty)
          chip(
            'PO: ${a.poNumber}',
            bg: const Color(0xFFF5F3FF),
            fg: const Color(0xFF6D28D9),
          ),
        chip(a.status, bg: statusBg, fg: statusFg),
        if ((a.endDate ?? '').trim().isNotEmpty)
          chip('Expires: ${_shortDate(a.endDate!)}', fg: AppColors.gray500),
      ],
    );
  }

  static String _amcLabel(AmcContract a) {
    final po = (a.poNumber ?? '').trim().isEmpty ? '' : ' | PO: ${a.poNumber}';
    final client = a.clientName.trim().isEmpty
        ? ''
        : ' — ${a.clientName.trim()}';
    return '${a.id}$po — ${a.title}$client';
  }

  static String _shortDate(String v) => v.length >= 10 ? v.substring(0, 10) : v;

  Widget _dateModeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Single',
                selected: _dateMode == 'single',
                onTap: () => setState(() {
                  _dateMode = 'single';
                  _startDate = null;
                  _endDate = null;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeButton(
                label: 'Date Range',
                selected: _dateMode == 'range',
                onTap: () => setState(() {
                  _dateMode = 'range';
                  _scheduledDate = null;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dateRangePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _datePicker(
                context,
                label: 'From Date',
                value: _startDate,
                hint: 'Select start date',
                onPicked: (picked) => setState(() => _startDate = picked),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _datePicker(
                context,
                label: 'To Date',
                value: _endDate,
                hint: 'Select end date',
                onPicked: (picked) => setState(() => _endDate = picked),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Select the full visit date range, from the first day to the last day.',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11),
        ),
      ],
    );
  }

  Widget _datePicker(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
    String hint = 'Select date',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) onPicked(picked);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF374151) : AppColors.gray200,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF0B1220) : AppColors.gray50,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value != null
                        ? value.toIso8601String().substring(0, 10)
                        : hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      color: value != null ? null : AppColors.gray400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? (isDark ? const Color(0xFF1D4ED8) : AppColors.blue600)
              : (isDark ? const Color(0xFF111827) : AppColors.gray100),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Theme.of(context).hintColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MultiTechnicianPicker extends StatefulWidget {
  const _MultiTechnicianPicker({
    required this.label,
    required this.items,
    required this.selectedIds,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final List<({int id, String name, String phone})> items;
  final List<int> selectedIds;
  final bool enabled;
  final ValueChanged<List<int>> onChanged;

  @override
  State<_MultiTechnicianPicker> createState() => _MultiTechnicianPickerState();
}

class _MultiTechnicianPickerState extends State<_MultiTechnicianPicker> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _query = '';
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      if (!_isOpen) setState(() => _isOpen = true);
    }
  }

  void _openPicker() {
    if (!widget.enabled) return;
    if (_isOpen) return;
    setState(() => _isOpen = true);
    _focusNode.requestFocus();
  }

  void _closePicker({bool clearQuery = false}) {
    if (!mounted) return;
    setState(() {
      _isOpen = false;
      if (clearQuery) {
        _query = '';
        _controller.clear();
      }
    });
    _focusNode.unfocus();
  }

  List<({int id, String name, String phone})> get _filteredItems {
    final query = _query.trim().toLowerCase();
    final selected = widget.selectedIds.map((id) => id.toString()).toSet();
    return widget.items
        .where((item) {
          if (selected.contains(item.id.toString())) return false;
          if (query.isEmpty) return true;
          return item.name.toLowerCase().contains(query) ||
              item.phone.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _add(int id) {
    if (!widget.enabled || widget.selectedIds.contains(id)) return;
    widget.onChanged([...widget.selectedIds, id]);
    _controller.clear();
    setState(() {
      _query = '';
      _isOpen = true;
    });
    _focusNode.requestFocus();
  }

  void _remove(int id) {
    if (!widget.enabled) return;
    widget.onChanged(
      widget.selectedIds.where((selected) => selected != id).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final selectedItems = widget.items
        .where((item) => widget.selectedIds.contains(item.id))
        .toList(growable: false);
    final filtered = _filteredItems;
    final showList = _isOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1220) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Search, pick multiple technicians, or collapse the list when done.',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.enabled)
                    TextButton.icon(
                      onPressed: _isOpen ? () => _closePicker() : _openPicker,
                      icon: Icon(
                        _isOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                      ),
                      label: Text(_isOpen ? 'Close' : 'Open'),
                    ),
                ],
              ),
              if (selectedItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tech in selectedItems)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF172554)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.engineering_outlined,
                              size: 14,
                              color: AppColors.blue600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tech.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: widget.enabled
                                  ? () => _remove(tech.id)
                                  : null,
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: AppColors.blue600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                onTap: _openPicker,
                onChanged: (value) => setState(() {
                  _query = value;
                  _isOpen = true;
                }),
                onTapOutside: (_) => _focusNode.unfocus(),
                decoration: InputDecoration(
                  hintText: widget.selectedIds.isEmpty
                      ? 'Search technicians...'
                      : 'Add more technicians...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: !_isOpen && _controller.text.trim().isEmpty
                      ? const Icon(Icons.unfold_more_rounded, size: 18)
                      : _controller.text.trim().isNotEmpty && widget.enabled
                      ? IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                            _focusNode.requestFocus();
                          },
                          icon: const Icon(Icons.close, size: 18),
                        )
                      : IconButton(
                          tooltip: 'Close',
                          onPressed: () => _closePicker(),
                          icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                          ),
                        ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  filtered.isEmpty
                                      ? 'No matches'
                                      : '${filtered.length} technician${filtered.length == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _closePicker(),
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      widget.items.isEmpty
                                          ? 'No technicians available'
                                          : 'No more technicians to add',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, index) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final tech = filtered[index];
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: widget.enabled
                                          ? () => _add(tech.id)
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).dividerColor
                                              .withValues(alpha: 0.12)
                                              .withValues(alpha: 0.04),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFFDBEAFE),
                                                    Color(0xFFF0F9FF),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.engineering_outlined,
                                                size: 18,
                                                color: AppColors.blue600,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tech.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  if (tech.phone
                                                      .trim()
                                                      .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      tech.phone,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Theme.of(
                                                          context,
                                                        ).hintColor,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.add_circle_outline,
                                              size: 18,
                                              color: AppColors.blue600,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                crossFadeState: showList
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                sizeCurve: Curves.easeOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JobsSkeleton extends StatelessWidget {
  const _JobsSkeleton();

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
          const AppCard(child: ShimmerBox(height: 120)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SearchableDropdownString extends StatefulWidget {
  const _SearchableDropdownString({
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
    this.allowNull = false,
    this.nullLabel = '— Please select —',
  });

  final String label;
  final String? value;
  final List<({String value, String label})> items;
  final bool enabled;
  final bool allowNull;
  final String nullLabel;
  final ValueChanged<String?> onChanged;

  @override
  State<_SearchableDropdownString> createState() =>
      _SearchableDropdownStringState();
}

class _AsyncSearchableClientDropdown extends StatefulWidget {
  const _AsyncSearchableClientDropdown({
    required this.label,
    required this.value,
    required this.initialItems,
    required this.enabled,
    required this.searchClients,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<({int id, String name})> initialItems;
  final bool enabled;
  final Future<List<({int id, String name})>> Function(String query)
  searchClients;
  final ValueChanged<int?> onChanged;

  @override
  State<_AsyncSearchableClientDropdown> createState() =>
      _AsyncSearchableClientDropdownState();
}

class _AsyncSearchableClientDropdownState
    extends State<_AsyncSearchableClientDropdown> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  List<({int id, String name})> _items = const [];
  Timer? _debounce;
  int _requestToken = 0;
  bool _loading = false;
  bool _open = false;
  bool _suppressTextListener = false;

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems;
    _controller = TextEditingController(text: _selectedLabel(widget.value));
    _focusNode = FocusNode();
    _controller.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(covariant _AsyncSearchableClientDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.initialItems, widget.initialItems) &&
        _controller.text.trim().isEmpty) {
      _items = widget.initialItems;
    }

    if (oldWidget.value != widget.value) {
      final label = _selectedLabel(widget.value);
      if (label.isNotEmpty && _controller.text != label) {
        _controller.text = label;
        _controller.selection = TextSelection.collapsed(offset: label.length);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    if (_suppressTextListener) return;
    if (!mounted) return;
    final query = _controller.text.trim();
    if (query.isEmpty) {
      widget.onChanged(null);
      setState(() {
        _items = widget.initialItems;
        _loading = false;
        _open = _focusNode.hasFocus;
      });
      return;
    }

    widget.onChanged(null);
    setState(() => _open = true);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(_loadClients(query));
    });
  }

  Future<void> _loadClients(String query) async {
    final token = ++_requestToken;
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await widget.searchClients(query);
      if (!mounted || token != _requestToken) return;
      setState(() {
        _items = results;
        _loading = false;
        _open = _focusNode.hasFocus || query.trim().isNotEmpty;
      });
    } catch (_) {
      if (!mounted || token != _requestToken) return;
      setState(() => _loading = false);
    }
  }

  String _selectedLabel(int? value) {
    if (value == null) return '';
    for (final item in [...widget.initialItems, ..._items]) {
      if (item.id == value) return item.name;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: divider),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2),
    );

    final query = _controller.text.trim().toLowerCase();
    final visibleItems = query.isEmpty
        ? _items
        : _items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          onTap: () => setState(() => _open = true),
          onSubmitted: (_) => _focusNode.unfocus(),
          decoration: InputDecoration(
            hintText: 'Type to search clients',
            isDense: false,
            filled: true,
            fillColor: isDark
                ? const Color(0xFF0B1220)
                : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: baseBorder,
            enabledBorder: baseBorder,
            focusedBorder: focusedBorder,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_controller.text.trim().isNotEmpty && widget.enabled)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: () {
                      _debounce?.cancel();
                      _suppressTextListener = true;
                      _controller.clear();
                      _suppressTextListener = false;
                      widget.onChanged(null);
                      setState(() {
                        _items = widget.initialItems;
                        _open = true;
                      });
                      _focusNode.requestFocus();
                    },
                    icon: const Icon(Icons.close, size: 18),
                  ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: divider),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _loading
                                ? 'Searching clients...'
                                : visibleItems.isEmpty
                                ? 'No matches'
                                : '${visibleItems.length} client${visibleItems.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _focusNode.unfocus();
                            setState(() => _open = false);
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loading && visibleItems.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : visibleItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _controller.text.trim().isEmpty
                                    ? 'Start typing a client name'
                                    : 'No clients found for this search',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: visibleItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];
                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  _debounce?.cancel();
                                  widget.onChanged(item.id);
                                  _suppressTextListener = true;
                                  _controller.text = item.name;
                                  _controller.selection =
                                      TextSelection.collapsed(
                                        offset: item.name.length,
                                      );
                                  _suppressTextListener = false;
                                  setState(() => _open = false);
                                  _focusNode.unfocus();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          crossFadeState: _open
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}

class _SearchableDropdownStringState extends State<_SearchableDropdownString> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _selectedLabel(widget.value));
    _focusNode = FocusNode();
    _controller.addListener(_syncSelectionFromText);
  }

  @override
  void didUpdateWidget(covariant _SearchableDropdownString oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final label = _selectedLabel(widget.value);
      if (label.isNotEmpty && _controller.text != label) {
        _controller.text = label;
        _controller.selection = TextSelection.collapsed(offset: label.length);
      } else if (widget.value == null &&
          widget.allowNull &&
          _controller.text.isEmpty) {
        // keep blank state in sync
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncSelectionFromText);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncSelectionFromText() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      widget.onChanged(null);
      return;
    }

    final matches = widget.items
        .where((item) => item.label.trim().toLowerCase() == text.toLowerCase())
        .toList(growable: false);

    if (matches.length == 1) {
      widget.onChanged(matches.single.value);
    } else {
      widget.onChanged(null);
    }
  }

  String _selectedLabel(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return '';
    for (final item in widget.items) {
      if (item.value == v) return item.label;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final divider = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: divider),
    );

    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        RawAutocomplete<({String value, String label})>(
          textEditingController: _controller,
          focusNode: _focusNode,
          displayStringForOption: (option) => option.label,
          optionsBuilder: (TextEditingValue value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return widget.items;
            return widget.items.where(
              (item) => item.label.toLowerCase().contains(query),
            );
          },
          onSelected: (option) {
            _controller.text = option.label;
            _controller.selection = TextSelection.collapsed(
              offset: option.label.length,
            );
            widget.onChanged(option.value);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textController,
                  builder: (context, value, _) {
                    return TextField(
                      controller: textController,
                      focusNode: focusNode,
                      enabled: widget.enabled,
                      onSubmitted: (_) {
                        onFieldSubmitted();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        hintText: widget.allowNull
                            ? 'Type to search or leave blank'
                            : 'Type to search',
                        isDense: false,
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0B1220)
                            : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        border: baseBorder,
                        enabledBorder: baseBorder,
                        focusedBorder: focusedBorder,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (value.text.trim().isNotEmpty && widget.enabled)
                              IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  textController.clear();
                                  widget.onChanged(null);
                                  _focusNode.requestFocus();
                                },
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SizedBox(
                  width: 360,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length + (widget.allowNull ? 1 : 0),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      if (widget.allowNull) {
                        if (index == 0) {
                          return ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(widget.nullLabel),
                            onTap: () {
                              _controller.clear();
                              widget.onChanged(null);
                              Navigator.of(context).maybePop();
                            },
                          );
                        }
                        index -= 1;
                      }
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          option.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
