import 'package:dio/dio.dart';

import '../domain/user.dart';

class AuthRepository {
  AuthRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<({String token, User user})> login({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    final payload = <String, dynamic>{'password': password};

    if (trimmed.contains('@')) {
      payload['email'] = trimmed;
    } else {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      payload['phone_number'] = digits.startsWith('91') ? '+$digits' : '+91$digits';
    }

    final response = await _dio.post('/auth/login', data: payload);
    final data = _asMap(response.data);

    final token = (data['token'] ?? '').toString();
    final userJson = _asMap(data['user'] ?? data);
    final user = User.fromJson(userJson);
    if (token.isEmpty || user.id == 0) {
      throw const AuthException('Invalid login response.');
    }
    return (token: token, user: user);
  }

  Future<User> getMe() async {
    final response = await _dio.get('/auth/me');
    final data = _asMap(response.data);
    final userJson = _asMap(data['user'] ?? data);
    final user = User.fromJson(userJson);
    if (user.id == 0) throw const AuthException('Invalid session response.');
    return user;
  }

  Future<String?> forgotPassword({required String email}) async {
    final response = await _dio.post('/auth/forgot-password', data: {'email': email.trim()});
    final data = _asMap(response.data);
    final token = data['dev_only_reset_token'];
    return (token as Object?)?.toString();
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post(
      '/auth/reset-password',
      data: {
        'token': token.trim(),
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return <String, dynamic>{};
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
