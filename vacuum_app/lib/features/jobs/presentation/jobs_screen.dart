import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../amc/data/amc_repository.dart';
import '../../amc/domain/amc_contract.dart';
import '../../clients/data/clients_repository.dart';
import '../../technicians/data/technicians_repository.dart';
import '../application/jobs_notifier.dart';
import '../domain/job.dart';
import 'close_job_sheet.dart';

const _statuses = ['Raised', 'Assigned', 'In Progress', 'Closed'];
const _priorities = ['Low', 'Medium', 'High', 'Critical'];
const _categories = ['Maintenance', 'Repair', 'Installation', 'Inspection'];

const _statusBorderColor = <String, Color>{
  'Raised': AppColors.purple500,
  'Assigned': AppColors.blue500,
  'In Progress': AppColors.amber500,
  'Closed': AppColors.emerald500,
};

const _statusFlow = <String, String>{
  'Raised': 'Assigned',
  'Assigned': 'In Progress',
  'In Progress': 'Closed',
};

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canRaise = !['technician', 'labour'].contains(role);

    final state = ref.watch(jobsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.read(jobsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Visit Scheduled',
              subtitle: state.whenOrNull(
                data: (d) =>
                    '${d.items.where((j) => j.status != "Closed").length} active orders',
              ),
              action: canRaise
                  ? AppButton(
                      label: 'Raise Job',
                      onPressed: () => context.push('/jobs/new'),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _JobsSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: e.toString(),
              ),
              data: (data) {
                final counts = <String, int>{
                  for (final s in _statuses)
                    s: data.items.where((j) => j.status == s).length,
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        onTap: (id) => context.go('/jobs/$id'),
                        onAdvance: (job) =>
                            _advanceOrClose(context, ref, job, canRaise),
                      )
                    else
                      _FilteredListView(
                        jobs: data.items,
                        canRaise: canRaise,
                        onTap: (id) => context.go('/jobs/$id'),
                        onAdvance: (job) =>
                            _advanceOrClose(context, ref, job, canRaise),
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

class _KanbanAllView extends StatelessWidget {
  const _KanbanAllView({
    required this.jobs,
    required this.canRaise,
    required this.onTap,
    required this.onAdvance,
  });

  final List<Job> jobs;
  final bool canRaise;
  final ValueChanged<String> onTap;
  final ValueChanged<Job> onAdvance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final status in _statuses) ...[
          _StatusSection(
            status: status,
            items: jobs.where((j) => j.status == status).toList(),
            canRaise: canRaise,
            onTap: onTap,
            onAdvance: onAdvance,
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
    required this.onTap,
    required this.onAdvance,
  });

  final String status;
  final List<Job> items;
  final bool canRaise;
  final ValueChanged<String> onTap;
  final ValueChanged<Job> onAdvance;

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
                  onTap: () => onTap(job.id),
                  onAdvance: () => onAdvance(job),
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
    required this.onTap,
    required this.onAdvance,
  });

  final List<Job> jobs;
  final bool canRaise;
  final ValueChanged<String> onTap;
  final ValueChanged<Job> onAdvance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final job in jobs) ...[
          _JobCardHorizontal(
            job: job,
            canRaise: canRaise,
            onTap: () => onTap(job.id),
            onAdvance: () => onAdvance(job),
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
    required this.onTap,
    required this.onAdvance,
  });

  final Job job;
  final bool canRaise;
  final VoidCallback onTap;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final border = _statusBorderColor[job.status] ?? AppColors.gray200;
    return AppCard(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: border, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const Spacer(),
                StatusBadge(label: job.priority),
                if (canRaise && job.status != 'Closed') ...[
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Advance status',
                    onPressed: onAdvance,
                    icon: const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: AppColors.blue600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              job.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _MetaRow(
              icon: Icons.groups_outlined,
              text: job.clientName.isNotEmpty ? job.clientName : '—',
            ),
            _MetaRow(
              icon: Icons.engineering_outlined,
              text: job.technicianName.isNotEmpty
                  ? job.technicianName
                  : 'Unassigned',
            ),
            _MetaRow(
              icon: Icons.calendar_today_outlined,
              text: _shortDate(job.scheduledDate) ?? '—',
            ),
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
    required this.onTap,
    required this.onAdvance,
  });

  final Job job;
  final bool canRaise;
  final VoidCallback onTap;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final border = _statusBorderColor[job.status] ?? AppColors.gray200;
    return AppCard(
      onTap: onTap,
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(label: job.status),
                const SizedBox(height: 6),
                Text(
                  '₹${job.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (canRaise && job.status != 'Closed') ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Advance status',
                onPressed: onAdvance,
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: AppColors.blue600,
                ),
              ),
            ],
          ],
        ),
      ),
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

