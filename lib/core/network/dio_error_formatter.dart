import 'package:dio/dio.dart';

/// User-facing message for Telebirr gateway auth/token failures.
String formatTelebirrGatewayError(
  Object error, {
  String? gatewayUrl,
}) {
  if (error is DioException) {
    return _formatDioException(error, gatewayUrl: gatewayUrl);
  }

  final message = error.toString();
  if (message.contains('DioException')) {
    return _formatDioMessage(message, gatewayUrl: gatewayUrl);
  }

  return message;
}

String _formatDioException(DioException error, {String? gatewayUrl}) {
  final url = gatewayUrl ?? error.requestOptions.uri.toString();
  final status = error.response?.statusCode;

  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return 'Telebirr gateway connection failed for $url. '
          'The WebView cannot reach the payment gateway (network/CORS). '
          'Status: ${status ?? 'none'}.';
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Telebirr gateway request timed out for $url.';
    case DioExceptionType.badResponse:
      final body = error.response?.data;
      final detail = body is Map
          ? (body['errorMsg'] ?? body['message'] ?? body['msg'])?.toString()
          : body?.toString();
      return 'Telebirr gateway rejected the request (HTTP $status) for $url.'
          '${detail != null ? ' $detail' : ''}';
    case DioExceptionType.cancel:
      return 'Telebirr gateway request was cancelled for $url.';
    case DioExceptionType.badCertificate:
      return 'Telebirr gateway TLS certificate error for $url.';
  }
}

String _formatDioMessage(String message, {String? gatewayUrl}) {
  if (message.contains('connection error') ||
      message.contains('XMLHttpRequest onError')) {
    final url = gatewayUrl ??
        'https://api.hello-equb.com/api/v1/user/auth/auto-login-telebirr-miniapp';
    return 'Telebirr gateway connection failed for $url. '
        'The WebView cannot reach the payment gateway (network/CORS).';
  }
  return message;
}
