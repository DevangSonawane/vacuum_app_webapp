import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dropdown_field.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/bottom_safe_area.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/application/auth_notifier.dart';
import '../../clients/application/clients_notifier.dart';
import '../../erp/application/erp_quotations_notifier.dart';
import '../../erp/domain/erp_quotation.dart';
import '../application/quotations_notifier.dart';
import '../domain/quotation.dart';

final _inr0 = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class QuotationsScreen extends ConsumerStatefulWidget {
  const QuotationsScreen({super.key});

  @override
  ConsumerState<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends ConsumerState<QuotationsScreen> {
  int _tabIndex = 0; // 0 = Local, 1 = ERP
  final _erpSearch = TextEditingController();
  Timer? _erpDebounce;

  @override
  void dispose() {
    _erpSearch.dispose();
    _erpDebounce?.cancel();
    super.dispose();
  }

  void _onErpSearch(String q) {
    _erpDebounce?.cancel();
    _erpDebounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(erpQuotationsProvider.notifier).applyFilters(search: q, page: 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final canEdit = !['technician', 'labour'].contains(role);

    final quotations = ref.watch(quotationsProvider);
    final pending = quotations.where((q) => q.status == 'Pending').length;
    final erp = ref.watch(erpQuotationsProvider);

    final width = MediaQuery.sizeOf(context).width;
    final cols = width >= 1024 ? 3 : (width >= 720 ? 2 : 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Quotations',
            subtitle: _tabIndex == 0
                ? '$pending pending approval'
                : erp.whenOrNull(data: (d) => '${d.count} total quotations') ??
                    'ERP quotations',
            action: (_tabIndex == 0 && canEdit)
                ? AppButton(
                    label: 'New Quotation',
                    onPressed: () => context.push('/quotations/new'),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Local')),
                    ButtonSegment(value: 1, label: Text('ERP')),
                  ],
                  selected: {_tabIndex},
                  onSelectionChanged: (s) =>
                      setState(() => _tabIndex = s.first),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () {
                  if (_tabIndex == 0) return;
                  ref
                      .read(erpQuotationsProvider.notifier)
                      .applyFilters(page: erp.valueOrNull?.page ?? 1);
                },
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_tabIndex == 0) ...[
            if (quotations.isEmpty)
              const EmptyState(
                icon: Icons.currency_rupee,
                title: 'No quotations yet',
                description: 'Create a quotation for a client.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 1.8 : 1.45,
                ),
                itemCount: quotations.length,
                itemBuilder: (context, i) => _QuotationCard(
                  quotation: quotations[i],
                  canEdit: canEdit,
                  onTap: () => _openDetailSheet(context, quotations[i]),
                  onApprove: () => _changeStatus(quotations[i].id, 'Approved'),
                  onReject: () => _changeStatus(quotations[i].id, 'Rejected'),
                ),
              ),
          ] else ...[
            TextField(
              controller: _erpSearch,
              onChanged: _onErpSearch,
              decoration: const InputDecoration(
                hintText: 'Search ERP quotations...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppDropdownField<String>(
                    label: 'Status',
                    value: erp.valueOrNull?.status ?? 'All',
                    items: const [
                      AppDropdownItem(value: 'All', label: 'All'),
                      AppDropdownItem(value: 'Draft', label: 'Draft'),
                      AppDropdownItem(value: 'Confirmed', label: 'Confirmed'),
                      AppDropdownItem(value: 'Cancelled', label: 'Cancelled'),
                    ],
                    onChanged: (v) => ref
                        .read(erpQuotationsProvider.notifier)
                        .applyFilters(status: v ?? 'All', page: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            erp.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Failed to load ERP quotations',
                description: e.toString(),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No ERP quotations',
                    description: 'Try a different search or status filter.',
                  );
                }
                return Column(
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: cols == 1 ? 1.9 : 1.55,
                      ),
                      itemCount: data.items.length,
                      itemBuilder: (context, i) => _ErpQuotationCard(
                        quotation: data.items[i],
                        onTap: () async {
                          final full = await ref
                              .read(erpQuotationsProvider.notifier)
                              .fetchDetail(data.items[i].id);
                          if (!context.mounted) return;
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            useSafeArea: true,
                            builder: (_) => _ErpQuotationDetailSheet(
                              quotation: full ?? data.items[i],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ErpPager(
                      page: data.page,
                      totalPages: data.totalPages,
                      onPage: (p) => ref
                          .read(erpQuotationsProvider.notifier)
                          .applyFilters(page: p),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _changeStatus(String id, String status) {
    ref.read(quotationsProvider.notifier).updateStatus(id, status);
    AppToast.show(
      context,
      message: 'Quotation ${status.toLowerCase()}',
      type: status == 'Approved' ? AppToastType.success : AppToastType.error,
    );
  }

  Future<void> _openDetailSheet(BuildContext context, Quotation q) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _QuotationDetailSheet(quotation: q),
    );
  }
}

class _ErpPager extends StatelessWidget {
  const _ErpPager({
    required this.page,
    required this.totalPages,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: page <= 1 ? null : () => onPage(page - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Page $page of $totalPages',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
        IconButton(
          onPressed: page >= totalPages ? null : () => onPage(page + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _ErpQuotationCard extends StatelessWidget {
  const _ErpQuotationCard({required this.quotation, required this.onTap});
  final ErpQuotation quotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountText = _inr0.format(quotation.totalAmount);
    return AppCard(
      hover: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quotation.id,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: AppColors.blue600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quotation.customerName.isEmpty ? '—' : quotation.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StatusBadge(label: quotation.status),
              const Spacer(),
              Text(
                amountText,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quotation.date.isEmpty ? '—' : quotation.date,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErpQuotationDetailSheet extends StatelessWidget {
  const _ErpQuotationDetailSheet({required this.quotation});
  final ErpQuotation quotation;

  @override
  Widget build(BuildContext context) {
    final amountText = _inr0.format(quotation.totalAmount);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quotation.customerName.isEmpty ? 'ERP Quotation' : quotation.customerName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            quotation.id,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w900,
              color: AppColors.blue600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatusBadge(label: quotation.status),
              const Spacer(),
              Text(amountText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          _kv(context, 'Customer ID', quotation.customerId),
          _kv(context, 'Date', quotation.date),
          _kv(context, 'Valid Until', quotation.validUntil ?? '—'),
          if (quotation.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Items',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            for (final it in quotation.items)
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        it.description.isEmpty ? '—' : it.description,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${it.quantity} × ${_inr0.format(it.unitPrice)}',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _inr0.format(it.total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final val = v.trim().isEmpty ? '—' : v.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          Expanded(child: Text(val, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class QuotationCreateScreen extends ConsumerStatefulWidget {
  const QuotationCreateScreen({super.key});

  @override
  ConsumerState<QuotationCreateScreen> createState() =>
      _QuotationCreateScreenState();
}

class _QuotationCreateScreenState extends ConsumerState<QuotationCreateScreen> {
  List<({int id, String name})> _clients = const [];
  bool _loadingClients = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadClients());
  }

  Future<void> _loadClients() async {
    setState(() => _loadingClients = true);
    try {
      final list = await ref
          .read(clientsRepositoryProvider)
          .fetchClients(limit: 100);
      _clients = [for (final c in list) (id: c.id, name: c.name)];
    } catch (_) {
      _clients = const [];
    } finally {
      if (mounted) setState(() => _loadingClients = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    void close() {
      final r = GoRouter.of(context);
      if (r.canPop()) {
        r.pop();
      } else {
        context.go('/quotations');
      }
    }

    if (_loadingClients) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_clients.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'No clients',
            description: 'Create a client first to make a quotation.',
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Add Client',
            onPressed: () => context.go('/clients/new'),
          ),
        ],
      );
    }

    return _CreateQuotationSheet(
      asSheet: false,
      clients: _clients,
      onCreate: (clientId, clientName, title, validTill, items) {
        ref
            .read(quotationsProvider.notifier)
            .addQuotation(
              clientId: clientId,
              clientName: clientName,
              title: title,
              validTill: validTill,
              items: items,
            );
        close();
        AppToast.show(
          context,
          message: 'Quotation created!',
          type: AppToastType.success,
        );
      },
    );
  }
}

class _QuotationCard extends StatelessWidget {
  const _QuotationCard({
    required this.quotation,
    required this.canEdit,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
  });

  final Quotation quotation;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final amountText = _inr0.format(quotation.amount);

    return AppCard(
      hover: true,
      onTap: onTap,
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
                      quotation.id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                        color: AppColors.blue600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quotation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quotation.clientName,
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
              StatusBadge(label: quotation.status),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amountText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.blue600,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Valid till ${quotation.validTill ?? '—'}',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (canEdit && quotation.status == 'Pending')
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Approve',
                      onPressed: onApprove,
                      icon: const Icon(
                        Icons.check,
                        color: AppColors.emerald500,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reject',
                      onPressed: onReject,
                      icon: const Icon(Icons.close, color: AppColors.red500),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateQuotationSheet extends StatefulWidget {
  const _CreateQuotationSheet({
    required this.clients,
    required this.onCreate,
    this.asSheet = true,
  });

  final List<({int id, String name})> clients;
  final void Function(
    int clientId,
    String clientName,
    String title,
    String? validTill,
    List<QuotationItem> items,
  )
  onCreate;
  final bool asSheet;

  @override
  State<_CreateQuotationSheet> createState() => _CreateQuotationSheetState();
}

class _CreateQuotationSheetState extends State<_CreateQuotationSheet> {
  final _title = TextEditingController();
  final _validTill = TextEditingController();

  int? _clientId;
  String _clientName = '';
  List<_LineItemState> _items = [const _LineItemState()];

  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) {
      _clientId = widget.clients.first.id;
      _clientName = widget.clients.first.name;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _validTill.dispose();
    super.dispose();
  }

  num get _total => _items.fold<num>(0, (p, e) => p + e.total);

  @override
  Widget build(BuildContext context) {
    void close() {
      final r = GoRouter.of(context);
      if (r.canPop()) {
        r.pop();
      } else {
        context.go('/quotations');
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
                    onPressed: close,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'Create Quotation',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else ...[
              Text(
                'Create Quotation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(child: _clientDropdown()),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'Quotation Title *',
                    _title,
                    hint: 'Annual contract',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field('Valid Till', _validTill, hint: 'YYYY-MM-DD'),
            const SizedBox(height: 16),
            const Text(
              'Line Items',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < _items.length; i++) ...[
              _LineItemRow(
                value: _items[i],
                onChanged: (v) => setState(() => _items[i] = v),
                onRemove: _items.length > 1
                    ? () => setState(() => _items.removeAt(i))
                    : null,
              ),
              const SizedBox(height: 10),
            ],
            TextButton.icon(
              onPressed: () =>
                  setState(() => _items = [..._items, const _LineItemState()]),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item'),
            ),
            const SizedBox(height: 12),
            Divider(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 12),
            BottomSafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _inr0.format(_total),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.blue600,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'Create Quotation',
                    onPressed: () {
                      if (_clientId == null || _title.text.trim().isEmpty) {
                        AppToast.show(
                          context,
                          message: 'Client and title are required.',
                          type: AppToastType.error,
                        );
                        return;
                      }
                      final items = [
                        for (final it in _items)
                          QuotationItem(
                            description: it.description.trim(),
                            qty: it.qty,
                            rate: it.rate,
                            total: it.total,
                          ),
                      ].where((e) => e.description.isNotEmpty).toList();

                      if (items.isEmpty) {
                        AppToast.show(
                          context,
                          message: 'Add at least one line item.',
                          type: AppToastType.error,
                        );
                        return;
                      }

                      widget.onCreate(
                        _clientId!,
                        _clientName,
                        _title.text.trim(),
                        _validTill.text.trim().isEmpty
                            ? null
                            : _validTill.text.trim(),
                        items,
                      );
                    },
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
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => content(scroll),
    );
  }

  Widget _clientDropdown() {
    return AppDropdownField<int>(
      label: 'Client *',
      value: _clientId,
      items: [
        for (final c in widget.clients)
          AppDropdownItem(value: c.id, label: c.name),
      ],
      onChanged: (v) {
        setState(() {
          _clientId = v;
          _clientName = widget.clients
              .firstWhere((e) => e.id == v, orElse: () => (id: 0, name: ''))
              .name;
        });
      },
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) {
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
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final _LineItemState value;
  final ValueChanged<_LineItemState> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: TextField(
            decoration: const InputDecoration(hintText: 'Description'),
            onChanged: (v) => onChanged(value.copyWith(description: v)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            decoration: const InputDecoration(hintText: 'Qty'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(value.copyWith(qty: int.tryParse(v) ?? 1)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            decoration: const InputDecoration(hintText: 'Rate'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                onChanged(value.copyWith(rate: num.tryParse(v) ?? 0)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '₹${value.total.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.blue600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        if (onRemove != null)
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.close, color: AppColors.red500, size: 18),
          ),
      ],
    );
  }
}

class _LineItemState {
  const _LineItemState({this.description = '', this.qty = 1, this.rate = 0});

  final String description;
  final int qty;
  final num rate;

  num get total => qty * rate;

  _LineItemState copyWith({String? description, int? qty, num? rate}) {
    return _LineItemState(
      description: description ?? this.description,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
    );
  }
}

class _QuotationDetailSheet extends StatelessWidget {
  const _QuotationDetailSheet({required this.quotation});

  final Quotation quotation;

  @override
  Widget build(BuildContext context) {
    final amountText = _inr0.format(quotation.amount);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quotation.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Info(
                    label: 'ID',
                    value: quotation.id,
                    monospace: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(label: quotation.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Info(label: 'Client', value: quotation.clientName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Info(
                    label: 'Valid Till',
                    value: quotation.validTill ?? '—',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Qty')),
                  DataColumn(label: Text('Rate')),
                  DataColumn(label: Text('Total')),
                ],
                rows: [
                  for (final it in quotation.items)
                    DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              it.description,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(it.qty.toString())),
                        DataCell(Text('₹${it.rate.toStringAsFixed(0)}')),
                        DataCell(
                          Text(
                            '₹${it.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Grand Total',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      amountText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.blue600,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: monospace ? 'monospace' : null,
            color: monospace ? AppColors.blue600 : null,
          ),
        ),
      ],
    );
  }
}
