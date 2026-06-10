import 'package:dio/dio.dart';

import '../domain/user.dart';

class AuthRepository {
  AuthRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<({String token, User user})> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final trimmed = identifier.trim();
      final payload = <String, dynamic>{'password': password};

      if (trimmed.contains('@')) {
        payload['email'] = trimmed;
      } else {
        final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
        payload['phone_number'] = digits.startsWith('91')
            ? '+$digits'
            : '+91$digits';
      }

      final response = await _dio.post('auth/login', data: payload);
      final data = _asMap(response.data);

      final token = (data['token'] ?? '').toString();
      final userJson = _asMap(data['user'] ?? data);
      final user = User.fromJson(userJson);
      if (token.isEmpty || user.id == 0) {
        throw const AuthException('Login failed. Please try again.');
      }
      return (token: token, user: user);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (_isConnectionIssue(e)) {
        throw const AuthException(
          'Unable to reach the server. Please check your internet connection.',
        );
      }
      if (status == 400 || status == 401 || status == 422) {
        throw const AuthException(
          'Incorrect email/phone number or password.',
        );
      }
      if (status == 403) {
        throw const AuthException(
          'Your account does not have access. Please contact the admin.',
        );
      }
      if (status != null && status >= 500) {
        throw const AuthException(
          'Backend error. Please contact the admin and try again later.',
        );
      }
      throw AuthException(
        _messageFromDio(e, fallback: 'Login failed. Please try again.'),
      );
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _dio.get('auth/me');
      final data = _asMap(response.data);
      final userJson = _asMap(data['user'] ?? data);
      final user = User.fromJson(userJson);
      if (user.id == 0) throw const AuthException('Invalid session response.');
      return user;
    } on DioException catch (e) {
      throw AuthException(
        _messageFromDio(e, fallback: 'Session expired. Please sign in again.'),
      );
    }
  }

  Future<String?> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        'auth/forgot-password',
        data: {'email': email.trim()},
      );
      final data = _asMap(response.data);
      final token = data['dev_only_reset_token'];
      return (token as Object?)?.toString();
    } on DioException catch (e) {
      throw AuthException(
        _messageFromDio(e, fallback: 'Failed to request reset token.'),
      );
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _dio.post(
        'auth/reset-password',
        data: {
          'token': token.trim(),
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw AuthException(
        _messageFromDio(e, fallback: 'Failed to reset password.'),
      );
    }
  }

  static String _messageFromDio(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'].toString().trim();
      if (msg.isNotEmpty) return msg;
    }
    if (data is Map && data['error'] != null) {
      final msg = data['error'].toString().trim();
      if (msg.isNotEmpty) return msg;
    }
    final msg = e.message?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return fallback;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static bool _isConnectionIssue(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown => true,
      _ => false,
    };
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
