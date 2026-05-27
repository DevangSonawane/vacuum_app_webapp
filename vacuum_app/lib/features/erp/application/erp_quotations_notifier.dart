import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/erp_quotations_repository.dart';
import '../domain/erp_quotation.dart';

final erpQuotationsRepositoryProvider = Provider<ErpQuotationsRepository>((ref) {
  return ErpQuotationsRepository(dio: ref.read(dioProvider));
});

class ErpQuotationsState {
  const ErpQuotationsState({
    required this.items,
    required this.page,
    required this.limit,
    required this.count,
    this.search = '',
    this.status = 'All',
    this.fromDate = '',
    this.toDate = '',
  });

  final List<ErpQuotation> items;
  final int page;
  final int limit;
  final int count;
  final String search;
  final String status;
  final String fromDate;
  final String toDate;

  int get totalPages => (count / limit).ceil().clamp(1, 999999);

  ErpQuotationsState copyWith({
    List<ErpQuotation>? items,
    int? page,
    int? limit,
    int? count,
    String? search,
    String? status,
    String? fromDate,
    String? toDate,
  }) {
    return ErpQuotationsState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      count: count ?? this.count,
      search: search ?? this.search,
      status: status ?? this.status,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

final erpQuotationsProvider =
    AsyncNotifierProvider<ErpQuotationsNotifier, ErpQuotationsState>(
      ErpQuotationsNotifier.new,
    );

class ErpQuotationsNotifier extends AsyncNotifier<ErpQuotationsState> {
  ErpQuotationsRepository get _repo => ref.read(erpQuotationsRepositoryProvider);

  @override
  Future<ErpQuotationsState> build() async {
    final res = await _repo.fetchQuotations(page: 1, limit: 10);
    return ErpQuotationsState(
      items: res.items,
      count: res.count,
      page: 1,
      limit: 10,
    );
  }

  Future<void> applyFilters({
    String? search,
    String? status,
    String? fromDate,
    String? toDate,
    int? page,
  }) async {
    final prev = state.valueOrNull;
    final next = prev?.copyWith(
          search: search ?? prev.search,
          status: status ?? prev.status,
          fromDate: fromDate ?? prev.fromDate,
          toDate: toDate ?? prev.toDate,
          page: page ?? prev.page,
        ) ??
        ErpQuotationsState(
          items: const [],
          count: 0,
          page: 1,
          limit: 10,
          search: search ?? '',
          status: status ?? 'All',
          fromDate: fromDate ?? '',
          toDate: toDate ?? '',
        );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await _repo.fetchQuotations(
        page: next.page,
        limit: next.limit,
        search: next.search,
        status: next.status == 'All' ? '' : next.status,
        fromDate: next.fromDate,
        toDate: next.toDate,
      );
      return next.copyWith(items: res.items, count: res.count);
    });
  }

  Future<ErpQuotation?> fetchDetail(String id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }
}

