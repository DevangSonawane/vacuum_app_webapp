import 'package:dio/dio.dart';
import 'dart:io';

import '../domain/technician.dart';

const _maxTechnicianDocumentBytes = 20 * 1024 * 1024;

class TechniciansRepository {
  TechniciansRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<String> login({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    final payload = <String, dynamic>{'password': password};

    if (trimmed.contains('@')) {
      payload['email'] = trimmed;
    } else {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      payload['phone_number'] = digits.startsWith('91')
          ? '+$digits'
          : '+91$digits';
    }

    final res = await _dio.post('technicians/login', data: payload);
    final data = res.data;
    if (data is String) return data;
    if (data is Map && data['token'] != null) return data['token'].toString();
    return '';
  }

  Future<List<Technician>> fetchTechnicians({
    int limit = 50,
    String search = '',
    String status = '',
  }) async {
    final response = await _dio.get(
      'technicians',
      queryParameters: {
        'limit': limit,
        if (search.isNotEmpty) 'search': search,
        if (status.isNotEmpty) 'status': status,
      },
    );

    final root = _asMap(response.data);
    if (root['success'] == true) {
      final list = _asList(root['data']);
      return list
          .whereType<Map>()
          .map((e) => Technician.fromJson(_asMap(e)))
          .toList();
    }

    final list = _asList(root['data']);
    if (list.isNotEmpty) {
      return list
          .whereType<Map>()
          .map((e) => Technician.fromJson(_asMap(e)))
          .toList();
    }

    throw Exception(
      (root['message'] ?? 'Failed to load technicians').toString(),
    );
  }

  Future<Technician> fetchById(int id) async {
    final response = await _dio.get('technicians/$id');
    final root = _asMap(response.data);
    final data = root['success'] == true
        ? _asMap(root['data'])
        : _asMap(root['data'] ?? root);
    return Technician.fromJson(data);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    await _dio.post('technicians', data: payload);
  }

  Future<Map<String, dynamic>> uploadTechnicianDocument({
    required String filePath,
    required String filename,
    String? documentType,
    String? documentName,
    String? expiryDate,
    String? notes,
  }) async {
    final file = File(filePath);
    final size = await file.length();
    if (size > _maxTechnicianDocumentBytes) {
      throw Exception(
        'Document is too large. Please choose a file smaller than 20 MB.',
      );
    }

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'files',
        await MultipartFile.fromFile(filePath, filename: filename),
      ),
    );

    try {
      final response = await _dio.post(
        'upload/technician-documents',
        queryParameters: {
          if (documentType != null && documentType.trim().isNotEmpty)
            'document_type': documentType.trim(),
          if (documentName != null && documentName.trim().isNotEmpty)
            'document_name': documentName.trim(),
          if (expiryDate != null && expiryDate.trim().isNotEmpty)
            'expiry_date': expiryDate.trim(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
        data: formData,
      );

      final root = _asMap(response.data);
      final uploaded = _asList(root['data']);
      if (uploaded.isEmpty) {
        throw Exception(
          (root['message'] ?? 'Failed to upload technician document')
              .toString(),
        );
      }
      return _asMap(uploaded.first);
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception(
          'Document is too large. Please choose a file smaller than 20 MB.',
        );
      }
      final root = _asMap(e.response?.data);
      final message = (root['message'] ?? e.message ?? 'Upload failed')
          .toString();
      throw Exception(message);
    }
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    await _dio.put('technicians/$id', data: payload);
  }

  Future<void> delete(int id) async {
    await _dio.delete('technicians/$id');
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
    return <String, dynamic>{};
  }

  static List<dynamic> _asList(dynamic v) => v is List ? v : const [];
}
