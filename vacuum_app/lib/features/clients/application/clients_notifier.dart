import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/clients_repository.dart';
import '../domain/client.dart';

final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepository(dio: ref.read(dioProvider));
});

class ClientsState {
  const ClientsState({required this.items, this.search = '', this.typeFilter = 'All'});

  final List<Client> items;
  final String search;
  final String typeFilter;

  ClientsState copyWith({List<Client>? items, String? search, String? typeFilter}) {
    return ClientsState(
      items: items ?? this.items,
      search: search ?? this.search,
      typeFilter: typeFilter ?? this.typeFilter,
    );
  }
}

final clientsProvider = AsyncNotifierProvider<ClientsNotifier, ClientsState>(ClientsNotifier.new);

class ClientsNotifier extends AsyncNotifier<ClientsState> {
  ClientsRepository get _repo => ref.read(clientsRepositoryProvider);

  @override
  Future<ClientsState> build() async {
    final items = await _repo.fetchClients();
    return ClientsState(items: items);
  }

  Future<void> filter({String? search, String? type}) async {
    final current = state.valueOrNull ?? const ClientsState(items: []);
    final s = search ?? current.search;
    final t = type ?? current.typeFilter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchClients(search: s, type: t);
      return ClientsState(items: items, search: s, typeFilter: t);
    });
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ?? const ClientsState(items: []);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchClients(search: current.search, type: current.typeFilter);
      return ClientsState(items: items, search: current.search, typeFilter: current.typeFilter);
    });
  }

  Future<Client?> fetchDetail(int id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> create(Map<String, dynamic> p) async {
    try {
      await _repo.create(p);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateClient(int id, Map<String, dynamic> p) async {
    try {
      await _repo.update(id, p);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteClient(int id) async {
    try {
      await _repo.delete(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

