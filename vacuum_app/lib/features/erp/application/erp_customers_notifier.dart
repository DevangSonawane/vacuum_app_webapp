import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/erp_customers_repository.dart';
import '../domain/erp_customer.dart';

final erpCustomersRepositoryProvider = Provider<ErpCustomersRepository>((ref) {
  return ErpCustomersRepository(dio: ref.read(dioProvider));
});

class ErpCustomersState {
  const ErpCustomersState({
    required this.items,
    required this.page,
    required this.limit,
    required this.count,
    this.search = '',
    this.status = 'All',
  });

  final List<ErpCustomer> items;
  final int page;
  final int limit;
  final int count;
  final String search;
  final String status;

  int get totalPages => (count / limit).ceil().clamp(1, 999999);

  ErpCustomersState copyWith({
    List<ErpCustomer>? items,
    int? page,
    int? limit,
    int? count,
    String? search,
    String? status,
  }) {
    return ErpCustomersState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      count: count ?? this.count,
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }
}

final erpCustomersProvider =
    AsyncNotifierProvider<ErpCustomersNotifier, ErpCustomersState>(
      ErpCustomersNotifier.new,
    );

class ErpCustomersNotifier extends AsyncNotifier<ErpCustomersState> {
  ErpCustomersRepository get _repo => ref.read(erpCustomersRepositoryProvider);

  @override
  Future<ErpCustomersState> build() async {
    final res = await _repo.fetchCustomers(page: 1, limit: 10);
    return ErpCustomersState(
      items: res.items,
      count: res.count,
      page: 1,
      limit: 10,
    );
  }

  Future<void> setSearch(String value) async {
    final prev = state.valueOrNull;
    final nextSearch = value.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = 1;
      final limit = prev?.limit ?? 10;
      final status = prev?.status ?? 'All';
      final res = await _repo.fetchCustomers(
        page: page,
        limit: limit,
        search: nextSearch,
        status: status,
      );
      return ErpCustomersState(
        items: res.items,
        count: res.count,
        page: page,
        limit: limit,
        search: nextSearch,
        status: status,
      );
    });
  }

  Future<void> setStatus(String value) async {
    final prev = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = 1;
      final limit = prev?.limit ?? 10;
      final search = prev?.search ?? '';
      final res = await _repo.fetchCustomers(
        page: page,
        limit: limit,
        search: search,
        status: value,
      );
      return ErpCustomersState(
        items: res.items,
        count: res.count,
        page: page,
        limit: limit,
        search: search,
        status: value,
      );
    });
  }

  Future<void> setPage(int page) async {
    final prev = state.valueOrNull;
    if (prev == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await _repo.fetchCustomers(
        page: page,
        limit: prev.limit,
        search: prev.search,
        status: prev.status,
      );
      return prev.copyWith(items: res.items, count: res.count, page: page);
    });
  }

  Future<ErpCustomer?> fetchDetail(String id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }
}

