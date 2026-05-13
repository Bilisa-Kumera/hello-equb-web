import 'package:ekubee/features/app_update/domain/entities/update_check_info.dart';

abstract class UpdateState {
  const UpdateState();
}

class UpdateInitial extends UpdateState {
  const UpdateInitial();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.info);

  final UpdateCheckInfo info;
}

class UpdateNotAvailable extends UpdateState {
  const UpdateNotAvailable();
}

class UpdateError extends UpdateState {
  const UpdateError(this.message);

  final String message;
}
