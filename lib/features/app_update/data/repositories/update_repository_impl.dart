import 'package:helloequb/features/app_update/data/datasources/update_remote_data_source.dart';
import 'package:helloequb/features/app_update/domain/entities/immediate_update_result.dart';
import 'package:helloequb/features/app_update/domain/entities/update_check_info.dart';
import 'package:helloequb/features/app_update/domain/repositories/update_repository.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  const UpdateRepositoryImpl(this._remoteDataSource);

  final UpdateRemoteDataSource _remoteDataSource;

  @override
  Future<UpdateCheckInfo> checkForUpdate() async {
    final info = await _remoteDataSource.checkForUpdate();

    return UpdateCheckInfo(
      isUpdateAvailable:
          info.updateAvailability == UpdateAvailability.updateAvailable,
      isImmediateUpdateAllowed: info.immediateUpdateAllowed,
      availableVersionCode: info.availableVersionCode,
    );
  }

  @override
  Future<ImmediateUpdateResult> performImmediateUpdate() async {
    final result = await _remoteDataSource.performImmediateUpdate();

    switch (result) {
      case AppUpdateResult.success:
        return ImmediateUpdateResult.success;
      case AppUpdateResult.userDeniedUpdate:
        return ImmediateUpdateResult.userDenied;
      case AppUpdateResult.inAppUpdateFailed:
        return ImmediateUpdateResult.failed;
    }
  }
}
