import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/email_settings/presentation/email_settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/clients/presentation/clients_screen.dart';
import '../../features/amc/presentation/amc_screen.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/jobs_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quotations/presentation/quotations_screen.dart';
import '../../features/reports/presentation/report_detail_screen.dart';
import '../../features/reports/presentation/report_create_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/technicians/presentation/technicians_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../shared/widgets/page_loader.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  AuthGuardStatus status() {
    return auth.when(
      loading: () => AuthGuardStatus.loading,
      error: (error, stackTrace) => AuthGuardStatus.unauthenticated,
      data: (value) => value.isAuthenticated
          ? AuthGuardStatus.authenticated
          : AuthGuardStatus.unauthenticated,
    );
  }

  String? role() => auth.valueOrNull?.user?.role;

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _GoRouterRefresh(ref),
    redirect: (context, state) {
      final s = status();
      final isAuthRoute =
          state.matchedLocation == '/login' ||
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
      final adminOnly =
          state.matchedLocation == '/users' ||
          state.matchedLocation == '/email' ||
          state.matchedLocation == '/activity';
      if (adminOnly && userRole != 'admin') return '/';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const PageLoader()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
            builder: (context, state) => const TechniciansScreen(),
          ),
          GoRoute(
            path: '/technicians/new',
            builder: (context, state) => const TechnicianCreateScreen(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsScreen(),
          ),
          GoRoute(
            path: '/clients/new',
            builder: (context, state) => const ClientCreateScreen(),
          ),
          GoRoute(
            path: '/jobs',
            builder: (context, state) => const JobsScreen(),
          ),
          GoRoute(
            path: '/jobs/new',
            builder: (context, state) => const JobCreateScreen(),
          ),
          GoRoute(
            path: '/jobs/:id',
            builder: (context, state) =>
                JobDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/reports/new',
            builder: (context, state) => const ReportCreateScreen(),
          ),
          GoRoute(
            path: '/reports/:id',
            builder: (context, state) =>
                ReportDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/quotations',
            builder: (context, state) => const QuotationsScreen(),
          ),
          GoRoute(path: '/amc', builder: (context, state) => const AmcScreen()),
          GoRoute(
            path: '/amc/new',
            builder: (context, state) => const AmcCreateScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/email',
            builder: (context, state) => const EmailSettingsScreen(),
          ),
          GoRoute(
            path: '/activity',
            builder: (context, state) => const ActivityScreen(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
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
