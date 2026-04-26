import '../domain/user.dart';

class AuthState {
  const AuthState({
    required this.user,
    required this.isAuthenticated,
    required this.resetToken,
  });

  final User? user;
  final bool isAuthenticated;
  final String? resetToken;

  AuthState copyWith({User? user, bool? isAuthenticated, String? resetToken}) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      resetToken: resetToken ?? this.resetToken,
    );
  }

  static const unauthenticated = AuthState(
    user: null,
    isAuthenticated: false,
    resetToken: null,
  );
}
