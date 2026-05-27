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
  final _erpSearch = TextEditingController();
  Timer? _erpDebounce;
  String _fromDate = '';
  String _toDate = '';
  int _limit = 10;

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

  Future<void> _pickDate({
    required bool isFrom,
  }) async {
    final now = DateTime.now();
    DateTime? initial;
    try {
      final raw = isFrom ? _fromDate : _toDate;
      if (raw.isNotEmpty) initial = DateTime.parse(raw);
    } catch (_) {
      initial = null;
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDate: initial ?? now,
    );
    if (picked == null) return;
    final iso = picked.toIso8601String().substring(0, 10);
    setState(() {
      if (isFrom) {
        _fromDate = iso;
      } else {
        _toDate = iso;
      }
    });
    ref.read(erpQuotationsProvider.notifier).applyFilters(
          fromDate: _fromDate,
          toDate: _toDate,
          page: 1,
          limit: _limit,
        );
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(authProvider).valueOrNull?.user?.role ?? '';
    final isAdmin = role.toLowerCase() == 'admin';
    if (!isAdmin) {
      return const EmptyState(
        icon: Icons.lock_outline,
        title: 'Access Denied',
        description: 'This page is restricted to administrators only.',
      );
    }

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
            subtitle:
                erp.whenOrNull(data: (d) => '${d.count} total quotations from ERP') ??
                    'ERP quotations',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ERP Quotations',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref
                    .read(erpQuotationsProvider.notifier)
                    .applyFilters(page: erp.valueOrNull?.page ?? 1, limit: _limit),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _erpSearch,
                  onChanged: _onErpSearch,
                  decoration: const InputDecoration(
                    hintText: 'Search by ID or Customer...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 740;
                    final statusValue = erp.valueOrNull?.status ?? 'All';

                    final statusField = AppDropdownField<String>(
                      label: 'Status',
                      value: statusValue,
                      items: const [
                        AppDropdownItem(value: 'All', label: 'All Status'),
                        AppDropdownItem(value: 'Draft', label: 'Draft'),
                        AppDropdownItem(value: 'Confirmed', label: 'Confirmed'),
                        AppDropdownItem(value: 'Cancelled', label: 'Cancelled'),
                      ],
                      onChanged: (v) => ref
                          .read(erpQuotationsProvider.notifier)
                          .applyFilters(status: v ?? 'All', page: 1),
                    );

                    final limitField = AppDropdownField<int>(
                      label: 'Limit',
                      value: _limit,
                      items: const [
                        AppDropdownItem(value: 10, label: '10'),
                        AppDropdownItem(value: 20, label: '20'),
                        AppDropdownItem(value: 50, label: '50'),
                      ],
                      onChanged: (v) {
                        final next = v ?? 10;
                        setState(() => _limit = next);
                        ref
                            .read(erpQuotationsProvider.notifier)
                            .applyFilters(page: 1, limit: next);
                      },
                    );

                    final fromBtn = AppButton(
                      label: _fromDate.isEmpty ? 'From Date' : _fromDate,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.calendar_month_outlined),
                      onPressed: () => _pickDate(isFrom: true),
                    );

                    final toBtn = AppButton(
                      label: _toDate.isEmpty ? 'To Date' : _toDate,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.calendar_month_outlined),
                      onPressed: () => _pickDate(isFrom: false),
                    );

                    final resetBtn = AppButton(
                      label: 'Reset',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.sm,
                      onPressed: () {
                        setState(() {
                          _erpSearch.clear();
                          _fromDate = '';
                          _toDate = '';
                          _limit = 10;
                        });
                        ref.read(erpQuotationsProvider.notifier).applyFilters(
                              search: '',
                              status: 'All',
                              fromDate: '',
                              toDate: '',
                              page: 1,
                              limit: 10,
                            );
                      },
                    );

                    if (narrow) {
                      return Column(
                        children: [
                          Row(children: [Expanded(child: statusField)]),
                          const SizedBox(height: 12),
                          Row(children: [Expanded(child: limitField)]),
                          const SizedBox(height: 12),
                          Row(children: [Expanded(child: fromBtn)]),
                          const SizedBox(height: 10),
                          Row(children: [Expanded(child: toBtn)]),
                          const SizedBox(height: 10),
                          Row(children: [Expanded(child: resetBtn)]),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: statusField),
                        const SizedBox(width: 12),
                        SizedBox(width: 110, child: limitField),
                        const SizedBox(width: 12),
                        fromBtn,
                        const SizedBox(width: 10),
                        toBtn,
                        const SizedBox(width: 10),
                        resetBtn,
                      ],
                    );
                  },
                ),
              ],
            ),
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
                  title: 'No quotations found',
                  description: 'Try adjusting your filters.',
                );
              }

              final start = ((data.page - 1) * data.limit) + 1;
              final end = (data.page * data.limit) > data.count
                  ? data.count
                  : (data.page * data.limit);

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Showing $start–$end of ${data.count}',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: cols == 1 ? 1.55 : 1.35,
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
                  _ErpPaginationBar(
                    page: data.page,
                    totalPages: data.totalPages,
                    totalCount: data.count,
                    limit: data.limit,
                    onPage: (p) => ref
                        .read(erpQuotationsProvider.notifier)
                        .applyFilters(page: p),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

}

