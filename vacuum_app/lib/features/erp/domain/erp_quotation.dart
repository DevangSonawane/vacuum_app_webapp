class ErpQuotation {
  const ErpQuotation({
    required this.quotId,
    required this.quotNo,
    required this.enquiryNo,
    required this.enquiryId,
    required this.date,
    required this.enquiryDate,
    required this.subject,
    required this.kindAttention,
    required this.email,
    required this.customer,
    required this.clientId,
    required this.billTo,
    required this.shipTo,
    required this.priority,
    required this.category,
    required this.sector,
    required this.plant,
    required this.financialYear,
    required this.currency,
    required this.netTotal,
    required this.discountPer,
    required this.discountAmt,
    required this.gst,
    required this.preparedBy,
    required this.preparedById,
    required this.enteredBy,
    required this.enteredById,
    required this.quotationStatus,
    required this.enquiryStatus,
    required this.isAmended,
    required this.isCancelled,
    required this.versionNo,
    required this.authorization,
    required this.cancelInfo,
    this.items = const [],
  });

  final int quotId;
  final String quotNo;
  final String enquiryNo;
  final int? enquiryId;
  final String date;
  final String enquiryDate;
  final String subject;
  final String? kindAttention;
  final String email;
  final ErpParty? customer;
  final int? clientId;
  final ErpParty? billTo;
  final ErpParty? shipTo;
  final String priority;
  final String category;
  final String sector;
  final String plant;
  final String financialYear;
  final String currency;
  final num netTotal;
  final num discountPer;
  final num discountAmt;
  final ErpGst? gst;
  final String preparedBy;
  final int? preparedById;
  final String enteredBy;
  final int? enteredById;
  final String quotationStatus;
  final String enquiryStatus;
  final bool isAmended;
  final bool isCancelled;
  final int versionNo;
  final ErpAuthorization? authorization;
  final dynamic cancelInfo;
  final List<ErpQuotationItem> items;

  String get id => quotId.toString();
  String get customerId =>
      customer?.id?.toString() ?? billTo?.id?.toString() ?? '';
  String get customerName => customer?.name ?? billTo?.name ?? '';
  String get clientIdText => clientId?.toString() ?? '';
  String? get contactNo {
    final t = kindAttention?.trim() ?? '';
    if (t.isNotEmpty) return t;
    final e = email.trim();
    return e.isNotEmpty ? e : null;
  }

  String? get validUntil {
    final t = financialYear.trim();
    return t.isEmpty ? null : t;
  }

  String get status => quotationStatus;
  num get totalAmount => netTotal;

  static ErpQuotation fromJson(Map<String, dynamic> json) {
    String s(Object? v) => (v ?? '').toString();
    num n(Object? v) {
      if (v is num) return v;
      return num.tryParse((v ?? '').toString()) ?? 0;
    }

    int? i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse((v ?? '').toString());
    }

    bool b(Object? v) {
      if (v is bool) return v;
      final t = s(v).trim().toLowerCase();
      return t == 'true' || t == '1' || t == 'y' || t == 'yes';
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
      quotId: i(json['quot_id'] ?? json['id']) ?? 0,
      quotNo: s(
        json['quot_no'] ?? json['QuotNo'] ?? json['quotation_no'],
      ).trim(),
      enquiryNo: s(json['enquiry_no'] ?? json['EnquiryNo']).trim(),
      enquiryId: i(json['enquiry_id'] ?? json['EnquiryId']),
      date: s(json['date'] ?? json['QuotDate']).trim(),
      enquiryDate: s(json['enquiry_date'] ?? json['EnquiryDate']).trim(),
      subject: s(json['subject'] ?? json['Subject']).trim(),
      kindAttention: _sn(json['kind_attention'] ?? json['KindAttention']),
      email: s(json['email'] ?? json['Email']).trim(),
      customer: _party(json['customer']),
      clientId: i(json['client_id']),
      billTo: _party(json['bill_to']),
      shipTo: _party(json['ship_to']),
      priority: s(json['priority'] ?? json['Priority']).trim(),
      category: s(json['category'] ?? json['CategoryName']).trim(),
      sector: s(json['sector'] ?? json['Sector']).trim(),
      plant: s(json['plant'] ?? json['Plant']).trim(),
      financialYear: s(json['financial_year'] ?? json['FinancialYear']).trim(),
      currency: s(json['currency'] ?? json['Currency']).trim(),
      netTotal: n(json['net_total'] ?? json['NetTotal']),
      discountPer: n(json['discount_per'] ?? json['DiscountPer']),
      discountAmt: n(json['discount_amt'] ?? json['DiscountAmt']),
      gst: _gst(json['gst']),
      preparedBy: s(json['prepared_by'] ?? json['PreparedBy']).trim(),
      preparedById: i(json['prepared_by_id'] ?? json['PreparedById']),
      enteredBy: s(json['entered_by'] ?? json['EnteredBy']).trim(),
      enteredById: i(json['entered_by_id'] ?? json['EnteredById']),
      quotationStatus: s(
        json['quotation_status'] ?? json['QuotationStatus'],
      ).trim(),
      enquiryStatus: s(json['enquiry_status'] ?? json['EnquiryStatus']).trim(),
      isAmended: b(json['is_amended'] ?? json['IsAmended']),
      isCancelled: b(json['is_cancelled'] ?? json['IsCancelled']),
      versionNo: i(json['version_no'] ?? json['VersionNo']) ?? 0,
      authorization: _authorization(json['authorization']),
      cancelInfo: json['cancel_info'],
      items: items,
    );
  }
}

