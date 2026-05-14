import 'package:ekubee/features/app_update/domain/exceptions/update_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';

abstract class UpdateRemoteDataSource {
  Future<AppUpdateInfo> checkForUpdate();
  Future<AppUpdateResult> performImmediateUpdate();
}

class UpdateRemoteDataSourceImpl implements UpdateRemoteDataSource {
  UpdateRemoteDataSourceImpl({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;

  @override
  Future<AppUpdateInfo> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const UpdateException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'In-app updates are supported only on Android.',
      );
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      _logger.i(
        'Update check complete: availability=${info.updateAvailability.name}, '
        'immediateAllowed=${info.immediateUpdateAllowed}, '
        'versionCode=${info.availableVersionCode}',
      );
      return info;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Update check failed', error: e, stackTrace: stackTrace);
      throw _mapPlatformException(e);
    } catch (e, stackTrace) {
      _logger.e('Unexpected update check error',
          error: e, stackTrace: stackTrace);
      throw UpdateException(
        code: 'UNKNOWN_CHECK_ERROR',
        message: 'Failed to check for app update.',
        cause: e,
      );
    }
  }

  @override
  Future<AppUpdateResult> performImmediateUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const UpdateException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'In-app updates are supported only on Android.',
      );
    }

    try {
      final result = await InAppUpdate.performImmediateUpdate();
      _logger.i('Immediate update result: $result');
      return result;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('Immediate update failed', error: e, stackTrace: stackTrace);
      throw _mapPlatformException(e);
    } catch (e, stackTrace) {
      _logger.e('Unexpected immediate update error',
          error: e, stackTrace: stackTrace);
      throw UpdateException(
        code: 'UNKNOWN_IMMEDIATE_UPDATE_ERROR',
        message: 'Failed to perform immediate update.',
        cause: e,
      );
    }
  }

  UpdateException _mapPlatformException(PlatformException exception) {
    final code = exception.code;
    switch (code) {
      case 'ERROR_API_NOT_AVAILABLE':
        return UpdateException(
          code: code,
          message:
              'Update API is not available on this device. Please use a Play Store installed app.',
          cause: exception,
        );
      case 'ERROR_PLAY_STORE_NOT_FOUND':
        return UpdateException(
          code: code,
          message: 'Google Play Store is missing on this device.',
          cause: exception,
        );
      case 'ERROR_APP_NOT_OWNED':
        return UpdateException(
          code: code,
          message:
              'This app is not owned by the current Play Store account, so updates are unavailable.',
          cause: exception,
        );
      case 'REQUIRE_FLEXIBLE_UPDATE':
        return UpdateException(
          code: code,
          message:
              'Immediate update is not allowed for this release. Please allow immediate update in Play Console.',
          cause: exception,
        );
      case 'USER_DENIED_UPDATE':
        return UpdateException(
          code: code,
          message: 'Update was canceled by the user.',
          cause: exception,
        );
      default:
        return UpdateException(
          code: code,
          message:
              exception.message ?? 'In-app update failed with unknown error.',
          cause: exception,
        );
    }
  }
}
