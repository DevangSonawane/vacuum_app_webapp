import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/simple_pages/simple_page.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../shared/widgets/page_loader.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  AuthGuardStatus status() {
    return auth.when(
      loading: () => AuthGuardStatus.loading,
      error: (error, stackTrace) => AuthGuardStatus.unauthenticated,
      data: (value) =>
          value.isAuthenticated ? AuthGuardStatus.authenticated : AuthGuardStatus.unauthenticated,
    );
  }

  String? role() => auth.valueOrNull?.user?.role;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefresh(ref),
    redirect: (context, state) {
      final s = status();
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';

      if (s == AuthGuardStatus.loading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      if (s == AuthGuardStatus.unauthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // authenticated
      if (isAuthRoute || state.matchedLocation == '/splash') return '/';

      final userRole = role();
      final adminOnly = state.matchedLocation == '/users' || state.matchedLocation == '/email';
      if (adminOnly && userRole != 'admin') return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const PageLoader(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/technicians',
            builder: (context, state) => const SimplePage(title: 'Technicians'),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const SimplePage(title: 'Clients'),
          ),
          GoRoute(
            path: '/jobs',
            builder: (context, state) => const SimplePage(title: 'Work Orders'),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const SimplePage(title: 'Service Reports'),
          ),
          GoRoute(
            path: '/quotations',
            builder: (context, state) => const SimplePage(title: 'Quotations'),
          ),
          GoRoute(
            path: '/amc',
            builder: (context, state) => const SimplePage(title: 'AMC Contracts'),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const SimplePage(title: 'Attendance'),
          ),
          GoRoute(
            path: '/email',
            builder: (context, state) => const SimplePage(title: 'Email Settings'),
          ),
          GoRoute(
            path: '/activity',
            builder: (context, state) => const SimplePage(title: 'Activity History'),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const SimplePage(title: 'Profile'),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SimplePage(title: 'Settings'),
          ),
        ],
      ),
    ],
  );
});

enum AuthGuardStatus { loading, unauthenticated, authenticated }

class _GoRouterRefresh extends ChangeNotifier {
  _GoRouterRefresh(this.ref) {
    _sub = ref.listen(authProvider, (previous, next) => notifyListeners());
  }

  final Ref ref;
  late final ProviderSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
