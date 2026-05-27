import 'package:dio/dio.dart';

class UploadsRepository {
  UploadsRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> deleteUpload(int id) async {
    await _dio.delete('upload/$id');
  }
}

