import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:helloequb/core/network/dio_error_formatter.dart';
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

  /// Exchanges a mini-app token with Telebirr's H5 gateway (auth/token).
  Future<Map<String, dynamic>> exchangeTelebirrAuthToken({
    required String gatewayUrl,
    required String authToken,
  }) async {
    try {
      final response = await _dio.post(
        gatewayUrl,
        data: {'authToken': authToken},
        options: Options(contentType: Headers.jsonContentType),
      );

      return _normalizePayload(response.data);
    } on DioException catch (e) {
      throw StateError(formatTelebirrGatewayError(e, gatewayUrl: gatewayUrl));
    }
  }

  /// Posts `{"token": token}` to [url] and returns the raw response payload.
  /// Used by both Telebirr and CBEBirr Plus auto-login endpoints.
  Future<Map<String, dynamic>> autoLoginMiniApp({
    required String url,
    required String token,
  }) async {
    final response = await _dio.post(
      url,
      data: {'token': token},
      options: Options(contentType: Headers.jsonContentType),
    );
    return _normalizePayload(response.data);
  }

  Future<Map<String, dynamic>> loginForMiniApp({
    required String phoneNumber,
    required String appToken,
  }) async {
    final response = await _dio.post(
      tokenExchangePath,
      data: {
        // Some backends expect `authToken`, others expect `token`.
        // Send both for maximum compatibility.
        'authToken': appToken,
        'token': appToken,
        if (phoneNumber.trim().isNotEmpty) 'phoneNumber': phoneNumber.trim(),
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
    if (user is String) {
      final parsedUser = _parseLooseMapString(user);
      if (parsedUser.isNotEmpty) return parsedUser;
    }

    final openId = _stringAt(payload, [
          'open_id',
          'openId',
          'data.open_id',
          'data.openId',
          'biz_content.open_id',
          'biz_content.openId',
        ]) ??
        _stringInLooseMapAt(
            payload,
            [
              'authRes',
              'data.authRes',
            ],
            'open_id');
    final identityId = _stringAt(payload, [
          'identityId',
          'identity_id',
          'data.identityId',
          'data.identity_id',
          'biz_content.identityId',
          'biz_content.identity_id',
        ]) ??
        _stringInLooseMapAt(
            payload,
            [
              'authRes',
              'data.authRes',
            ],
            'identityId');
    if (openId != null || identityId != null) {
      return <String, dynamic>{
        if (openId != null) 'open_id': openId,
        if (identityId != null) 'identityId': identityId,
      };
    }

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

  String? _stringInLooseMapAt(
    Map<String, dynamic> payload,
    List<String> paths,
    String key,
  ) {
    for (final path in paths) {
      final v = _getPath(payload, path);
      if (v is! String || v.trim().isEmpty) continue;
      final parsed = _parseLooseMapString(v);
      final value = parsed[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Map<String, dynamic> _parseLooseMapString(String value) {
    final trimmed = value.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) {
      return const <String, dynamic>{};
    }

    final content = trimmed.substring(1, trimmed.length - 1);
    final map = <String, dynamic>{};
    final entryPattern = RegExp(
      r'([A-Za-z_][A-Za-z0-9_]*):\s*(.*?)(?=,\s*[A-Za-z_][A-Za-z0-9_]*:\s*|$)',
    );

    for (final match in entryPattern.allMatches(content)) {
      final key = match.group(1);
      final rawValue = match.group(2)?.trim();
      if (key == null || rawValue == null) continue;
      map[key] = _parseLooseValue(rawValue);
    }
    return map;
  }

  dynamic _parseLooseValue(String value) {
    if (value == 'null') return null;
    if (value == 'true') return true;
    if (value == 'false') return false;
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    return value;
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
