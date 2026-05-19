import 'package:dio/dio.dart';
import 'package:helloequb/core/network/auth_token_interceptor.dart';
import 'package:helloequb/core/storage/secure_token_storage.dart';

class DioFactory {
  DioFactory({
    SecureTokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? SecureTokenStorage();

  final SecureTokenStorage _tokenStorage;

  Dio createAuthedDio({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(AuthTokenInterceptor(_tokenStorage));
    return dio;
  }

  Dio createPlainDio({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
  }) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
  }
}

