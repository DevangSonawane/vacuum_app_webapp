import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/domain/user.dart';
import '../data/jobs_repository.dart';
import '../domain/job.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(dio: ref.read(dioProvider));
});

class JobsState {
  const JobsState({
    required this.items,
    required this.allItems,
    this.statusFilter = 'All',
    this.search = '',
  });

  final List<Job> items;
  final List<Job> allItems;
  final String statusFilter;
  final String search;

  JobsState copyWith({
    List<Job>? items,
    List<Job>? allItems,
    String? statusFilter,
    String? search,
  }) {
    return JobsState(
      items: items ?? this.items,
      allItems: allItems ?? this.allItems,
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
    );
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, JobsState>(
  JobsNotifier.new,
);

class JobsNotifier extends AsyncNotifier<JobsState> {
  JobsRepository get _repo => ref.read(jobsRepositoryProvider);

  int? _scopedUserId([User? user]) {
    final auth = user ?? ref.read(authProvider).valueOrNull?.user;
    if (auth == null) return null;
    final role = auth.role.toLowerCase();
    if (role == 'technician' && auth.id != 0) return auth.id;
    return null;
  }

  @override
  Future<JobsState> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull?.user;
    if (user == null) {
      return const JobsState(items: [], allItems: []);
    }

    final items = await _repo.fetchJobs(userId: _scopedUserId(user));
    return JobsState(items: items, allItems: items);
  }

  Future<void> setFilter(String status) async {
    final prev = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchJobs(
        status: status,
        userId: _scopedUserId(),
      );
      return _applySearch(
        JobsState(
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
      final items = await _repo.fetchJobs(
        status: filter,
        userId: _scopedUserId(),
      );
      return _applySearch(
        JobsState(
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

  Future<bool> advanceStatus(String id, String next) async {
    try {
      await _repo.advanceStatus(id, next);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelJob(String id, {String? reason}) async {
    try {
      await _repo.cancel(id, reason: reason);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteJob(String id) async {
    try {
      await _repo.delete(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Job?> fetchDetail(String id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadAndLinkImages(
    String jobId,
    List<({String path, String name})> files,
  ) async {
    try {
      for (final f in files) {
        final url = await _repo.uploadImage(jobId, f.path, f.name);
        if (url == null) continue;
        await _repo.linkImage(jobId, {'file_url': url, 'file_name': f.name});
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  JobsState _applySearch(JobsState state) {
    final query = state.search.trim().toLowerCase();
    if (query.isEmpty) return state;
    final filtered = state.allItems.where((job) {
      return [
        job.id,
        job.title,
        job.status,
        job.priority,
        job.category,
        job.clientName,
        job.technicianDisplayName,
        job.description,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
    return state.copyWith(items: filtered);
  }
}