class _ErpPaginationBar extends StatelessWidget {
  const _ErpPaginationBar({
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.limit,
    required this.onPage,
  });

  final int page;
  final int totalPages;
  final int totalCount;
  final int limit;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final start = ((page - 1) * limit) + 1;
    final end = (page * limit) > totalCount ? totalCount : (page * limit);

    List<int> pagesToShow() {
      if (totalPages <= 5) return [for (int i = 1; i <= totalPages; i++) i];
      final set = <int>{1, totalPages, page - 1, page, page + 1};
      final list = set.where((p) => p >= 1 && p <= totalPages).toList()..sort();
      return list;
    }

    final pages = pagesToShow();

    Widget pageButton(int p) {
      final active = p == page;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bg = active
          ? AppColors.blue600
          : (isDark ? const Color(0xFF111827) : AppColors.gray100);
      final fg =
          active ? Colors.white : (isDark ? Colors.white : AppColors.gray700);
      return InkWell(
        onTap: () => onPage(p),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            p.toString(),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: fg,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 720;
          final left = Text(
            'Showing $start to $end of $totalCount results',
            style: TextStyle(color: Theme.of(context).hintColor),
          );

          final right = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                label: 'Previous',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                leading: const Icon(Icons.chevron_left),
                onPressed: page <= 1 ? null : () => onPage(page - 1),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < pages.length; i++) ...[
                    if (i > 0 && pages[i] - pages[i - 1] > 1) ...[
                      const SizedBox(width: 10),
                      Text(
                        '...',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                      const SizedBox(width: 10),
                    ] else if (i > 0) ...[
                      const SizedBox(width: 8),
                    ],
                    pageButton(pages[i]),
                  ],
                ],
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Next',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.sm,
                leading: const Icon(Icons.chevron_right),
                onPressed: page >= totalPages ? null : () => onPage(page + 1),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 10),
                right,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: left),
              right,
            ],
          );
        },
      ),
    );
  }
}

class _ErpQuotationCard extends StatelessWidget {
  const _ErpQuotationCard({required this.quotation, required this.onTap});
  final ErpQuotation quotation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contact = (quotation.contactNo ?? '').trim().isNotEmpty
        ? quotation.contactNo!.trim()
        : quotation.customerId.trim();

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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      quotation.customerName.isEmpty
                          ? '—'
                          : quotation.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    if (contact.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        contact,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(
                label: quotation.status.isEmpty ? 'Confirmed' : quotation.status,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Date: ${_formatDate(quotation.date)}',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.emerald500,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return '—';
    try {
      final base = t.length >= 10 ? t.substring(0, 10) : t;
      final dt = DateTime.parse(base);
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
    } catch (_) {
      return t;
    }
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

// ignore: unused_element
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

// ignore: unused_element
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
