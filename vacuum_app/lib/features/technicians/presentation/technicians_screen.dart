import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/initials.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/shimmer_box.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/technicians_notifier.dart';
import '../domain/technician.dart';

const _specializations = ['HVAC', 'Electrical', 'Plumbing', 'Carpentry', 'Generator', 'Civil', 'IT'];
const _statuses = ['Active', 'On Leave', 'Inactive'];

class TechniciansScreen extends ConsumerStatefulWidget {
  const TechniciansScreen({super.key});

  @override
  ConsumerState<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends ConsumerState<TechniciansScreen> {
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
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(techniciansProvider.notifier).search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);
    final state = ref.watch(techniciansProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(techniciansProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Technicians',
              subtitle: state.whenOrNull(
                data: (d) =>
                    '${d.items.where((t) => t.status == "Active").length} active of ${d.items.length} total',
              ),
              action: canEdit
                  ? AppButton(
                      label: '+ Add Technician',
                      onPressed: () => _openFormSheet(context, null),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search technicians...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            state.when(
              loading: () => const _TechniciansSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: e.toString(),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.engineering_outlined,
                    title: 'No technicians found',
                    description: 'Try a different search or add a new technician.',
                  );
                }

                final width = MediaQuery.sizeOf(context).width;
                final cols = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: cols == 1 ? 2.0 : 1.4,
                  ),
                  itemCount: data.items.length,
                  itemBuilder: (context, i) {
                    final tech = data.items[i];
                    return _TechnicianCard(
                      tech: tech,
                      canEdit: canEdit,
                      onEdit: () => _openFormSheet(context, tech),
                      onDelete: () => _confirmDelete(context, tech),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFormSheet(BuildContext context, Technician? tech) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _TechnicianFormSheet(
        existing: tech,
        fetchById: tech == null ? null : () => ref.read(techniciansProvider.notifier).fetchById(tech.id),
        onSubmit: (payload, isEdit, id, password) async {
          bool ok;
          if (isEdit && id != null) {
            ok = await ref.read(techniciansProvider.notifier).updateTechnician(id, payload);
          } else {
            if (password.isNotEmpty) payload['password'] = password;
            ok = await ref.read(techniciansProvider.notifier).create(payload);
          }

          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: ok ? (isEdit ? 'Technician updated!' : 'Technician added!') : 'Operation failed',
            type: ok ? AppToastType.success : AppToastType.error,
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Technician tech) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Technician',
      body: 'Are you sure you want to remove ${tech.name}? This cannot be undone.',
      confirmLabel: 'Remove',
    );

    if (!confirmed || !context.mounted) return;
    final ok = await ref.read(techniciansProvider.notifier).delete(tech.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Technician removed' : 'Delete failed',
      type: ok ? AppToastType.error : AppToastType.error,
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  const _TechnicianCard({
    required this.tech,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final Technician tech;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBg = isDark ? const Color(0xFF111827) : AppColors.gray50;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppAvatar(initials: initialsFromName(tech.name), size: AppAvatarSize.lg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tech.specialization,
                      style: const TextStyle(
                        color: AppColors.blue600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: tech.status),
            ],
          ),
          const SizedBox(height: 10),
          if (tech.email.isNotEmpty) _ContactRow(icon: Icons.mail_outline, text: tech.email),
          _ContactRow(icon: Icons.phone_outlined, text: tech.phone),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Jobs', value: tech.jobsCompleted.toString(), bg: boxBg)),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Rating',
                  value: '★ ${tech.rating.toStringAsFixed(1)}',
                  bg: boxBg,
                  valueColor: AppColors.amber500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: 'Since',
                  value: tech.joinDate != null && tech.joinDate!.length >= 4 ? tech.joinDate!.substring(0, 4) : '—',
                  bg: boxBg,
                ),
              ),
            ],
          ),
          if (canEdit) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Edit',
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    leading: const Icon(Icons.edit_outlined),
                    expanded: true,
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  label: '',
                  variant: AppButtonVariant.danger,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

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
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.bg,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color bg;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _TechnicianFormSheet extends StatefulWidget {
  const _TechnicianFormSheet({
    required this.existing,
    required this.onSubmit,
    required this.fetchById,
  });

  final Technician? existing;
  final Future<Technician?> Function()? fetchById;
  final Future<void> Function(Map<String, dynamic> payload, bool isEdit, int? id, String password) onSubmit;

  @override
  State<_TechnicianFormSheet> createState() => _TechnicianFormSheetState();
}

class _TechnicianFormSheetState extends State<_TechnicianFormSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  String _specialization = _specializations.first;
  String _status = _statuses.first;
  DateTime? _joinDate;

  bool _loading = false;
  bool _fetchingDetails = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _name.text = t.name;
      _email.text = t.email;
      _phone.text = t.phone;
      _specialization = _specializations.contains(t.specialization) ? t.specialization : _specializations.first;
      _status = _statuses.contains(t.status) ? t.status : _statuses.first;
      _joinDate = _parseDate(t.joinDate);
      _loadLatestIfNeeded();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _loadLatestIfNeeded() async {
    final fetch = widget.fetchById;
    if (fetch == null) return;
    setState(() => _fetchingDetails = true);
    final latest = await fetch();
    if (!mounted) return;
    setState(() => _fetchingDetails = false);
    if (latest == null) return;

    _name.text = latest.name;
    _email.text = latest.email;
    _phone.text = latest.phone;
    _specialization = _specializations.contains(latest.specialization) ? latest.specialization : _specializations.first;
    _status = _statuses.contains(latest.status) ? latest.status : _statuses.first;
    _joinDate = _parseDate(latest.joinDate);
    setState(() {});
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      AppToast.show(context, message: 'Name and phone are required.', type: AppToastType.error);
      return;
    }

    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'specialization': _specialization,
      'status': _status,
      if (_joinDate != null) 'join_date': _joinDate!.toIso8601String().substring(0, 10),
    };
    await widget.onSubmit(payload, _isEdit, widget.existing?.id, _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Edit Technician' : 'Add Technician', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_fetchingDetails)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _field('Full Name *', _name, hint: 'Ravi Kumar'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Email',
                      _email,
                      hint: 'ravi@vdti.com',
                      keyboard: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Phone *',
                      _phone,
                      hint: '9876543210',
                      keyboard: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dropdown(
                      'Specialization',
                      _specialization,
                      _specializations,
                      (v) => setState(() => _specialization = v ?? _specializations.first),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dropdown(
                      'Status',
                      _status,
                      _statuses,
                      (v) => setState(() => _status = v ?? _statuses.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _datePicker(context),
              if (!_isEdit) ...[
                const SizedBox(height: 12),
                _field('Password (optional)', _password, hint: 'Leave blank if no login needed', obscure: true),
                const SizedBox(height: 4),
                Text(
                  'If provided, this technician can log in via the mobile app.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                ),
              ],
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
                      label: _isEdit ? 'Update Technician' : 'Add Technician',
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

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          enabled: !_loading,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _dropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(isDense: true),
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: _loading ? null : onChanged,
        ),
      ],
    );
  }

  Widget _datePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Join Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _loading
              ? null
              : () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _joinDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _joinDate = picked);
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
                  _joinDate != null ? _joinDate!.toIso8601String().substring(0, 10) : 'Select date',
                  style: TextStyle(color: _joinDate != null ? null : AppColors.gray400),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TechniciansSkeleton extends StatelessWidget {
  const _TechniciansSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: cols == 1 ? 2.0 : 1.4,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 48, height: 48, borderRadius: 999),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: 8),
                      SizedBox(height: 8),
                      ShimmerBox(width: 90, height: 12, borderRadius: 8),
                    ],
                  ),
                ),
                ShimmerBox(width: 54, height: 16, borderRadius: 999),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(height: 12, borderRadius: 8),
            SizedBox(height: 8),
            ShimmerBox(width: 180, height: 12, borderRadius: 8),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 44, borderRadius: 12)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 44, borderRadius: 12)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 44, borderRadius: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
