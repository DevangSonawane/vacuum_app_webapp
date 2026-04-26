class Quotation {
  const Quotation({
    required this.id,
    required this.title,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.amount,
    required this.validTill,
    required this.createdDate,
    this.items = const [],
  });

  final String id;
  final String title;
  final int clientId;
  final String clientName;
  final String status; // Pending | Approved | Rejected
  final num amount;
  final String? validTill;
  final String? createdDate;
  final List<QuotationItem> items;

  Quotation copyWith({
    String? status,
    String? clientName,
    num? amount,
    List<QuotationItem>? items,
  }) {
    return Quotation(
      id: id,
      title: title,
      clientId: clientId,
      clientName: clientName ?? this.clientName,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      validTill: validTill,
      createdDate: createdDate,
      items: items ?? this.items,
    );
  }
}

class QuotationItem {
  const QuotationItem({
    required this.description,
    required this.qty,
    required this.rate,
    required this.total,
  });

  final String description;
  final int qty;
  final num rate;
  final num total;

  QuotationItem copyWith({
    String? description,
    int? qty,
    num? rate,
    num? total,
  }) {
    return QuotationItem(
      description: description ?? this.description,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
      total: total ?? this.total,
    );
  }
}
