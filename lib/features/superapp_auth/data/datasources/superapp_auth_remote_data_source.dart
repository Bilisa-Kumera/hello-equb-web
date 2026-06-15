import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:helloequb/features/superapp_auth/domain/entities/session.dart';

class SuperAppAuthRemoteDataSource {
  SuperAppAuthRemoteDataSource({
    required Dio dio,
    required this.tokenExchangePath,
    required this.profilePath,
  }) : _dio = dio;

  final Dio _dio;
  final String tokenExchangePath;
  final String profilePath;

  Future<Map<String, dynamic>> loginForMiniApp({
    required String phoneNumber,
    required String appToken,
  }) async {
    final response = await _dio.post(
      tokenExchangePath,
      data: {
        'phoneNumber': phoneNumber,
        'appToken': appToken,
      },
      options: Options(contentType: Headers.jsonContentType),
    );

    return _normalizePayload(response.data);
  }

  Session sessionFromLoginPayload(Map<String, dynamic> payload) {
    final accessToken = _stringAt(payload, [
          'accessToken',
          'token',
          'jwt',
          'data.accessToken',
          'data.token',
          'data.jwt',
        ]) ??
        '';

    if (accessToken.isEmpty) {
      throw StateError(
          'Token exchange succeeded but no access token returned.');
    }

    final refreshToken = _stringAt(payload, [
      'refreshToken',
      'data.refreshToken',
    ]);

    return Session(accessToken: accessToken, refreshToken: refreshToken);
  }

  Map<String, dynamic>? userFromLoginPayload(Map<String, dynamic> payload) {
    final user = _getPath(payload, 'user') ?? _getPath(payload, 'data.user');
    if (user is Map<String, dynamic>) return user;
    if (user is Map) return Map<String, dynamic>.from(user);
    return null;
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get(profilePath);
    final payload = _normalizePayload(response.data);
    return payload;
  }

  Map<String, dynamic> _normalizePayload(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{'data': data};
  }

  String? _stringAt(Map<String, dynamic> payload, List<String> paths) {
    for (final path in paths) {
      final v = _getPath(payload, path);
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  dynamic _getPath(Map<String, dynamic> map, String path) {
    dynamic current = map;
    for (final part in path.split('.')) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}
