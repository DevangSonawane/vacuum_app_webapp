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
                      description: 'We could not load this ERP quotation.',
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
                          quotation.customerName.isEmpty
                              ? 'ERP Quotation'
                              : quotation.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quotation.quotNo.isEmpty ? quotation.id : quotation.quotNo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              StatusBadge(
                                label: quotation.status.isEmpty
                                    ? 'Approved'
                                    : quotation.status,
                              ),
                              const Spacer(),
                              Text(
                                _inr0.format(quotation.totalAmount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _kv(context, 'Quot ID', quotation.quotId.toString()),
                          const SizedBox(height: 10),
                          _kv(context, 'Enquiry No', quotation.enquiryNo),
                          const SizedBox(height: 10),
                          _kv(context, 'Customer ID', quotation.customerId),
                          const SizedBox(height: 10),
                          _kv(context, 'Kind Attention', quotation.kindAttention ?? ''),
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
                          _kv(context, 'Financial Year', quotation.validUntil ?? '—'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final clientId = int.tryParse(quotation.customerId);
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
                            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Items',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
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
                                item.description.isEmpty ? '—' : item.description,
                                style: const TextStyle(fontWeight: FontWeight.w800),
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
                                    style: const TextStyle(fontWeight: FontWeight.w900),
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
          child: Text(
            v,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
