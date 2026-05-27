import 'package:dio/dio.dart';

import '../domain/erp_customer.dart';

class ErpCustomersRepository {
  ErpCustomersRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<({List<ErpCustomer> items, int count})> fetchCustomers({
    int page = 1,
    int limit = 50,
    String search = '',
    String status = '',
  }) async {
    final res = await _dio.get(
      'erp/customers',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.trim().isNotEmpty && status != 'All') 'status': status.trim(),
      },
    );
    final root = _asMap(res.data);
    final data = _asList(root['data']);
    final items = data
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .map(ErpCustomer.fromJson)
        .toList();
    final count = _asInt(root['count'], fallback: items.length);
    return (items: items, count: count);
  }

  Future<ErpCustomer> fetchById(String id) async {
    final res = await _dio.get('erp/customers/$id');
    final root = _asMap(res.data);
    return ErpCustomer.fromJson(_asMap(root['data']));
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