class ErpQuotationItem {
  const ErpQuotationItem({
    required this.lineId,
    required this.itemId,
    required this.itemCode,
    required this.itemNo,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.discountPer,
    required this.discountAmt,
    required this.total,
    required this.note,
    required this.hsnCode,
  });

  final int? lineId;
  final int? itemId;
  final String itemCode;
  final String itemNo;
  final String description;
  final num quantity;
  final String unit;
  final num rate;
  final num discountPer;
  final num discountAmt;
  final num total;
  final String note;
  final String hsnCode;

  static ErpQuotationItem fromJson(Map<String, dynamic> json) {
    String s(Object? v) => (v ?? '').toString();
    num n(Object? v) {
      if (v is num) return v;
      return num.tryParse((v ?? '').toString()) ?? 0;
    }

    int? i(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse((v ?? '').toString());
    }

    return ErpQuotationItem(
      lineId: i(json['line_id'] ?? json['LineId']),
      itemId: i(json['item_id'] ?? json['ItemId']),
      itemCode: s(json['item_code'] ?? json['ItemCode']).trim(),
      itemNo: s(json['item_no'] ?? json['ItemNo']).trim(),
      description: s(json['description'] ?? json['Desc']).trim(),
      quantity: n(json['qty'] ?? json['quantity'] ?? json['Qty']),
      unit: s(json['unit'] ?? json['Unit']).trim(),
      rate: n(json['rate'] ?? json['unit_price'] ?? json['Rate']),
      discountPer: n(json['discount_per'] ?? json['DiscountPer']),
      discountAmt: n(json['discount_amt'] ?? json['DiscountAmt']),
      total: n(json['total'] ?? json['Total']),
      note: s(json['note'] ?? json['Note']).trim(),
      hsnCode: s(json['hsn_code'] ?? json['HsnCode']).trim(),
    );
  }
}

class ErpParty {
  const ErpParty({required this.id, required this.code, required this.name});

  final int? id;
  final String code;
  final String name;
}

class ErpGst {
  const ErpGst({
    required this.cgstPer,
    required this.cgstAmt,
    required this.sgstPer,
    required this.sgstAmt,
    required this.igstPer,
    required this.igstAmt,
  });

  final num cgstPer;
  final num cgstAmt;
  final num sgstPer;
  final num sgstAmt;
  final num igstPer;
  final num igstAmt;
}

class ErpAuthorization {
  const ErpAuthorization({
    required this.auth1Status,
    required this.auth1By,
    required this.auth1Date,
    required this.auth2Status,
    required this.auth2By,
    required this.auth2Date,
  });

  final String auth1Status;
  final String auth1By;
  final String auth1Date;
  final String auth2Status;
  final String auth2By;
  final String auth2Date;
}

ErpParty? _party(dynamic value) {
  final map = _map(value);
  if (map.isEmpty) return null;
  int? i(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '').toString());
  }

  String s(Object? v) => (v ?? '').toString();
  return ErpParty(
    id: i(map['id']),
    code: s(map['code']).trim(),
    name: s(map['name']).trim(),
  );
}

ErpGst? _gst(dynamic value) {
  final map = _map(value);
  if (map.isEmpty) return null;
  num n(Object? v) {
    if (v is num) return v;
    return num.tryParse((v ?? '').toString()) ?? 0;
  }

  return ErpGst(
    cgstPer: n(map['cgst_per']),
    cgstAmt: n(map['cgst_amt']),
    sgstPer: n(map['sgst_per']),
    sgstAmt: n(map['sgst_amt']),
    igstPer: n(map['igst_per']),
    igstAmt: n(map['igst_amt']),
  );
}

ErpAuthorization? _authorization(dynamic value) {
  final map = _map(value);
  if (map.isEmpty) return null;
  String s(Object? v) => (v ?? '').toString();
  return ErpAuthorization(
    auth1Status: s(map['auth1_status']).trim(),
    auth1By: s(map['auth1_by']).trim(),
    auth1Date: s(map['auth1_date']).trim(),
    auth2Status: s(map['auth2_status']).trim(),
    auth2By: s(map['auth2_by']).trim(),
    auth2Date: s(map['auth2_date']).trim(),
  );
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return <String, dynamic>{};
}

String? _sn(dynamic v) {
  final t = (v ?? '').toString().trim();
  return t.isEmpty ? null : t;
}
