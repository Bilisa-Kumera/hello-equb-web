import 'package:helloequb/features/superapp_auth/domain/entities/session.dart';

abstract class SuperAppAuthRepository {
  bool get isSuperAppAvailable;

  Future<String> getMiniAppToken({required String merchantAppId});

  Future<Session> loginWithMiniAppToken({
    required String appToken,
    required String phoneNumber,
  });

  /// Calls Telebirr gateway auth/token and returns parsed user identity fields.
  Future<Map<String, dynamic>> exchangeAppTokenWithTelebirrGateway({
    required String appToken,
  });
}
