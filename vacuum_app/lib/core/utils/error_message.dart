import 'package:dio/dio.dart';

String friendlyErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException) {
    final status = error.response?.statusCode;

    if (_isConnectionIssue(error)) {
      return 'Unable to reach the server. Please check your internet connection and try again.';
    }

    if (status == 401) {
      return 'Your session has expired. Please log out and log in again.';
    }

    if (status == 403) {
      return 'You do not have permission to do this. Please contact your admin.';
    }

    if (status == 404) {
      return 'The item you are looking for was not found.';
    }

    if (status == 422 || status == 400) {
      final message = _messageFromBody(error);
      if (message != null) return message;
      return 'Some details are invalid. Please check the form and try again.';
    }

    if (status != null && status >= 500) {
      return 'The server is having trouble right now. Please try again later.';
    }

    final message = _messageFromBody(error);
    if (message != null) return message;
  }

  final text = error.toString().trim();
  if (text.isNotEmpty && text != 'Exception') return text;
  return fallback;
}

String? _messageFromBody(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) {
    final message = data['message'].toString().trim();
    if (message.isNotEmpty) return message;
  }
  if (data is Map && data['error'] != null) {
    final message = data['error'].toString().trim();
    if (message.isNotEmpty) return message;
  }
  final message = error.message?.trim();
  if (message != null && message.isNotEmpty) return message;
  return null;
}

bool _isConnectionIssue(DioException e) {
  return switch (e.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.badCertificate ||
    DioExceptionType.unknown => true,
    _ => false,
  };
}
