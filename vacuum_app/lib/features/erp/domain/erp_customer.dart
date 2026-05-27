class ErpCustomer {
  const ErpCustomer({
    required this.id,
    required this.code,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    this.address,
    this.address1,
    this.address2,
    this.pinCode,
    this.stateCode,
    this.gstin,
    this.createdDate,
  });

  final String id;
  final String? code;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? address1;
  final String? address2;
  final String? pinCode;
  final String? stateCode;
  final String? gstin;
  final String status;
  final String? createdDate;

  static ErpCustomer fromJson(Map<String, dynamic> json) {
    String s(Object? v) => (v ?? '').toString();
    String? sn(Object? v) {
      final v0 = (v ?? '').toString().trim();
      return v0.isEmpty ? null : v0;
    }

    final id = s(json['id'] ?? json['CustId'] ?? json['cust_id']).trim();
    final name =
        s(json['name'] ?? json['CustName'] ?? json['cust_name']).trim();
    final code = sn(json['CustCode'] ?? json['code']);
    final email = sn(json['email'] ?? json['EmailId'] ?? json['email_id']);
    final phone =
        sn(json['phone'] ?? json['ContactNo'] ?? json['phone_number']);
    final address = sn(
      json['address'] ??
          json['CustAdd'] ??
          json['CustAdd1'] ??
          json['CustAdd2'] ??
          json['cust_add'],
    );
    final address1 = sn(json['CustAdd1']);
    final address2 = sn(json['CustAdd2']);
    final pinCode = sn(json['PinCode']);
    final stateCode = sn(json['StateCode']);
    final gstin = sn(json['gstin'] ?? json['GSTIN'] ?? json['gst_no']);

    return ErpCustomer(
      id: id,
      code: code,
      name: name,
      email: email,
      phone: phone,
      address: address,
      address1: address1,
      address2: address2,
      pinCode: pinCode,
      stateCode: stateCode,
      gstin: gstin,
      status: s(json['status']).trim().isEmpty ? 'Active' : s(json['status']),
      createdDate: sn(json['created_date']),
    );
  }
}
