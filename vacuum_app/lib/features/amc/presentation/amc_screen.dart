import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/revenue.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../clients/data/clients_repository.dart';
import '../application/amc_notifier.dart';
import '../domain/amc_contract.dart';

const _amcStatuses = ['Active', 'Expiring Soon', 'Expired'];

const _statusGrad = <String, List<Color>>{
  'Active': [AppColors.blue500, AppColors.blue600],
  'Expiring Soon': [AppColors.orange500, Color(0xFFEA580C)],
  'Expired': [AppColors.gray400, AppColors.gray500],
};

class AmcScreen extends ConsumerWidget {
  const AmcScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        onPressed: () => _openFormSheet(context, ref, null),
                      )
                    : null,
              ),
              error: (e, _) => SectionHeader(
                title: 'AMC Contracts',
                subtitle: e.toString(),
                action: canEdit
                    ? AppButton(
                        label: 'Add Contract',
                        onPressed: () => _openFormSheet(context, ref, null),
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
                          onPressed: () => _openFormSheet(context, ref, null),
                        )
                      : null,
                );
              },
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _AmcSkeleton(),
              error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Failed to load', description: e.toString()),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterTabs(
                    value: data.statusFilter,
                    onChanged: (s) => ref.read(amcProvider.notifier).setFilter(s),
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

  Future<void> _openFormSheet(BuildContext context, WidgetRef ref, AmcContract? existing) async {
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
            message: ok ? (isEdit ? 'Contract updated!' : 'Contract created!') : 'Operation failed',
            type: ok ? AppToastType.success : AppToastType.error,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AmcContract c) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Contract',
      body: 'Are you sure you want to delete ${c.title}? This cannot be undone.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: value == t ? (isDark ? AppColors.gray800 : const Color(0xFFDBEAFE)) : Colors.transparent,
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.16)),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: value == t ? (isDark ? Colors.white : AppColors.blue600) : Theme.of(context).hintColor,
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
    final grad = _statusGrad[contract.status] ?? [AppColors.gray400, AppColors.gray500];
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
                child: const Icon(Icons.verified_user_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(contract.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(contract.clientName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : AppColors.gray100,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
          if ((contract.nextServiceDate ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.gray400),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Next service: ${_shortDate(contract.nextServiceDate)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray500),
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
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111827) : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
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
            item('Reminder', '${contract.renewalReminderDays} days'),
          ],
        ),
      ],
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
  });

  final Dio dio;
  final AmcContract? existing;
  final Future<void> Function(Map<String, dynamic> payload, bool isEdit, String? id) onSubmit;

  @override
  State<_AmcFormSheet> createState() => _AmcFormSheetState();
}

class _AmcFormSheetState extends State<_AmcFormSheet> {
  final _title = TextEditingController();
  final _value = TextEditingController();
  final _reminder = TextEditingController(text: '30');
  final _services = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  DateTime? _nextService;

  bool _loading = false;
  bool _fetching = true;

  int? _clientId;
  List<({int id, String name})> _clients = const [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _value.text = e.value.toString();
      _reminder.text = e.renewalReminderDays.toString();
      _services.text = e.services.join(', ');
      _start = _parse(e.startDate);
      _end = _parse(e.endDate);
      _nextService = _parse(e.nextServiceDate);
      _clientId = e.clientId;
    }
    _loadClients();
  }

  @override
  void dispose() {
    _title.dispose();
    _value.dispose();
    _reminder.dispose();
    _services.dispose();
    super.dispose();
  }

  DateTime? _parse(String? iso) => iso == null ? null : DateTime.tryParse(iso);

  Future<void> _loadClients() async {
    setState(() => _fetching = true);
    try {
      final repo = ClientsRepository(dio: widget.dio);
      final clients = await repo.fetchClients(search: '', type: '');
      _clients = [for (final c in clients) (id: c.id, name: c.name)];
      _clientId ??= _clients.isNotEmpty ? _clients.first.id : null;
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_clientId == null || _title.text.trim().isEmpty || _start == null || _end == null || _value.text.trim().isEmpty) {
      AppToast.show(context, message: 'Client, title, start/end dates and value are required.', type: AppToastType.error);
      return;
    }

    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'client_id': _clientId,
      'title': _title.text.trim(),
      'start_date': _start!.toIso8601String().substring(0, 10),
      'end_date': _end!.toIso8601String().substring(0, 10),
      'value': num.tryParse(_value.text.trim()) ?? 0,
      'renewal_reminder_days': int.tryParse(_reminder.text.trim()) ?? 30,
      'services': _services.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      if (_nextService != null) 'next_service_date': _nextService!.toIso8601String().substring(0, 10),
    };

    await widget.onSubmit(payload, _isEdit, widget.existing?.id);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Edit Contract' : 'Add Contract', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_fetching)
              const AppCard(child: ShimmerBox(height: 120))
            else ...[
              _dropdownClient(),
              const SizedBox(height: 12),
              _field('Title *', _title, hint: 'Annual Maintenance'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _datePicker(context, 'Start Date *', _start, (v) => setState(() => _start = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _datePicker(context, 'End Date *', _end, (v) => setState(() => _end = v))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('Value (₹) *', _value, hint: '250000', keyboard: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Reminder Days', _reminder, hint: '30', keyboard: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              _field('Services (comma-separated)', _services, hint: 'Quarterly visit, Filter change', lines: 2),
              const SizedBox(height: 12),
              _datePicker(context, 'Next Service Date', _nextService, (v) => setState(() => _nextService = v)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      expanded: true,
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _dropdownClient() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Client *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: _clientId,
          decoration: const InputDecoration(isDense: true),
          items: _clients.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: _loading ? null : (v) => setState(() => _clientId = v),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboard, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

  Widget _datePicker(BuildContext context, String label, DateTime? value, ValueChanged<DateTime?> onPicked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (picked != null) onPicked(picked);
                },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? const Color(0xFF374151) : AppColors.gray200),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF0B1220) : AppColors.gray50,
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.gray400),
                const SizedBox(width: 8),
                Text(
                  value != null ? value.toIso8601String().substring(0, 10) : 'Select date',
                  style: TextStyle(color: value != null ? null : AppColors.gray400),
                ),
              ],
            ),
          ),
        ),
      ],
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

