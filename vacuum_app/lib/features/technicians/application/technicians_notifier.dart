import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/technicians_repository.dart';
import '../domain/technician.dart';

final techniciansRepositoryProvider = Provider<TechniciansRepository>((ref) {
  return TechniciansRepository(dio: ref.read(dioProvider));
});

class TechniciansState {
  const TechniciansState({required this.items, this.search = ''});

  final List<Technician> items;
  final String search;

  TechniciansState copyWith({List<Technician>? items, String? search}) {
    return TechniciansState(items: items ?? this.items, search: search ?? this.search);
  }
}

final techniciansProvider =
    AsyncNotifierProvider<TechniciansNotifier, TechniciansState>(TechniciansNotifier.new);

class TechniciansNotifier extends AsyncNotifier<TechniciansState> {
  TechniciansRepository get _repo => ref.read(techniciansRepositoryProvider);

  @override
  Future<TechniciansState> build() async {
    final items = await _repo.fetchTechnicians();
    return TechniciansState(items: items);
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchTechnicians(search: query);
      return TechniciansState(items: items, search: query);
    });
  }

  Future<void> refresh() async {
    final search = state.valueOrNull?.search ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchTechnicians(search: search);
      return TechniciansState(items: items, search: search);
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

  Future<bool> updateTechnician(int id, Map<String, dynamic> payload) async {
    try {
      await _repo.update(id, payload);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repo.delete(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Technician?> fetchById(int id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }
}
