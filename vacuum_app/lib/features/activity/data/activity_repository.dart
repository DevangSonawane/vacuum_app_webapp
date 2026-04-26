import 'package:dio/dio.dart';

import '../domain/activity_item.dart';

class ActivityRepository {
  ActivityRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<ActivityPage> fetchActivity({
    required int page,
    required int limit,
    String type = '',
  }) async {
    final response = await _dio.get(
      'activity',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (type.isNotEmpty && type != 'All') 'type': type,
      },
    );

    final root = _asMap(response.data);
    final list = _asList(root['data']);
    final items = list
        .whereType<Map>()
        .map(
          (e) =>
              ActivityItem.fromJson(e.map((k, v) => MapEntry(k.toString(), v))),
        )
        .toList();

    final pagination = _asMap(root['pagination']);
    return ActivityPage(
      items: items,
      page: (pagination['page'] as num?)?.toInt() ?? page,
      totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? items.length,
    );
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}

class ActivityPage {
  const ActivityPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<ActivityItem> items;
  final int page;
  final int totalPages;
  final int total;
}
