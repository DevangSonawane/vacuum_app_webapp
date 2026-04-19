import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/activity_repository.dart';
import '../domain/activity_item.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(dio: ref.read(dioProvider));
});

class ActivityState {
  const ActivityState({required this.items, this.typeFilter = 'All'});

  final List<ActivityItem> items;
  final String typeFilter;

  ActivityState copyWith({List<ActivityItem>? items, String? typeFilter}) =>
      ActivityState(items: items ?? this.items, typeFilter: typeFilter ?? this.typeFilter);
}

final activityProvider = AsyncNotifierProvider<ActivityNotifier, ActivityState>(ActivityNotifier.new);

class ActivityNotifier extends AsyncNotifier<ActivityState> {
  ActivityRepository get _repo => ref.read(activityRepositoryProvider);

  @override
  Future<ActivityState> build() async {
    final items = await _repo.fetchActivity();
    return ActivityState(items: items);
  }

  Future<void> setFilter(String type) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchActivity(type: type);
      return ActivityState(items: items, typeFilter: type);
    });
  }

  Future<void> refresh() async {
    final filter = state.valueOrNull?.typeFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchActivity(type: filter);
      return ActivityState(items: items, typeFilter: filter);
    });
  }
}

