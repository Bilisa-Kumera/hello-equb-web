import 'package:helloequb/features/superapp_auth/domain/entities/session.dart';

abstract class SuperAppAuthRepository {
  bool get isSuperAppAvailable;

  Future<String> getMiniAppToken({required String merchantAppId});

  Future<Session> loginWithMiniAppToken({
    required String appToken,
    required String phoneNumber,
  });
}
