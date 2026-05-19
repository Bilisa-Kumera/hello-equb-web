import 'package:dio/dio.dart';
import 'package:helloequb/core/storage/secure_token_storage.dart';

class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._tokenStorage);

  final SecureTokenStorage _tokenStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Don't block requests if storage is unavailable.
    }

    handler.next(options);
  }
}