String? _shortDate(String? iso) {
  if (iso == null) return null;
  final v = iso.trim();
  if (v.isEmpty) return null;
  return v.length >= 10 ? v.substring(0, 10) : v;
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
  DateTime? _scheduledDate;

  int? _clientId;
  int? _techId;
  String? _amcId;
  String _priority = _priorities[1];
  String _category = _categories.first;

  List<({int id, String name})> _clients = const [];
  List<({int id, String name})> _techs = const [];
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
      _techs = [for (final t in techs) (id: t.id, name: t.name)];
      _amcContracts = amcContracts;
      if (_clients.isNotEmpty) _clientId ??= _clients.first.id;
    } catch (_) {
      // ignore - will show empty dropdown
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
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

    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'title': _title.text.trim(),
      'client_id': _clientId,
      'priority': _priority,
      'category': _category,
      if (_techId != null) 'technician_id': _techId,
      if (_amcId != null && _amcId!.trim().isNotEmpty) 'amc_id': _amcId,
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (_scheduledDate != null)
        'scheduled_date': _scheduledDate!.toIso8601String().substring(0, 10),
      if (num.tryParse(_amount.text.trim()) != null)
        'amount': num.parse(_amount.text.trim()),
    };

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
              _dropdownInt(
                label: 'Client *',
                value: _clientId,
                items: _clients,
                onChanged: (v) {
                  setState(() {
                    _clientId = v;
                  });
                },
              ),
              const SizedBox(height: 12),
              _dropdownInt(
                label: 'Assign Technician',
                value: _techId,
                allowNull: true,
                items: _techs,
                onChanged: (v) => setState(() => _techId = v),
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
              _datePicker(context),
              const SizedBox(height: 12),
              _field(
                'Amount (₹)',
                _amount,
                hint: '12000',
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _dropdownAmc(
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

  Widget _dropdownInt({
    required String label,
    required int? value,
    required List<({int id, String name})> items,
    required ValueChanged<int?> onChanged,
    bool allowNull = false,
  }) {
    return AppDropdownField<int>(
      label: label,
      value: value,
      allowNull: allowNull,
      nullLabel: '— Please select —',
      items: [
        for (final o in items) AppDropdownItem(value: o.id, label: o.name),
      ],
      enabled: !_loading,
      onChanged: onChanged,
    );
  }

  Widget _dropdownAmc({
    required String label,
    required String? value,
    required List<AmcContract> items,
    required ValueChanged<String?> onChanged,
  }) {
    return AppDropdownField<String>(
      label: label,
      value: (value?.trim().isEmpty ?? true) ? null : value,
      allowNull: true,
      nullLabel: '— Not linked to an AMC —',
      items: [for (final a in items) AppDropdownItem(value: a.id, label: _amcLabel(a))],
      enabled: !_loading,
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
          color: Theme.of(context).dividerColor.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if ((a.poNumber ?? '').trim().isNotEmpty)
          chip('PO: ${a.poNumber}', bg: const Color(0xFFF5F3FF), fg: const Color(0xFF6D28D9)),
        chip(a.status, bg: statusBg, fg: statusFg),
        if ((a.endDate ?? '').trim().isNotEmpty)
          chip(
            'Expires: ${_shortDate(a.endDate!)}',
            fg: AppColors.gray500,
          ),
      ],
    );
  }

  static String _amcLabel(AmcContract a) {
    final po = (a.poNumber ?? '').trim().isEmpty ? '' : ' | PO: ${a.poNumber}';
    final client =
        a.clientName.trim().isEmpty ? '' : ' — ${a.clientName.trim()}';
    return '${a.id}$po — ${a.title}$client';
  }

  static String _shortDate(String v) => v.length >= 10 ? v.substring(0, 10) : v;

  Widget _datePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scheduled Date',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _scheduledDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _scheduledDate = picked);
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
                Text(
                  _scheduledDate != null
                      ? _scheduledDate!.toIso8601String().substring(0, 10)
                      : 'Select date',
                  style: TextStyle(
                    color: _scheduledDate != null ? null : AppColors.gray400,
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
