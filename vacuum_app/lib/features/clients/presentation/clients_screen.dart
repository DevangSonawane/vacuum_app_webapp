import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
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
import '../application/clients_notifier.dart';
import '../domain/client.dart';

const _typeColors = <String, (Color, Color)>{
  'Corporate': (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
  'Residential': (Color(0xFFD1FAE5), Color(0xFF065F46)),
  'Commercial': (Color(0xFFF3E8FF), Color(0xFF6B21A8)),
  'Healthcare': (Color(0xFFFEE2E2), Color(0xFF991B1B)),
  'Government': (Color(0xFFFEF3C7), Color(0xFF92400E)),
};

const _clientTypes = [
  'All',
  'Corporate',
  'Residential',
  'Commercial',
  'Healthcare',
  'Government',
];
const _clientStatuses = ['Active', 'Inactive'];

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final next = query.trim();
      ref.read(clientsProvider.notifier).filter(search: next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);

    final state = ref.watch(clientsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(clientsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Clients',
              subtitle: state.whenOrNull(
                data: (d) =>
                    '${d.items.where((c) => c.status == "Active").length} active clients',
              ),
              action: canEdit
                  ? AppButton(
                      label: '+ Add Client',
                      onPressed: () => context.push('/clients/new'),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Search clients...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            state.when(
              loading: () => const _ClientsSkeleton(),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load',
                description: e.toString(),
              ),
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeFilters(
                    value: data.typeFilter,
                    onChanged: (t) =>
                        ref.read(clientsProvider.notifier).filter(type: t),
                  ),
                  const SizedBox(height: 16),
                  if (data.items.isEmpty)
                    const EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'No clients found',
                      description:
                          'Try a different search or adjust the type filter.',
                    )
                  else
                    _ClientsGrid(
                      items: data.items,
                      canEdit: canEdit,
                      onTap: (c) => _openDetailSheet(context, c, canEdit),
                      onEdit: (c) => _openFormSheet(context, c),
                      onDelete: (c) => _confirmDelete(context, c),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFormSheet(BuildContext context, Client? existing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => _ClientFormSheet(
        existing: existing,
        onSubmit: (payload, isEdit, id) async {
          final ok = isEdit && id != null
              ? await ref
                    .read(clientsProvider.notifier)
                    .updateClient(id, payload)
              : await ref.read(clientsProvider.notifier).create(payload);
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          AppToast.show(
            context,
            message: ok
                ? (isEdit ? 'Client updated!' : 'Client added!')
                : 'Operation failed',
            type: ok ? AppToastType.success : AppToastType.error,
          );
        },
      ),
    );
  }

  Future<void> _openDetailSheet(
    BuildContext context,
    Client client,
    bool canEdit,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _ClientDetailSheet(
        client: client,
        canEdit: canEdit,
        fetch: () => ref.read(clientsProvider.notifier).fetchDetail(client.id),
        onEdit: () async {
          Navigator.of(context).pop();
          await _openFormSheet(context, client);
        },
        onDelete: () async {
          Navigator.of(context).pop();
          await _confirmDelete(context, client);
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Client client) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove Client',
      body:
          'Are you sure you want to remove ${client.name}? This cannot be undone.',
      confirmLabel: 'Remove',
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(clientsProvider.notifier).deleteClient(client.id);
    if (!context.mounted) return;
    AppToast.show(
      context,
      message: ok ? 'Client removed' : 'Delete failed',
      type: ok ? AppToastType.error : AppToastType.error,
    );
  }
}

class ClientCreateScreen extends ConsumerWidget {
  const ClientCreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ClientFormSheet(
      asSheet: false,
      existing: null,
      onSubmit: (payload, isEdit, id) async {
        final ok = await ref.read(clientsProvider.notifier).create(payload);
        if (!context.mounted) return;
        if (ok) context.pop();
        AppToast.show(
          context,
          message: ok ? 'Client added!' : 'Operation failed',
          type: ok ? AppToastType.success : AppToastType.error,
        );
      },
    );
  }
}

class _TypeFilters extends StatelessWidget {
  const _TypeFilters({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final t in _clientTypes)
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
                      fontWeight: FontWeight.w700,
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

class _ClientsGrid extends StatelessWidget {
  const _ClientsGrid({
    required this.items,
    required this.canEdit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Client> items;
  final bool canEdit;
  final ValueChanged<Client> onTap;
  final ValueChanged<Client> onEdit;
  final ValueChanged<Client> onDelete;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 720 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Slightly taller cards to avoid RenderFlex overflow on smaller heights.
        childAspectRatio: cols == 1 ? 1.30 : 1.18,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _ClientCard(
        client: items[i],
        canEdit: canEdit,
        onTap: () => onTap(items[i]),
        onEdit: () => onEdit(items[i]),
        onDelete: () => onDelete(items[i]),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.canEdit,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Client client;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeColors =
        _typeColors[client.type] ?? (AppColors.gray100, AppColors.gray700);
    return AppCard(
      hover: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [AppColors.blue500, AppColors.blue600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.apartment_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      client.contactPerson,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(label: client.status),
                  const SizedBox(height: 6),
                  _TypeChip(label: client.type, colors: typeColors),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (client.email.isNotEmpty)
            _InfoRow(icon: Icons.mail_outline, text: client.email),
          if (client.phone.isNotEmpty)
            _InfoRow(icon: Icons.phone_outlined, text: client.phone),
          if (client.address.isNotEmpty)
            _InfoRow(icon: Icons.location_on_outlined, text: client.address),
          const SizedBox(height: 10),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  fmtRevenue(client.contractValue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                client.joinDate != null && client.joinDate!.length >= 10
                    ? client.joinDate!.substring(0, 10)
                    : '—',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
              if (canEdit) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.blue600,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.red500,
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.colors});

  final String label;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

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
              maxLines: 1,
              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientDetailSheet extends StatelessWidget {
  const _ClientDetailSheet({
    required this.client,
    required this.canEdit,
    required this.fetch,
    required this.onEdit,
    required this.onDelete,
  });

  final Client client;
  final bool canEdit;
  final Future<Client?> Function() fetch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.blue600, Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          client.contactPerson,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<Client?>(
              future: fetch(),
              builder: (context, snapshot) {
                final detail = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done) {
                  return const AppCard(child: ShimmerBox(height: 140));
                }
                final stats = detail?.stats;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Total Jobs',
                            value: '${stats?.totalJobs ?? 0}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Open Jobs',
                            value: '${stats?.openJobs ?? 0}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Active AMC',
                            value: '${stats?.activeAmcCount ?? 0}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Contact',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      child: Column(
                        children: [
                          if ((detail?.email ?? client.email).isNotEmpty)
                            _DetailRow(
                              icon: Icons.mail_outline,
                              text: detail?.email ?? client.email,
                            ),
                          if ((detail?.phone ?? client.phone).isNotEmpty)
                            _DetailRow(
                              icon: Icons.phone_outlined,
                              text: detail?.phone ?? client.phone,
                            ),
                          if ((detail?.address ?? client.address).isNotEmpty)
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              text: detail?.address ?? client.address,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Contract',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Value',
                            value: fmtRevenue(
                              detail?.contractValue ?? client.contractValue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Since',
                            value: _shortDate(
                              detail?.joinDate ?? client.joinDate,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (canEdit) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Edit Client',
                              variant: AppButtonVariant.secondary,
                              expanded: true,
                              onPressed: onEdit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Delete',
                              variant: AppButtonVariant.danger,
                              expanded: true,
                              onPressed: onDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF111827)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: AppColors.blue600),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : AppColors.gray50,
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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

String _shortDate(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return '—';
  if (v.length >= 10) return v.substring(0, 10);
  return v;
}

class _ClientFormSheet extends StatefulWidget {
  const _ClientFormSheet({
    required this.existing,
    required this.onSubmit,
    this.asSheet = true,
  });

  final Client? existing;
  final Future<void> Function(
    Map<String, dynamic> payload,
    bool isEdit,
    int? id,
  )
  onSubmit;
  final bool asSheet;

  @override
  State<_ClientFormSheet> createState() => _ClientFormSheetState();
}

class _ClientFormSheetState extends State<_ClientFormSheet> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _gstNo = TextEditingController();
  final _address = TextEditingController();
  final _contractValue = TextEditingController();

  String _type = _clientTypes[1];
  String _status = _clientStatuses.first;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    if (c != null) {
      _name.text = c.name;
      _contact.text = c.contactPerson;
      _email.text = c.email;
      _phone.text = c.phone;
      _gstNo.text = c.gstNo;
      _address.text = c.address;
      _contractValue.text = c.contractValue == 0
          ? ''
          : c.contractValue.toString();
      _type = _clientTypes.contains(c.type) ? c.type : _clientTypes[1];
      _status = _clientStatuses.contains(c.status)
          ? c.status
          : _clientStatuses.first;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _email.dispose();
    _phone.dispose();
    _gstNo.dispose();
    _address.dispose();
    _contractValue.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_name.text.trim().isEmpty || _contact.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: 'Company name and contact person are required.',
        type: AppToastType.error,
      );
      return;
    }

    setState(() => _loading = true);
    final value = num.tryParse(_contractValue.text.trim()) ?? 0;
    final payload = Client(
      id: widget.existing?.id ?? 0,
      name: _name.text.trim(),
      contactPerson: _contact.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      gstNo: _gstNo.text.trim(),
      address: _address.text.trim(),
      type: _type,
      status: _status,
      contractValue: value,
      joinDate: widget.existing?.joinDate,
      stats: null,
    ).toPayload();

    await widget.onSubmit(payload, _isEdit, widget.existing?.id);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    void close() {
      final r = GoRouter.of(context);
      if (r.canPop()) {
        r.pop();
      } else {
        context.go('/clients');
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
                    _isEdit ? 'Edit Client' : 'Add Client',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                _isEdit ? 'Edit Client' : 'Add Client',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            _field('Company Name *', _name, hint: 'Acme Pvt Ltd'),
            const SizedBox(height: 12),
            _field('Contact Person *', _contact, hint: 'Rahul Sharma'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'Email',
                    _email,
                    hint: 'contact@acme.com',
                    keyboard: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'Phone',
                    _phone,
                    hint: '9876543210',
                    keyboard: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field('GST No', _gstNo, hint: '27AAECS1234F1Z5'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    'Type',
                    _type,
                    _clientTypes.skip(1).toList(),
                    (v) => setState(() => _type = v ?? _clientTypes[1]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dropdown(
                    'Status',
                    _status,
                    _clientStatuses,
                    (v) => setState(() => _status = v ?? _clientStatuses.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              'Contract Value (₹)',
              _contractValue,
              hint: '250000',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _field('Address', _address, hint: 'Full address', lines: 3),
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
                      label: _isEdit ? 'Update Client' : 'Add Client',
                      expanded: true,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.asSheet) return content(null);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.55,
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

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return AppDropdownField<String>(
      label: label,
      value: value,
      items: [for (final o in options) AppDropdownItem(value: o, label: o)],
      enabled: !_loading,
      onChanged: onChanged,
    );
  }
}

class _ClientsSkeleton extends StatelessWidget {
  const _ClientsSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 720 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Keep skeleton sizing consistent with the real cards.
        childAspectRatio: cols == 1 ? 1.30 : 1.18,
      ),
      itemCount: 6,
      itemBuilder: (context, i) => const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 44, height: 44, borderRadius: 12),
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
                ShimmerBox(width: 64, height: 16, borderRadius: 999),
              ],
            ),
            SizedBox(height: 12),
            ShimmerBox(height: 12, borderRadius: 8),
            SizedBox(height: 8),
            ShimmerBox(width: 180, height: 12, borderRadius: 8),
            SizedBox(height: 12),
            ShimmerBox(height: 1, borderRadius: 1),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ShimmerBox(height: 14, borderRadius: 8)),
                SizedBox(width: 12),
                ShimmerBox(width: 90, height: 12, borderRadius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
