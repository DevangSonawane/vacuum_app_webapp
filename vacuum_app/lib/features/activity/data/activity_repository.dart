import 'package:dio/dio.dart';

import '../domain/activity_item.dart';

class ActivityRepository {
  ActivityRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<ActivityItem>> fetchActivity({String type = ''}) async {
    final response = await _dio.get(
      '/activity',
      queryParameters: {
        'limit': 50,
        if (type.isNotEmpty && type != 'All') 'type': type,
      },
    );

    final root = _asMap(response.data);
    final list = _asList(root['data']);
    return list
        .whereType<Map>()
        .map((e) => ActivityItem.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}

