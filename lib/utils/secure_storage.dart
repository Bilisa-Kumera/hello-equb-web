import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';

class SecureStorageHelper {
  SecureStorageHelper._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final GetStorage _fallbackStorage = GetStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  static const String _userIdKey = 'user_id';

  static Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      await _fallbackStorage.write(key, value);
      return;
    }

    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      await _fallbackStorage.write(key, value);
    }
  }

  static Future<String?> _read(String key) async {
    if (kIsWeb) {
      return _fallbackStorage.read(key)?.toString();
    }

    try {
      final v = await _storage.read(key: key);
      if (v != null) return v;
    } catch (_) {
      // ignore and fallback
    }

    return _fallbackStorage.read(key)?.toString();
  }

  static Future<void> _delete(String key) async {
    if (!kIsWeb) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    }
    await _fallbackStorage.remove(key);
  }

  static Future<void> _deleteAll() async {
    if (!kIsWeb) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
    await _fallbackStorage.erase();
  }

  static Future<void> saveAccessToken(String token) async {
    await _write(_accessTokenKey, token);
  }

  static Future<String?> getAccessToken() async {
    return _read(_accessTokenKey);
  }

  static Future<void> deleteAccessToken() async {
    await _delete(_accessTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _write(_refreshTokenKey, token);
  }

  static Future<String?> getRefreshToken() async {
    return _read(_refreshTokenKey);
  }

  static Future<void> deleteRefreshToken() async {
    await _delete(_refreshTokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _write(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    return _read(_userIdKey);
  }

  static Future<void> deleteUserId() async {
    await _delete(_userIdKey);
  }

  

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() async {
    await _deleteAll();
  }
}
