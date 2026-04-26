import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  return AuthRepository(dio: dio);
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  TokenStorage get _tokenStorage => ref.read(tokenStorageProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AuthState> build() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return AuthState.unauthenticated;
    try {
      final user = await _repo.getMe();
      return AuthState(user: user, isAuthenticated: true, resetToken: null);
    } catch (_) {
      await _tokenStorage.deleteToken();
      return AuthState.unauthenticated;
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.login(
        identifier: identifier,
        password: password,
      );
      await _tokenStorage.writeToken(result.token);
      return AuthState(
        user: result.user,
        isAuthenticated: true,
        resetToken: null,
      );
    });
  }

  Future<void> logout() async {
    await _tokenStorage.deleteToken();
    state = const AsyncData(AuthState.unauthenticated);
  }

  Future<void> forgotPassword({required String email}) async {
    final current = state.valueOrNull ?? AuthState.unauthenticated;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final token = await _repo.forgotPassword(email: email);
      return current.copyWith(resetToken: token);
    });
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final current = state.valueOrNull ?? AuthState.unauthenticated;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return current.copyWith(resetToken: null);
    });
  }
}
