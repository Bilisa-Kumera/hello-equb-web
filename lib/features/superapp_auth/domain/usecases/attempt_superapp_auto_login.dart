import 'package:helloequb/features/superapp_auth/domain/entities/session.dart';
import 'package:helloequb/features/superapp_auth/domain/repositories/superapp_auth_repository.dart';

class AttemptSuperAppAutoLogin {
  const AttemptSuperAppAutoLogin(this._repository);

  final SuperAppAuthRepository _repository;

  Future<Session> call({
    required String appToken,
    required String phoneNumber,
  }) {
    return _repository.loginWithMiniAppToken(
      appToken: appToken,
      phoneNumber: phoneNumber,
    );
  }
}
