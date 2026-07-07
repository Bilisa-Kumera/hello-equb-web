import 'package:helloequb/features/app_update/domain/entities/immediate_update_result.dart';
import 'package:helloequb/features/app_update/domain/entities/update_check_info.dart';

abstract class UpdateRepository {
  Future<UpdateCheckInfo> checkForUpdate();
  Future<ImmediateUpdateResult> performImmediateUpdate();
}
