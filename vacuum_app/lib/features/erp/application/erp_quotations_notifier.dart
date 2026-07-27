import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/erp_quotations_repository.dart';
import '../domain/erp_quotation.dart';

final erpQuotationsRepositoryProvider = Provider<ErpQuotationsRepository>((
  ref,
) {
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
    this.priority = 'All',
    this.category = 'All',
    this.series = 'All',
    this.preparedBy = '',
    this.enteredBy = '',
    this.fromDate = '',
    this.toDate = '',
  });

  final List<ErpQuotation> items;
  final int page;
  final int limit;
  final int count;
  final String search;
  final String status;
  final String priority;
  final String category;
  final String series;
  final String preparedBy;
  final String enteredBy;
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
    String? priority,
    String? category,
    String? series,
    String? preparedBy,
    String? enteredBy,
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
      priority: priority ?? this.priority,
      category: category ?? this.category,
      series: series ?? this.series,
      preparedBy: preparedBy ?? this.preparedBy,
      enteredBy: enteredBy ?? this.enteredBy,
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
  ErpQuotationsRepository get _repo =>
      ref.read(erpQuotationsRepositoryProvider);

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
    String? priority,
    String? category,
    String? series,
    String? preparedBy,
    String? enteredBy,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) async {
    final prev = state.valueOrNull;
    final next =
        prev?.copyWith(
          search: search ?? prev.search,
          status: status ?? prev.status,
          priority: priority ?? prev.priority,
          category: category ?? prev.category,
          series: series ?? prev.series,
          preparedBy: preparedBy ?? prev.preparedBy,
          enteredBy: enteredBy ?? prev.enteredBy,
          fromDate: fromDate ?? prev.fromDate,
          toDate: toDate ?? prev.toDate,
          page: page ?? prev.page,
          limit: limit ?? prev.limit,
        ) ??
        ErpQuotationsState(
          items: const [],
          count: 0,
          page: 1,
          limit: limit ?? 10,
          search: search ?? '',
          status: status ?? 'All',
          priority: 'All',
          category: 'All',
          series: 'All',
          preparedBy: preparedBy ?? '',
          enteredBy: enteredBy ?? '',
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
        priority: next.priority == 'All' ? '' : next.priority,
        category: next.category == 'All' ? '' : next.category,
        series: next.series,
        preparedBy: next.preparedBy,
        enteredBy: next.enteredBy,
        fromDate: next.fromDate,
        toDate: next.toDate,
      );
      return next.copyWith(items: res.items, count: res.count);
    });
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    if (current == null) {
      await build();
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repo.syncQuotations();
      final res = await _repo.fetchQuotations(
        page: current.page,
        limit: current.limit,
        search: current.search,
        status: current.status == 'All' ? '' : current.status,
        priority: current.priority == 'All' ? '' : current.priority,
        category: current.category == 'All' ? '' : current.category,
        series: current.series,
        preparedBy: current.preparedBy,
        enteredBy: current.enteredBy,
        fromDate: current.fromDate,
        toDate: current.toDate,
      );
      return current.copyWith(items: res.items, count: res.count);
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
