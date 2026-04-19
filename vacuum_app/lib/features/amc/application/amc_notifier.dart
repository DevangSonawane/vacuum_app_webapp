import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/amc_repository.dart';
import '../domain/amc_contract.dart';

final amcRepositoryProvider = Provider<AmcRepository>((ref) {
  return AmcRepository(dio: ref.read(dioProvider));
});

class AmcState {
  const AmcState({required this.items, this.statusFilter = 'All'});

  final List<AmcContract> items;
  final String statusFilter;

  AmcState copyWith({List<AmcContract>? items, String? statusFilter}) {
    return AmcState(items: items ?? this.items, statusFilter: statusFilter ?? this.statusFilter);
  }
}

final amcProvider = AsyncNotifierProvider<AmcNotifier, AmcState>(AmcNotifier.new);

class AmcNotifier extends AsyncNotifier<AmcState> {
  AmcRepository get _repo => ref.read(amcRepositoryProvider);

  @override
  Future<AmcState> build() async {
    final items = await _repo.fetchContracts();
    return AmcState(items: items);
  }

  Future<void> setFilter(String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchContracts(status: status);
      return AmcState(items: items, statusFilter: status);
    });
  }

  Future<void> refresh() async {
    final filter = state.valueOrNull?.statusFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchContracts(status: filter);
      return AmcState(items: items, statusFilter: filter);
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
}

