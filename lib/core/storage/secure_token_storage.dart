import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String accessTokenKey = 'accessToken';

  Future<void> writeAccessToken(String token) {
    return _storage.write(key: accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: accessTokenKey);
  }
}

