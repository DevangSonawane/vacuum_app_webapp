import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../erp/application/erp_quotations_notifier.dart';
import '../../erp/domain/erp_quotation.dart';

final _inr0 = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class ErpQuotationDetailScreen extends ConsumerStatefulWidget {
  const ErpQuotationDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ErpQuotationDetailScreen> createState() =>
      _ErpQuotationDetailScreenState();
}

class _ErpQuotationDetailScreenState
    extends ConsumerState<ErpQuotationDetailScreen> {
  Future<ErpQuotation?>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(erpQuotationsProvider.notifier).fetchDetail(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ErpQuotation?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PageLoader(message: 'Loading quotation...');
        }

        final quotation = snapshot.data;
        if (quotation == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EmptyState(
                      icon: Icons.description_outlined,
                      title: 'Quotation not found',
                      description: 'We could not load this quotation.',
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Go Back',
                      variant: AppButtonVariant.secondary,
                      leading: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppButton(
                        label: 'Back',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.sm,
                        leading: const Icon(Icons.arrow_back),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          quotation.subject.isEmpty
                              ? 'Quotation Detail'
                              : quotation.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [AppColors.blue600, Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                                child: const Icon(
                                  Icons.request_quote_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      quotation.quotNo.isEmpty
                                          ? quotation.id
                                          : quotation.quotNo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      quotation.customerName.isEmpty
                                          ? 'Customer not linked'
                                          : quotation.customerName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
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
                                    _inr0.format(quotation.totalAmount),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total amount',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
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
                              StatusBadge(
                                label: quotation.status.isEmpty
                                    ? 'Approved'
                                    : quotation.status,
                              ),
                              if (quotation.priority.isNotEmpty)
                                _HeroChip(label: quotation.priority),
                              if (quotation.enquiryNo.isNotEmpty)
                                _HeroChip(
                                  label: 'Enquiry ${quotation.enquiryNo}',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Quotation Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _kv(context, 'Quot ID', quotation.quotId.toString()),
                          const SizedBox(height: 10),
                          _kv(context, 'Enquiry No', quotation.enquiryNo),
                          const SizedBox(height: 10),
                          _kv(
                            context,
                            'Client ID',
                            quotation.clientIdText.isEmpty
                                ? 'Not linked'
                                : quotation.clientIdText,
                          ),
                          const SizedBox(height: 10),
                          _kv(
                            context,
                            'Kind Attention',
                            quotation.kindAttention ?? '',
                          ),
                          const SizedBox(height: 10),
                          _kv(context, 'Date', quotation.date),
                          const SizedBox(height: 10),
                          _kv(context, 'Enquiry Date', quotation.enquiryDate),
                          const SizedBox(height: 10),
                          _kv(context, 'Priority', quotation.priority),
                          const SizedBox(height: 10),
                          _kv(context, 'Category', quotation.category),
                          const SizedBox(height: 10),
                          _kv(context, 'Prepared By', quotation.preparedBy),
                          const SizedBox(height: 10),
                          _kv(context, 'Entered By', quotation.enteredBy),
                          const SizedBox(height: 10),
                          _kv(
                            context,
                            'Financial Year',
                            quotation.validUntil ?? '—',
                          ),
                          if (quotation.authorization != null) ...[
                            const SizedBox(height: 14),
                            Divider(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.14),
                            ),
                            const SizedBox(height: 12),
                            _kv(
                              context,
                              'Auth 1',
                              _authValue(
                                quotation.authorization!.auth1Status,
                                quotation.authorization!.auth1By,
                                quotation.authorization!.auth1Date,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _kv(
                              context,
                              'Auth 2',
                              _authValue(
                                quotation.authorization!.auth2Status,
                                quotation.authorization!.auth2By,
                                quotation.authorization!.auth2Date,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Customer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final clientId = quotation.clientId;
                      if (clientId != null) {
                        context.push('/clients/$clientId');
                      }
                    },
                    child: AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Client',
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    quotation.customerName.isEmpty
                                        ? '—'
                                        : quotation.customerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.blue600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in quotation.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description.isEmpty
                                    ? '—'
                                    : item.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '${item.quantity} × ${_inr0.format(item.rate)}',
                                    style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _inr0.format(item.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(BuildContext context, String label, String value) {
    final v = value.trim().isEmpty ? '—' : value.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  String _authValue(String status, String by, String date) {
    final parts = <String>[
      if (status.trim().isNotEmpty) status.trim(),
      if (by.trim().isNotEmpty) by.trim(),
      if (date.trim().isNotEmpty) date.trim(),
    ];
    return parts.isEmpty ? '—' : parts.join(' • ');
  }
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
