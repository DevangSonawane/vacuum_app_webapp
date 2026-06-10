import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio: dio);
});

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>(
      (ref) => AuthNotifier(ref),
    );

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  AuthNotifier(this.ref) : super(const AsyncLoading()) {
    unawaited(_restoreSession());
  }

  final Ref ref;

  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _setStateAsync(AsyncValue<AuthState> value) {
    final completer = Completer<void>();
    scheduleMicrotask(() {
      if (mounted) {
        state = value;
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    return completer.future;
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      debugPrint('[Auth] build: no stored token');
      await _setStateAsync(const AsyncData(AuthState.unauthenticated));
      return;
    }

    try {
      final user = await _repo.getMe();
      debugPrint('[Auth] build: restored session for ${user.email}');
      await _setStateAsync(
        AsyncData(
          AuthState(user: user, isAuthenticated: true, resetToken: null),
        ),
      );
    } catch (_) {
      debugPrint('[Auth] build: stored token invalid, clearing session');
      await _tokenStorage.deleteToken();
      await _setStateAsync(const AsyncData(AuthState.unauthenticated));
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    debugPrint(
      '[Auth] login: start (${identifier.trim().contains('@') ? 'email' : 'phone'})',
    );
    try {
      final result = await _repo.login(
        identifier: identifier,
        password: password,
      );
      await _tokenStorage.writeToken(result.token);
      debugPrint('[Auth] login: success for ${result.user.email}');
      await _setStateAsync(
        AsyncData(
          AuthState(
          user: result.user,
          isAuthenticated: true,
          resetToken: null,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[Auth] login: failed -> $error');
      await _setStateAsync(AsyncError(error, stackTrace));
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> logout() async {
    debugPrint('[Auth] logout: start');
    await _tokenStorage.deleteToken();
    await _setStateAsync(const AsyncData(AuthState.unauthenticated));
    debugPrint('[Auth] logout: completed');
  }

  Future<void> forgotPassword({required String email}) async {
    final current = state.valueOrNull ?? AuthState.unauthenticated;
    await _setStateAsync(const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      final token = await _repo.forgotPassword(email: email);
      return current.copyWith(resetToken: token);
    });
    await _setStateAsync(result);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final current = state.valueOrNull ?? AuthState.unauthenticated;
    await _setStateAsync(const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      await _repo.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return current.copyWith(resetToken: null);
    });
    await _setStateAsync(result);
  }
}
