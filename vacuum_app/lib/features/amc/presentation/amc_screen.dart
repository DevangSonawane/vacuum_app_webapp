import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/revenue.dart';
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
import '../../clients/domain/client.dart';
import '../../clients/data/clients_repository.dart';
import '../application/amc_notifier.dart';
import '../domain/amc_contract.dart';

const _amcStatuses = ['Active', 'Expiring Soon', 'Expired'];

const _statusGrad = <String, List<Color>>{
  'Active': [AppColors.blue500, AppColors.blue600],
  'Expiring Soon': [AppColors.orange500, Color(0xFFEA580C)],
  'Expired': [AppColors.gray400, AppColors.gray500],
};

class AmcScreen extends ConsumerStatefulWidget {
  const AmcScreen({super.key});

  @override
  ConsumerState<AmcScreen> createState() => _AmcScreenState();
}

class _AmcScreenState extends ConsumerState<AmcScreen> {
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
      ref.read(amcProvider.notifier).search(query.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);

    final state = ref.watch(amcProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(amcProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            state.when(
              loading: () => SectionHeader(
                title: 'AMC Contracts',
                subtitle: 'Loading…',
                action: canEdit
                    ? AppButton(
                        label: 'Add Contract',
                        onPressed: () => context.push('/amc/new'),
                      )
                    : null,
              ),
              error: (e, _) => SectionHeader(
                title: 'AMC Contracts',
                subtitle: e.toString(),
                action: canEdit
                    ? AppButton(
                        label: 'Add Contract',
                        onPressed: () => context.push('/amc/new'),
                      )
                    : null,
              ),
              data: (d) {
                final totalValue = d.items.fold<num>(0, (p, e) => p + e.value);
                return SectionHeader(
                  title: 'AMC Contracts',
                  subtitle: fmtRevenue(totalValue),
                  action: canEdit
                      ? AppButton(
                          label: 'Add Contract',
                          onPressed: () => context.push('/amc/new'),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search contracts...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _AmcSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: e.toString(),
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterTabs(
                    value: data.statusFilter,
                    onChanged: (s) =>
                        ref.read(amcProvider.notifier).setFilter(s),
                  ),
                  const SizedBox(height: 16),
                  if (data.items.isEmpty)
                    const EmptyState(
                      icon: Icons.verified_user_outlined,
                      title: 'No contracts found',
                      description: 'Add a contract or adjust the filter.',
                    )
                  else
                    Column(
                      children: [
                        for (final c in data.items) ...[
                          _AmcCard(
                            contract: c,
                            canEdit: canEdit,
                            onEdit: () => _openFormSheet(context, ref, c),
                            onDelete: () => _confirmDelete(context, ref, c),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFormSheet(
    BuildContext context,
    WidgetRef ref,
    AmcContract? existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _AmcFormSheet(
        dio: ref.read(dioProvider),
        existing: existing,
        onSubmit: (payload, isEdit, id) async {
          final ok = isEdit && id != null
              ? await ref.read(amcProvider.notifier).updateContract(id, payload)
              : await ref.read(amcProvider.notifier).create(payload);
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: ok
                ? (isEdit ? 'Contract updated!' : 'Contract created!')
                : 'Operation failed',
            type: ok ? AppToastType.success : AppToastType.error,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AmcContract c,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Contract',
      body:
          'Are you sure you want to delete ${c.title}? This cannot be undone.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref.read(amcProvider.notifier).deleteContract(c.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Contract removed' : 'Delete failed',
      type: ok ? AppToastType.error : AppToastType.error,
    );
  }
}

class AmcCreateScreen extends ConsumerWidget {
  const AmcCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void close() {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        context.go('/amc');
      }
    }

    return _AmcFormSheet(
      asSheet: false,
      dio: ref.read(dioProvider),
      existing: null,
      onSubmit: (payload, isEdit, id) async {
        final ok = await ref.read(amcProvider.notifier).create(payload);
        if (!context.mounted) return;
        if (ok) close();
        AppToast.show(
          context,
          message: ok ? 'Contract created!' : 'Operation failed',
          type: ok ? AppToastType.success : AppToastType.error,
        );
      },
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = ['All', ..._amcStatuses];
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
                  child: Text(
                    t,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: value == t
                          ? (isDark ? Colors.white : AppColors.blue600)
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmcCard extends StatelessWidget {
  const _AmcCard({
    required this.contract,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final AmcContract contract;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final grad =
        _statusGrad[contract.status] ?? [AppColors.gray400, AppColors.gray500];
    final po = (contract.poNumber ?? '').trim();
    return AppCard(
      hover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: grad,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contract.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                    if (po.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _Pill(
                        label: 'PO $po',
                        bg: const Color(0xFFF3E8FF),
                        fg: AppColors.purple500,
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(label: contract.status),
            ],
          ),
          const SizedBox(height: 12),
          _InfoGrid(contract: contract),
          if (contract.services.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in contract.services)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF111827)
                          : AppColors.gray100,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if ((contract.nextServiceDate ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Next service: ${_shortDate(contract.nextServiceDate)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    expanded: true,
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Delete',
                    variant: AppButtonVariant.danger,
                    size: AppButtonSize.sm,
                    expanded: true,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.contract});
  final AmcContract contract;

  @override
  Widget build(BuildContext context) {
    Widget item(String label, String value) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111827)
              : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            item('Start', _shortDate(contract.startDate)),
            const SizedBox(width: 10),
            item('End', _shortDate(contract.endDate)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            item('Value', fmtRevenue(contract.value)),
            const SizedBox(width: 10),
            item(
              'Days Left',
              contract.daysLeft == null ? '—' : '${contract.daysLeft} days',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            item('Reminder', '${contract.renewalReminderDays} days'),
            const SizedBox(width: 10),
            item(
              'PO Number',
              (contract.poNumber ?? '').trim().isEmpty
                  ? '—'
                  : contract.poNumber!.trim(),
              ),
          ],
        ),
        if (contract.visitCount != null ||
            contract.pumpsCount != null ||
            contract.perPumpPrice != null ||
            contract.totalPrice != null ||
            contract.gstPercent != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              item(
                'Visit Count',
                contract.visitCount == null ? '—' : '${contract.visitCount}',
              ),
              const SizedBox(width: 10),
              item(
                'Pumps Count',
                contract.pumpsCount == null ? '—' : '${contract.pumpsCount}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              item(
                'Per Pump Price',
                contract.perPumpPrice == null
                    ? '—'
                    : fmtRevenue(contract.perPumpPrice!),
              ),
              const SizedBox(width: 10),
              item(
                'Total Price',
                contract.totalPrice == null
                    ? '—'
                    : fmtRevenue(contract.totalPrice!),
              ),
            ],
          ),
          if (contract.gstPercent != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                item('GST Percent', '${contract.gstPercent}%'),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

String _shortDate(String? iso) {
  final v = (iso ?? '').trim();
  if (v.isEmpty) return '—';
  return v.length >= 10 ? v.substring(0, 10) : v;
}

class _AmcFormSheet extends StatefulWidget {
  const _AmcFormSheet({
    required this.dio,
    required this.existing,
    required this.onSubmit,
    this.asSheet = true,
  });

  final Dio dio;
  final AmcContract? existing;
  final Future<void> Function(
    Map<String, dynamic> payload,
    bool isEdit,
    String? id,
  )
  onSubmit;
  final bool asSheet;

  @override
  State<_AmcFormSheet> createState() => _AmcFormSheetState();
}

class _AmcFormSheetState extends State<_AmcFormSheet> {
  final _title = TextEditingController();
  final _poNumber = TextEditingController();
  final _value = TextEditingController();
  final _services = TextEditingController();
  final _visitCount = TextEditingController();
  final _pumpsCount = TextEditingController();
  final _perPumpPrice = TextEditingController();
  final _totalPrice = TextEditingController();
  final _gstPercent = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  DateTime? _nextService;

  bool _loading = false;
  bool _fetching = true;

  int? _clientId;
  String _clientName = '';
  int _reminderDays = 30;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _poNumber.text = e.poNumber ?? '';
      _value.text = e.value.toString();
      _reminderDays = e.renewalReminderDays;
      _services.text = e.services.join(', ');
      _start = _parse(e.startDate);
      _end = _parse(e.endDate);
      _nextService = _parse(e.nextServiceDate);
      _clientId = e.clientId;
      _clientName = e.clientName;
      _visitCount.text = e.visitCount?.toString() ?? '';
      _pumpsCount.text = e.pumpsCount?.toString() ?? '';
      _perPumpPrice.text = e.perPumpPrice?.toString() ?? '';
      _totalPrice.text = e.totalPrice?.toString() ?? '';
      _gstPercent.text = e.gstPercent?.toString() ?? '';
    }
    _loadClients();
  }

  @override
  void dispose() {
    _title.dispose();
    _poNumber.dispose();
    _value.dispose();
    _services.dispose();
    _visitCount.dispose();
    _pumpsCount.dispose();
    _perPumpPrice.dispose();
    _totalPrice.dispose();
    _gstPercent.dispose();
    super.dispose();
  }

  DateTime? _parse(String? iso) => iso == null ? null : DateTime.tryParse(iso);

  int? _parseInt(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  num? _parseNum(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    return num.tryParse(text);
  }

  void _recalculateCommercials() {
    final pumps = _parseNum(_pumpsCount) ?? 0;
    final perPump = _parseNum(_perPumpPrice) ?? 0;
    final gst = _parseNum(_gstPercent) ?? 0;
    final total = pumps * perPump;
    final value = total + (total * (gst / 100));

    _totalPrice.text = total == 0 ? '' : total.toStringAsFixed(0);
    _value.text = value == 0 ? '' : value.toStringAsFixed(0);
  }

  Future<void> _loadClients() async {
    setState(() => _fetching = true);
    try {
      if (widget.existing != null) {
        _clientId ??= widget.existing!.clientId;
        if (_clientName.trim().isEmpty) {
          _clientName = widget.existing!.clientName;
        }
      }
    } catch (_) {
      // ignore; the searchable picker will surface its own loading state
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_clientId == null ||
        _title.text.trim().isEmpty ||
        _start == null ||
        _end == null) {
      AppToast.show(
        context,
        message: 'Client, title, start and end dates are required.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'client_id': _clientId,
      'title': _title.text.trim(),
      if (_poNumber.text.trim().isNotEmpty) 'po_number': _poNumber.text.trim(),
      'start_date': _start!.toIso8601String().substring(0, 10),
      'end_date': _end!.toIso8601String().substring(0, 10),
      if (_visitCount.text.trim().isNotEmpty)
        'visit_count': _parseInt(_visitCount),
      if (_pumpsCount.text.trim().isNotEmpty)
        'pumps_count': _parseInt(_pumpsCount),
      if (_perPumpPrice.text.trim().isNotEmpty)
        'per_pump_price': _parseNum(_perPumpPrice),
      if (_totalPrice.text.trim().isNotEmpty)
        'total_price': _parseNum(_totalPrice),
      if (_gstPercent.text.trim().isNotEmpty)
        'gst_percent': _parseNum(_gstPercent),
      'value': _parseNum(_value) ?? 0,
      'renewal_reminder_days': _reminderDays,
      'services': _services.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      if (_nextService != null)
        'next_service_date': _nextService!.toIso8601String().substring(0, 10),
    };

    await widget.onSubmit(payload, _isEdit, widget.existing?.id);
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
        context.go('/amc');
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
                    _isEdit ? 'Edit Contract' : 'Add Contract',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                _isEdit ? 'Edit Contract' : 'Add Contract',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            if (_fetching)
              const AppCard(child: ShimmerBox(height: 120))
            else ...[
              if (!_isEdit) ...[
                _InfoBanner(
                  text:
                      'On creation — confirmation email sent to client automatically.',
                ),
                const SizedBox(height: 12),
                _clientSelector(),
                const SizedBox(height: 12),
              ] else ...[
                _ReadOnlyField(label: 'Client', value: _clientName),
                const SizedBox(height: 12),
              ],
              _field('Title *', _title, hint: 'Annual Maintenance'),
              const SizedBox(height: 12),
              _field('PO Number', _poNumber, hint: 'PO-1234'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _datePicker(
                      context,
                      'Start Date *',
                      _start,
                      (v) => setState(() => _start = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _datePicker(
                      context,
                      'End Date *',
                      _end,
                      (v) => setState(() => _end = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Visit Count',
                      _visitCount,
                      hint: '12',
                      keyboard: TextInputType.number,
                      onChanged: (_) => _recalculateCommercials(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Pumps Count',
                      _pumpsCount,
                      hint: '4',
                      keyboard: TextInputType.number,
                      onChanged: (_) => _recalculateCommercials(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Per Pump Price (₹)',
                      _perPumpPrice,
                      hint: '18000',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _recalculateCommercials(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Total Price (₹)',
                      _totalPrice,
                      hint: '72000',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'GST Percent',
                      _gstPercent,
                      hint: '18',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _recalculateCommercials(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Contract Value (₹) *',
                      _value,
                      hint: '84720',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _reminderDropdown(),
              const SizedBox(height: 12),
              _field(
                'Services (comma-separated)',
                _services,
                hint: 'Quarterly visit, Filter change',
                lines: 2,
              ),
              const SizedBox(height: 12),
              _datePicker(
                context,
                'Next Service Date',
                _nextService,
                (v) => setState(() => _nextService = v),
              ),
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
                        label: _isEdit ? 'Update' : 'Create',
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
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => content(scroll),
    );
  }

  Widget _clientSelector() {
    final hasSelection = _clientId != null && _clientName.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Client *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading
              ? null
              : () async {
                  final selected = await showModalBottomSheet<_ClientChoice>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    useSafeArea: true,
                    builder: (ctx) => _ClientSearchPickerSheet(
                      dio: widget.dio,
                      initialClientId: _clientId,
                    ),
                  );
                  if (selected == null || !mounted) return;
                  setState(() {
                    _clientId = selected.id;
                    _clientName = selected.name;
                  });
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF374151)
                    : AppColors.gray200,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0B1220)
                  : AppColors.gray50,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: AppColors.gray400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasSelection ? _clientName : 'Search and select a client',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasSelection ? null : AppColors.gray400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _reminderDropdown() {
    const options = [15, 30, 60, 90];
    return AppDropdownField<int>(
      label: 'Renewal Reminder',
      value: options.contains(_reminderDays) ? _reminderDays : 30,
      items: [for (final d in options) AppDropdownItem(value: d, label: '$d days')],
      enabled: !_loading,
      onChanged: (v) => setState(() => _reminderDays = v ?? 30),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboard,
    int lines = 1,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
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
          enabled: readOnly ? true : !_loading,
          readOnly: readOnly,
          keyboardType: keyboard,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint),
          onChanged: readOnly ? null : onChanged,
        ),
      ],
    );
  }

  Widget _datePicker(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> onPicked,
  ) {
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
                    lastDate: DateTime.now().add(
                      const Duration(days: 365 * 10),
                    ),
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
                Text(
                  value != null
                      ? value.toIso8601String().substring(0, 10)
                      : 'Select date',
                  style: TextStyle(
                    color: value != null ? null : AppColors.gray400,
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

class _ClientChoice {
  const _ClientChoice({required this.id, required this.name});

  final int id;
  final String name;
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF374151)
                  : AppColors.gray200,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0B1220)
                : AppColors.gray50,
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: value.isEmpty ? AppColors.gray400 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _ClientSearchPickerSheet extends StatefulWidget {
  const _ClientSearchPickerSheet({
    required this.dio,
    required this.initialClientId,
  });

  final Dio dio;
  final int? initialClientId;

  @override
  State<_ClientSearchPickerSheet> createState() =>
      _ClientSearchPickerSheetState();
}

class _ClientSearchPickerSheetState extends State<_ClientSearchPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loading = true;
  List<Client> _clients = const [];
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialClientId;
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadClients({String search = ''}) async {
    setState(() => _loading = true);
    try {
      final repo = ClientsRepository(dio: widget.dio);
      final clients = await repo.fetchClients(limit: 100, search: search, type: '');
      if (!mounted) return;
      setState(() {
        _clients = clients;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _clients = const [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadClients(search: value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedId;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search clients by name...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.62,
              ),
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _clients.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No clients found'),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _clients.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final client = _clients[index];
                            final isSelected = selected == client.id;
                            return ListTile(
                              title: Text(
                                client.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'ID ${client.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.blue600,
                                    )
                                  : const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).pop(
                                _ClientChoice(id: client.id, name: client.name),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.blue600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.blue600,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmcSkeleton extends StatelessWidget {
  const _AmcSkeleton();

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
          const AppCard(child: ShimmerBox(height: 180)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
