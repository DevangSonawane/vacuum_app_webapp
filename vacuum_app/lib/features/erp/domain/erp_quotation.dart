class ErpQuotation {
  const ErpQuotation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.status,
    required this.totalAmount,
    this.contactNo,
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
  final String? contactNo;
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

    final id = s(json['id'] ?? json['QuotNo'] ?? json['quotation_no']).trim();
    final customerId = s(
      json['customer_id'] ?? json['CustId'] ?? json['customerId'],
    ).trim();
    final customerName = s(
      json['customer_name'] ?? json['CustName'] ?? json['customerName'],
    ).trim();
    final contactNo = sn(json['ContactNo'] ?? json['contact_no']);
    final date = s(json['date'] ?? json['QuotDate']).trim();
    final validUntil = sn(json['valid_until'] ?? json['validTill']);
    final statusRaw = s(json['status']).trim();
    final status = statusRaw.isEmpty ? 'Confirmed' : statusRaw;
    final totalAmount =
        n(json['total_amount'] ?? json['TotalAmt'] ?? json['total']);

    final itemsRaw = json['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .map(ErpQuotationItem.fromJson)
            .toList()
        : const <ErpQuotationItem>[];

    return ErpQuotation(
      id: id,
      customerId: customerId,
      customerName: customerName,
      date: date,
      validUntil: validUntil,
      status: status,
      totalAmount: totalAmount,
      contactNo: contactNo,
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
      description: s(json['description'] ?? json['Desc']).trim(),
      quantity: n(json['quantity'] ?? json['Qty']),
      unitPrice: n(json['unit_price'] ?? json['Rate']),
      total: n(json['total'] ?? json['Total']),
    );
  }
}
