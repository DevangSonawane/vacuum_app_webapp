import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/users_repository.dart';
import '../domain/app_user.dart';
import 'users_state.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final dio = ref.read(dioProvider);
  return UsersRepository(dio: dio);
});

final usersProvider = AsyncNotifierProvider<UsersNotifier, UsersState>(
  UsersNotifier.new,
);

class UsersNotifier extends AsyncNotifier<UsersState> {
  UsersRepository get _repo => ref.read(usersRepositoryProvider);

  @override
  Future<UsersState> build() async {
    return _fetch(page: 1, query: '');
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? UsersState.empty;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(page: current.page, query: current.query),
    );
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull ?? UsersState.empty;
    if (current.page >= current.totalPages) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(page: current.page + 1, query: current.query),
    );
  }

  Future<void> prevPage() async {
    final current = state.valueOrNull ?? UsersState.empty;
    if (current.page <= 1) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(page: current.page - 1, query: current.query),
    );
  }

  Future<UsersState> _fetch({required int page, required String query}) async {
    final result = await _repo.fetchUsers(page: page, search: query);
    return UsersState(
      allUsers: result.users,
      users: result.users,
      page: result.page,
      totalPages: result.totalPages,
      total: result.total,
      query: query,
    );
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetch(page: 1, query: query.trim()),
    );
  }

  Future<bool> createUser(Map<String, dynamic> payload) async {
    try {
      await _repo.createUser(payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateUserDetails(int id, Map<String, dynamic> payload) async {
    try {
      await _repo.updateUser(id, payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deactivate(int id) async {
    try {
      await _repo.deactivateUser(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AppUser?> fetchById(int id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

}
