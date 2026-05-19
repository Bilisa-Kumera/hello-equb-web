import 'package:helloequb/features/superapp_auth/domain/entities/session.dart';

abstract class SuperAppAuthRepository {
  bool get isSuperAppAvailable;

  Future<Session> loginWithSuperApp({required String merchantAppId});
}

