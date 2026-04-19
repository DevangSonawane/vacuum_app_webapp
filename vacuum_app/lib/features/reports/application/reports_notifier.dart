import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(dio: ref.read(dioProvider));
});

class ReportsState {
  const ReportsState({required this.items, this.statusFilter = 'All'});

  final List<Report> items;
  final String statusFilter;

  ReportsState copyWith({List<Report>? items, String? statusFilter}) {
    return ReportsState(items: items ?? this.items, statusFilter: statusFilter ?? this.statusFilter);
  }
}

final reportsProvider = AsyncNotifierProvider<ReportsNotifier, ReportsState>(ReportsNotifier.new);

class ReportsNotifier extends AsyncNotifier<ReportsState> {
  ReportsRepository get _repo => ref.read(reportsRepositoryProvider);

  @override
  Future<ReportsState> build() async {
    final items = await _repo.fetchReports();
    return ReportsState(items: items);
  }

  Future<void> setFilter(String status) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchReports(status: status);
      return ReportsState(items: items, statusFilter: status);
    });
  }

  Future<void> refresh() async {
    final filter = state.valueOrNull?.statusFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchReports(status: filter);
      return ReportsState(items: items, statusFilter: filter);
    });
  }

  Future<String?> create(Map<String, dynamic> payload) async {
    try {
      final id = await _repo.create(payload);
      await refresh();
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await _repo.updateStatus(id, status);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Report?> fetchDetail(String id) async {
    try {
      return await _repo.fetchById(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadAndLinkImages(String reportId, List<({String path, String name})> files) async {
    try {
      for (final f in files) {
        final url = await _repo.uploadImage(reportId, f.path, f.name);
        if (url == null) continue;
        await _repo.linkImage(reportId, {'file_url': url, 'file_name': f.name});
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

