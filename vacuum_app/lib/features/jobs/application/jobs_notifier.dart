import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/jobs_repository.dart';
import '../domain/job.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(dio: ref.read(dioProvider));
});

class JobsState {
  const JobsState({required this.items, this.statusFilter = 'All'});

  final List<Job> items;
  final String statusFilter;

  JobsState copyWith({List<Job>? items, String? statusFilter}) {
    return JobsState(items: items ?? this.items, statusFilter: statusFilter ?? this.statusFilter);
  }
}

final jobsProvider = AsyncNotifierProvider<JobsNotifier, JobsState>(JobsNotifier.new);

class JobsNotifier extends AsyncNotifier<JobsState> {
  JobsRepository get _repo => ref.read(jobsRepositoryProvider);

  @override
  Future<JobsState> build() async {
    final items = await _repo.fetchJobs();
    return JobsState(items: items);
  }

  Future<void> setFilter(String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchJobs(status: status);
      return JobsState(items: items, statusFilter: status);
    });
  }

  Future<void> refresh() async {
    final filter = state.valueOrNull?.statusFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchJobs(status: filter);
      return JobsState(items: items, statusFilter: filter);
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

  Future<Job?> fetchDetail(String id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadAndLinkImages(String jobId, List<({String path, String name})> files) async {
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
}

