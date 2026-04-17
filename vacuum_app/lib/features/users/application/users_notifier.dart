import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/users_repository.dart';
import 'users_state.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final dio = ref.read(dioProvider);
  return UsersRepository(dio: dio);
});

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, UsersState>(UsersNotifier.new);

class UsersNotifier extends AsyncNotifier<UsersState> {
  UsersRepository get _repo => ref.read(usersRepositoryProvider);

  @override
  Future<UsersState> build() async {
    return _fetch(page: 1);
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull ?? UsersState.empty;
    if (current.page >= current.totalPages) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: current.page + 1));
  }

  Future<void> prevPage() async {
    final current = state.valueOrNull ?? UsersState.empty;
    if (current.page <= 1) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(page: current.page - 1));
  }

  Future<UsersState> _fetch({required int page}) async {
    final result = await _repo.fetchUsers(page: page);
    return UsersState(
      users: result.users,
      page: result.page,
      totalPages: result.totalPages,
      total: result.total,
    );
  }
}

