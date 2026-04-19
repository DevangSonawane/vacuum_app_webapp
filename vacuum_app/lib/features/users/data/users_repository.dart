import 'package:dio/dio.dart';

import '../domain/app_user.dart';

class UsersRepository {
  UsersRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<UsersPage> fetchUsers({required int page}) async {
    final response = await _dio.get('/users', queryParameters: {'page': page});
    final data = _asMap(response.data);

    final list = (data['data'] as List?) ?? const [];
    final users = list
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .map(AppUser.fromJson)
        .toList();

    final pagination = _asMap(data['pagination']);
    return UsersPage(
      users: users,
      page: (pagination['page'] as num?)?.toInt() ?? page,
      totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
      total: (pagination['total'] as num?)?.toInt() ?? users.length,
    );
  }

  Future<void> updateUser(int id, Map<String, dynamic> payload) async {
    await _dio.put('/users/$id', data: payload);
  }

  Future<void> createUser(Map<String, dynamic> payload) async {
    await _dio.post('/users', data: payload);
  }

  Future<AppUser> fetchById(int id) async {
    final response = await _dio.get('/users/$id');
    final data = _asMap(_asMap(response.data)['data'] ?? response.data);
    return AppUser.fromJson(data);
  }

  Future<void> deactivateUser(int id) async {
    await _dio.delete('/users/$id');
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return <String, dynamic>{};
  }
}

class UsersPage {
  const UsersPage({
    required this.users,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  final List<AppUser> users;
  final int page;
  final int totalPages;
  final int total;
}
