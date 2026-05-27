import 'package:dio/dio.dart';

import '../domain/erp_quotation.dart';

class ErpQuotationsRepository {
  ErpQuotationsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<({List<ErpQuotation> items, int count})> fetchQuotations({
    int page = 1,
    int limit = 10,
    String status = '',
    String fromDate = '',
    String toDate = '',
    String search = '',
    String customerId = '',
  }) async {
    final res = await _dio.get(
      'erp/quotations',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status.trim().isNotEmpty && status != 'All') 'status': status.trim(),
        if (fromDate.trim().isNotEmpty) 'from_date': fromDate.trim(),
        if (toDate.trim().isNotEmpty) 'to_date': toDate.trim(),
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (customerId.trim().isNotEmpty) 'customer_id': customerId.trim(),
      },
    );

    final root = _asMap(res.data);
    final data = _asList(root['data']);
    final items = data
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .map(ErpQuotation.fromJson)
        .toList();
    final count = _asInt(root['count'], fallback: items.length);
    return (items: items, count: count);
  }

  Future<ErpQuotation> fetchById(String id) async {
    final res = await _dio.get('erp/quotations/$id');
    final root = _asMap(res.data);
    return ErpQuotation.fromJson(_asMap(root['data']));
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic v) => v is List ? v : const [];

int _asInt(Object? v, {required int fallback}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse((v ?? '').toString()) ?? fallback;
}

