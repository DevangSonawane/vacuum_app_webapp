class ErpQuotation {
  const ErpQuotation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.validUntil,
    this.currency,
    this.items = const [],
  });

  final String id;
  final String customerId;
  final String customerName;
  final String date;
  final String status;
  final num totalAmount;
  final String? validUntil;
  final String? currency;
  final List<ErpQuotationItem> items;

  static ErpQuotation fromJson(Map<String, dynamic> json) {
    String s(Object? v) => (v ?? '').toString();
    num n(Object? v) {
      if (v is num) return v;
      return num.tryParse((v ?? '').toString()) ?? 0;
    }
    String? sn(Object? v) {
      final t = (v ?? '').toString().trim();
      return t.isEmpty ? null : t;
    }

    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .map(ErpQuotationItem.fromJson)
            .toList()
        : const <ErpQuotationItem>[];

    return ErpQuotation(
      id: s(json['id']).trim(),
      customerId: s(json['customer_id']).trim(),
      customerName: s(json['customer_name']).trim(),
      date: s(json['date']).trim(),
      validUntil: sn(json['valid_until']),
      status: s(json['status']).trim().isEmpty ? 'Confirmed' : s(json['status']),
      totalAmount: n(json['total_amount']),
      currency: sn(json['currency']),
      items: items,
    );
  }
}

class ErpQuotationItem {
  const ErpQuotationItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  final String description;
  final num quantity;
  final num unitPrice;
  final num total;

  static ErpQuotationItem fromJson(Map<String, dynamic> json) {
    String s(Object? v) => (v ?? '').toString();
    num n(Object? v) {
      if (v is num) return v;
      return num.tryParse((v ?? '').toString()) ?? 0;
    }

    return ErpQuotationItem(
      description: s(json['description']).trim(),
      quantity: n(json['quantity']),
      unitPrice: n(json['unit_price']),
      total: n(json['total']),
    );
  }
}

