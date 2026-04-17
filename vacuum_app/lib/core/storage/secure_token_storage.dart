import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import 'token_storage.dart';

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> deleteToken() => _storage.delete(key: AppConstants.tokenKey);

  @override
  Future<String?> readToken() => _storage.read(key: AppConstants.tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: AppConstants.tokenKey, value: token);
}

