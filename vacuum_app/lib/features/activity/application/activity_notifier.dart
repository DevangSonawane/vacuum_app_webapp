import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/activity_repository.dart';
import '../domain/activity_item.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(dio: ref.read(dioProvider));
});

class ActivityState {
  const ActivityState({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    this.typeFilter = 'All',
  });

  final List<ActivityItem> items;
  final String typeFilter;
  final int page;
  final int totalPages;
  final int total;

  ActivityState copyWith({
    List<ActivityItem>? items,
    String? typeFilter,
    int? page,
    int? totalPages,
    int? total,
  }) => ActivityState(
    items: items ?? this.items,
    typeFilter: typeFilter ?? this.typeFilter,
    page: page ?? this.page,
    totalPages: totalPages ?? this.totalPages,
    total: total ?? this.total,
  );
}

final activityProvider = AsyncNotifierProvider<ActivityNotifier, ActivityState>(
  ActivityNotifier.new,
);

class ActivityNotifier extends AsyncNotifier<ActivityState> {
  ActivityRepository get _repo => ref.read(activityRepositoryProvider);
  static const _limit = 30;

  @override
  Future<ActivityState> build() async {
    final result = await _repo.fetchActivity(page: 1, limit: _limit);
    return ActivityState(
      items: result.items,
      page: result.page,
      totalPages: result.totalPages,
      total: result.total,
    );
  }

  Future<void> setFilter(String type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.fetchActivity(
        page: 1,
        limit: _limit,
        type: type,
      );
      return ActivityState(
        items: result.items,
        typeFilter: type,
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
      );
    });
  }

  Future<void> refresh() async {
    final filter = state.valueOrNull?.typeFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.fetchActivity(
        page: 1,
        limit: _limit,
        type: filter,
      );
      return ActivityState(
        items: result.items,
        typeFilter: filter,
        page: result.page,
        totalPages: result.totalPages,
        total: result.total,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.page >= current.totalPages) return;

    final filter = current.typeFilter;
    final nextPage = current.page + 1;
    try {
      final result = await _repo.fetchActivity(
        page: nextPage,
        limit: _limit,
        type: filter,
      );
      final nextItems = [...current.items, ...result.items];
      state = AsyncData(
        current.copyWith(
          items: nextItems,
          page: result.page,
          totalPages: result.totalPages,
          total: result.total,
        ),
      );
    } catch (_) {
      // ignore
    }
  }
}
