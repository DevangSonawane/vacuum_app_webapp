import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../storage/secure_token_storage.dart';
import '../storage/token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.read(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  if (!kReleaseMode) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final safeHeaders = Map<String, dynamic>.from(options.headers);
          if (safeHeaders['Authorization'] != null) safeHeaders['Authorization'] = 'Bearer **redacted**';

          Object? safeData = options.data;
          if (safeData is Map) {
            final m = safeData.map((k, v) => MapEntry(k.toString(), v));
            for (final key in const [
              'password',
              'new_password',
              'confirm_password',
              'token',
            ]) {
              if (m.containsKey(key)) m[key] = '**redacted**';
            }
            safeData = m;
          } else if (safeData is FormData) {
            safeData = '[FormData]';
          }

          debugPrint('[DIO] -> ${options.method} ${options.uri}');
          debugPrint('[DIO] headers=$safeHeaders');
          if (options.queryParameters.isNotEmpty) debugPrint('[DIO] query=${options.queryParameters}');
          if (safeData != null) debugPrint('[DIO] data=$safeData');
          handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('[DIO] <- ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) {
          final uri = error.requestOptions.uri;
          final status = error.response?.statusCode;
          debugPrint('[DIO] !! $status $uri');
          final data = error.response?.data;
          if (data != null) debugPrint('[DIO] errorBody=$data');
          handler.next(error);
        },
      ),
    );
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        if (status == 401) {
          await tokenStorage.deleteToken();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
