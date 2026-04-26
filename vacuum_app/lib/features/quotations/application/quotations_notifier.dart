import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quotation.dart';

final quotationsProvider =
    StateNotifierProvider<QuotationsNotifier, List<Quotation>>(
      (ref) => QuotationsNotifier(),
    );

class QuotationsNotifier extends StateNotifier<List<Quotation>> {
  QuotationsNotifier() : super(_seed);

  static final List<Quotation> _seed = [
    Quotation(
      id: 'QT-001',
      clientId: 1,
      clientName: 'TechCorp Solutions',
      title: 'Annual HVAC Contract',
      amount: 180000,
      status: 'Approved',
      validTill: '2024-03-31',
      createdDate: '2024-01-01',
      items: const [
        QuotationItem(
          description: 'HVAC Servicing (4 units)',
          qty: 4,
          rate: 18000,
          total: 72000,
        ),
        QuotationItem(
          description: 'Filter Replacement',
          qty: 12,
          rate: 2000,
          total: 24000,
        ),
        QuotationItem(
          description: 'Emergency Callouts (12)',
          qty: 12,
          rate: 7000,
          total: 84000,
        ),
      ],
    ),
    Quotation(
      id: 'QT-002',
      clientId: 3,
      clientName: 'City Mall Group',
      title: 'Electrical Upgrade Package',
      amount: 245000,
      status: 'Pending',
      validTill: '2024-02-28',
      createdDate: '2024-01-12',
      items: const [
        QuotationItem(
          description: 'Panel Upgrade',
          qty: 1,
          rate: 45000,
          total: 45000,
        ),
        QuotationItem(
          description: 'Wiring Replacement',
          qty: 1,
          rate: 150000,
          total: 150000,
        ),
        QuotationItem(
          description: 'Safety Audit',
          qty: 1,
          rate: 50000,
          total: 50000,
        ),
      ],
    ),
    Quotation(
      id: 'QT-003',
      clientId: 5,
      clientName: 'Horizon Hospitals',
      title: 'Full Facility Management',
      amount: 1200000,
      status: 'Approved',
      validTill: '2024-12-31',
      createdDate: '2024-01-05',
      items: const [
        QuotationItem(
          description: 'Monthly Maintenance',
          qty: 12,
          rate: 80000,
          total: 960000,
        ),
        QuotationItem(
          description: 'Emergency Services',
          qty: 1,
          rate: 240000,
          total: 240000,
        ),
      ],
    ),
  ];

  void addQuotation({
    required int clientId,
    required String clientName,
    required String title,
    required String? validTill,
    required List<QuotationItem> items,
  }) {
    final totalAmount = items.fold<num>(0, (p, e) => p + e.total);
    final id =
        'QT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final created = DateTime.now().toIso8601String().substring(0, 10);
    state = [
      Quotation(
        id: id,
        clientId: clientId,
        clientName: clientName,
        title: title,
        amount: totalAmount,
        status: 'Pending',
        validTill: validTill,
        createdDate: created,
        items: items,
      ),
      ...state,
    ];
  }

  void updateStatus(String id, String status) {
    state = [
      for (final q in state)
        if (q.id == id) q.copyWith(status: status) else q,
    ];
  }
}
