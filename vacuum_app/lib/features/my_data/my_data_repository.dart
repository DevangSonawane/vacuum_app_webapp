import 'package:dio/dio.dart';

class MyDataRepository {
  MyDataRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> fetch() async {
    final res = await _dio.get('my-data');
    final root = _asMap(res.data);
    return root;
  }
}

Map<String, dynamic> _asMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

