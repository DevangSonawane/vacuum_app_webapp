import 'package:dio/dio.dart';

String friendlyErrorMessage(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final bodyMessage = _messageFromBody(error);

    if (_isConnectionIssue(error)) {
      return 'Unable to reach the server. Please check your internet connection and try again.';
    }

    if (status == 401) {
      return 'Your session has expired. Please log out and log in again.';
    }

    if (status == 403) {
      if (_looksLikeSessionExpiry(bodyMessage)) {
        return 'Your session has expired. Please log in again.';
      }
      if (bodyMessage != null && bodyMessage.isNotEmpty) {
        return bodyMessage;
      }
      return 'You do not have permission to do this. Please contact your admin.';
    }

    if (status == 404) {
      return 'The item you are looking for was not found.';
    }

    if (status == 422 || status == 400) {
      if (bodyMessage != null) return bodyMessage;
      return 'Some details are invalid. Please check the form and try again.';
    }

    if (status != null && status >= 500) {
      return 'The server is having trouble right now. Please try again later.';
    }

    if (bodyMessage != null) return bodyMessage;
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

bool _looksLikeSessionExpiry(String? message) {
  final text = (message ?? '').toLowerCase();
  if (text.isEmpty) return false;
  return text.contains('session') ||
      text.contains('expired') ||
      text.contains('token') ||
      text.contains('login') ||
      text.contains('log in') ||
      text.contains('unauthor') ||
      text.contains('auth');
}
