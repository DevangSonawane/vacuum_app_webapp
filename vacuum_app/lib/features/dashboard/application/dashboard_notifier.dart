import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_data.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final dio = ref.read(dioProvider);
  return DashboardRepository(dio: dio);
});

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardData>(
      DashboardNotifier.new,
    );

class DashboardNotifier extends AsyncNotifier<DashboardData> {
  DashboardRepository get _repo => ref.read(dashboardRepositoryProvider);

  bool get _isTechnicianRole {
    final role =
        ref.read(authProvider).valueOrNull?.user?.role.toLowerCase() ?? '';
    return ['technician', 'engineer', 'labour'].contains(role);
  }

  @override
  Future<DashboardData> build() async {
    return _repo.fetchDashboard(isTechnician: _isTechnicianRole);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.fetchDashboard(isTechnician: _isTechnicianRole),
    );
  }
}
