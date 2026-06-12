import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/reports_repository.dart';
import '../domain/report.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(dio: ref.read(dioProvider));
});

class ReportsState {
  const ReportsState({
    required this.items,
    required this.allItems,
    this.statusFilter = 'All',
    this.search = '',
  });

  final List<Report> items;
  final List<Report> allItems;
  final String statusFilter;
  final String search;

  ReportsState copyWith({
    List<Report>? items,
    List<Report>? allItems,
    String? statusFilter,
    String? search,
  }) {
    return ReportsState(
      items: items ?? this.items,
      allItems: allItems ?? this.allItems,
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
    );
  }
}

final reportsProvider = AsyncNotifierProvider<ReportsNotifier, ReportsState>(
  ReportsNotifier.new,
);

class ReportsNotifier extends AsyncNotifier<ReportsState> {
  ReportsRepository get _repo => ref.read(reportsRepositoryProvider);

  @override
  Future<ReportsState> build() async {
    final items = await _repo.fetchReports();
    return ReportsState(
      items: items,
      allItems: items,
    );
  }

  Future<void> setFilter(String status) async {
    final prev = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchReports(status: status);
      return _applySearch(
        ReportsState(
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
    state = AsyncData(
      _applySearch(
        prev.copyWith(search: nextQuery),
      ),
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    final filter = current?.statusFilter ?? 'All';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final items = await _repo.fetchReports(status: filter);
      return _applySearch(
        ReportsState(
          items: items,
          allItems: items,
          statusFilter: filter,
          search: current?.search ?? '',
        ),
      );
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

  Future<Uint8List?> fetchPdf(String id) async {
    try {
      return await _repo.fetchReportPdf(id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> downloadPdf(String id, String savePath) async {
    try {
      final result = await _repo.downloadReportPdf(id, savePath);
      return result.mimeType == 'application/pdf';
    } catch (_) {
      return false;
    }
  }

  Future<({String path, String mimeType})?> downloadPdfWithType(
    String id,
    String savePath,
  ) async {
    try {
      return await _repo.downloadReportPdf(id, savePath);
    } catch (_) {
      return null;
    }
  }

  Future<bool> uploadAndLinkImages(
    String reportId,
    List<({String path, String name})> files,
  ) async {
    try {
      for (final f in files) {
        final meta = await _repo.uploadImageMeta(reportId, f.path, f.name);
        if (meta == null) continue;
        await _repo.linkImage(reportId, {
          'file_url': meta['file_url'],
          'file_name': meta['file_name'] ?? f.name,
          'mime_type': meta['mime_type'],
          'file_size_bytes': meta['file_size_bytes'],
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createWithUploads({
    required Map<String, dynamic> payload,
    List<({String path, String name})> photos = const [],
    List<({String path, String name})> technicalReports = const [],
  }) async {
    try {
      final next = Map<String, dynamic>.from(payload);
      if (technicalReports.isNotEmpty) {
        final uploaded = await _repo.uploadTechnicalReports(technicalReports);
        next['technical_reports'] = [
          for (final f in uploaded)
            {
              'file_name': f.fileName,
              'file_url': f.fileUrl,
              'mime_type': f.mimeType,
              'file_size_bytes': f.fileSizeBytes,
            },
        ];
      } else {
        next['technical_reports'] = const [];
      }

      final id = await _repo.create(next);
      if (photos.isNotEmpty) {
        await uploadAndLinkImages(id, photos);
      }
      await refresh();
      return id;
    } catch (_) {
      return null;
    }
  }

  ReportsState _applySearch(ReportsState state) {
    final query = state.search.trim().toLowerCase();
    if (query.isEmpty) return state;
    final filtered = state.allItems.where((r) {
      return [
        r.title,
        r.status,
        r.jobTitle,
        r.clientName,
        r.technicianName,
        r.companyName ?? '',
        r.contactPerson ?? '',
        r.location ?? '',
        r.serialNo ?? '',
        r.poNumber ?? '',
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
    return state.copyWith(items: filtered);
  }
}
