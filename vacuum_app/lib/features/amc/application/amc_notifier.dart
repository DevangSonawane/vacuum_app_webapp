import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/amc_repository.dart';
import '../domain/amc_contract.dart';

final amcRepositoryProvider = Provider<AmcRepository>((ref) {
  return AmcRepository(dio: ref.read(dioProvider));
});

class AmcState {
  const AmcState({
    required this.items,
    required this.allItems,
    this.statusFilter = 'All',
    this.search = '',
  });

  final List<AmcContract> items;
  final List<AmcContract> allItems;
  final String statusFilter;
  final String search;

  AmcState copyWith({
    List<AmcContract>? items,
    List<AmcContract>? allItems,
    String? statusFilter,
    String? search,
  }) {
    return AmcState(
      items: items ?? this.items,
      allItems: allItems ?? this.allItems,
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
    );
  }
}

final amcProvider = AsyncNotifierProvider<AmcNotifier, AmcState>(
  AmcNotifier.new,
);

class AmcNotifier extends AsyncNotifier<AmcState> {
  AmcRepository get _repo => ref.read(amcRepositoryProvider);

  @override
  Future<AmcState> build() async {
    final items = await _repo.fetchContracts();
    return AmcState(items: items, allItems: items);
  }

  Future<void> setFilter(String status) async {
    final prev = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchContracts(status: status);
      return _applySearch(
        AmcState(
          items: items,
          allItems: items,
          statusFilter: status,
          search: prev?.search ?? '',
        ),
      );
    });
  }

  Future<void> search(String query) async {
    final prev = state.valueOrNull;
    if (prev == null) return;
    final nextQuery = query.trim();
    state = AsyncData(_applySearch(prev.copyWith(search: nextQuery)));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final filter = current?.statusFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchContracts(status: filter);
      return _applySearch(
        AmcState(
          items: items,
          allItems: items,
          statusFilter: filter,
          search: current?.search ?? '',
        ),
      );
    });
  }

  Future<bool> create(Map<String, dynamic> payload) async {
    try {
      await _repo.create(payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateContract(String id, Map<String, dynamic> payload) async {
    try {
      await _repo.update(id, payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteContract(String id) async {
    try {
      await _repo.delete(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AmcContract?> fetchDetail(String id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  AmcState _applySearch(AmcState state) {
    final query = state.search.trim().toLowerCase();
    if (query.isEmpty) return state;
    final filtered = state.allItems.where((contract) {
      return [
        contract.id,
        contract.title,
        contract.clientName,
        contract.status,
        contract.poNumber ?? '',
        contract.startDate ?? '',
        contract.endDate ?? '',
        contract.nextServiceDate ?? '',
        contract.daysLeft?.toString() ?? '',
        contract.visitCount?.toString() ?? '',
        contract.pumpsCount?.toString() ?? '',
        contract.perPumpPrice?.toString() ?? '',
        contract.totalPrice?.toString() ?? '',
        contract.gstPercent?.toString() ?? '',
        contract.services.join(' '),
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
    return state.copyWith(items: filtered);
  }
}
