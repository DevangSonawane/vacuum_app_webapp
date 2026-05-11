import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/report.dart';

class ReportsRepository {
  ReportsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Report>> fetchReports({String status = ''}) async {
    final response = await _dio.get(
      'reports',
      queryParameters: {
        'limit': 100,
        if (status.isNotEmpty && status != 'All') 'status': status,
      },
    );
    final root = _asMap(response.data);
    final list = _asList(root['data']);
    return list
        .whereType<Map>()
        .map((e) => Report.fromJson(e.map((k, v) => MapEntry(k.toString(), v))))
        .toList();
  }

  Future<Report> fetchById(String id) async {
    final response = await _dio.get('reports/$id');
    return Report.fromJson(_asMap(_asMap(response.data)['data']));
  }

  Future<String> create(Map<String, dynamic> payload) async {
    final response = await _dio.post('reports', data: payload);
    final root = _asMap(response.data);
    final data = _asMap(root['data'] ?? root);
    final id = (data['id'] ?? '').toString();
    return id;
  }

  Future<void> updateStatus(String id, String status) =>
      _dio.patch('reports/$id/status', data: {'status': status});

  Future<List<TechnicalReportFile>> uploadTechnicalReports(
    List<({String path, String name})> files,
  ) async {
    final formData = FormData();
    for (final f in files) {
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(f.path, filename: f.name),
        ),
      );
    }

    final response = await _dio.post(
      'upload/technical-reports',
      data: formData,
    );
    final uploaded = _asList(_asMap(response.data)['data']);
    return uploaded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .map(TechnicalReportFile.fromJson)
        .toList();
  }

  Future<String?> uploadImage(
    String reportId,
    String filePath,
    String filename,
  ) async {
    final meta = await uploadImageMeta(reportId, filePath, filename);
    return meta?['file_url']?.toString();
  }

  Future<Map<String, dynamic>?> uploadImageMeta(
    String reportId,
    String filePath,
    String filename,
  ) async {
    final formData = FormData.fromMap({
      'images': await MultipartFile.fromFile(filePath, filename: filename),
    });
    final response = await _dio.post(
      'upload',
      queryParameters: {'entity_type': 'report', 'entity_id': reportId},
      data: formData,
    );
    final uploaded = _asList(_asMap(response.data)['data']);
    if (uploaded.isEmpty) return null;
    return _asMap(uploaded.first);
  }

  Future<void> linkImage(String reportId, Map<String, dynamic> data) =>
      _dio.post('reports/$reportId/images', data: data);

  Future<Uint8List> fetchReportPdf(String id) async {
    final response = await _dio.get<List<int>>(
      'reports/$id/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {'Accept': 'application/pdf'},
      ),
    );
    final bytes = response.data;
    if (bytes == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Empty PDF response',
      );
    }
    return Uint8List.fromList(bytes);
  }

  Future<({String path, String mimeType})> downloadReportPdf(
    String id,
    String savePath,
  ) async {
    Response<List<int>> response;
    try {
      response = await _dio.get<List<int>>(
        'reports/$id/pdf',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 1),
          headers: const {
            'Accept': 'application/pdf, text/html;q=0.9, */*;q=0.8',
          },
        ),
      );
    } on DioException catch (e) {
      debugPrint('[PDF] download failed: ${e.type} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[PDF] download failed: $e');
      rethrow;
    }

    final rawBytes = response.data;
    if (rawBytes == null || rawBytes.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Empty response body',
      );
    }

    final file = File(savePath);
    await file.writeAsBytes(rawBytes, flush: true);
    final bytes = Uint8List.fromList(rawBytes);
    final probeLen = bytes.length < 1024 ? bytes.length : 1024;
    final isPdf = _containsPdfHeader(bytes, probeLen);
    if (isPdf) {
      return (path: savePath, mimeType: 'application/pdf');
    }

    final isHtml = _looksLikeHtml(bytes, probeLen);
    if (isHtml) {
      final htmlPath = savePath.endsWith('.pdf')
          ? '${savePath.substring(0, savePath.length - 4)}.html'
          : '$savePath.html';
      try {
        await file.rename(htmlPath);
      } catch (_) {
        // If rename fails, still return the original path.
        return (path: savePath, mimeType: 'text/html');
      }
      return (path: htmlPath, mimeType: 'text/html');
    }

    {
      try {
        await file.delete();
      } catch (_) {}
      throw DioException(
        requestOptions: RequestOptions(path: 'reports/$id/pdf'),
        error: 'Downloaded file is neither PDF nor HTML',
      );
    }
  }

  static bool _containsPdfHeader(Uint8List bytes, int limit) {
    if (limit < 4) return false;
    for (int i = 0; i <= limit - 4; i++) {
      if (bytes[i] == 0x25 && // %
          bytes[i + 1] == 0x50 && // P
          bytes[i + 2] == 0x44 && // D
          bytes[i + 3] == 0x46) {
        return true;
      }
    }
    return false;
  }

  static bool _looksLikeHtml(Uint8List bytes, int limit) {
    if (limit <= 0) return false;
    final prefix = String.fromCharCodes(bytes.take(limit)).toLowerCase();
    final trimmed = prefix.trimLeft();
    return trimmed.startsWith('<!doctype html') ||
        trimmed.startsWith('<html') ||
        trimmed.contains('<head') ||
        trimmed.contains('<body');
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
