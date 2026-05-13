import 'package:ekubee/features/app_update/domain/entities/update_check_info.dart';
import 'package:ekubee/features/app_update/domain/repositories/update_repository.dart';

class CheckForUpdateUseCase {
  const CheckForUpdateUseCase(this._repository);

  final UpdateRepository _repository;

  Future<UpdateCheckInfo> call() {
    return _repository.checkForUpdate();
  }
}
