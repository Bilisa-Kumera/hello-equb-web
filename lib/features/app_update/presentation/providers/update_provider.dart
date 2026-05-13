import 'dart:async';
import 'dart:io';

import 'package:ekubee/features/app_update/domain/entities/immediate_update_result.dart';
import 'package:ekubee/features/app_update/domain/exceptions/update_exception.dart';
import 'package:ekubee/features/app_update/domain/repositories/update_repository.dart';
import 'package:ekubee/features/app_update/domain/usecases/check_for_update_use_case.dart';
import 'package:ekubee/features/app_update/presentation/providers/update_state.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class UpdateProvider extends ChangeNotifier {
  UpdateProvider({
    required CheckForUpdateUseCase checkForUpdateUseCase,
    required UpdateRepository updateRepository,
    Logger? logger,
  })  : _checkForUpdateUseCase = checkForUpdateUseCase,
        _updateRepository = updateRepository,
        _logger = logger ?? Logger();

  final CheckForUpdateUseCase _checkForUpdateUseCase;
  final UpdateRepository _updateRepository;
  final Logger _logger;

  UpdateState _state = const UpdateInitial();
  bool _hasCheckedOnce = false;

  UpdateState get state => _state;
  bool get isChecking => _state is UpdateChecking;

  Future<void> checkForUpdateOnStartup() async {
    if (_hasCheckedOnce) {
      _logger.d('Update check skipped: already checked once.');
      return;
    }
    _hasCheckedOnce = true;

    if (kIsWeb || !Platform.isAndroid) {
  _logger.d('Update check skipped: non-Android/web platform.');
  _setState(const UpdateNotAvailable());
  return;
}

    _setState(const UpdateChecking());

    try {
      final info =
          await _checkForUpdateUseCase().timeout(const Duration(seconds: 20));

      if (!info.isUpdateAvailable) {
        _setState(const UpdateNotAvailable());
        return;
      }

      _setState(UpdateAvailable(info));

      if (!info.isImmediateUpdateAllowed) {
        _setState(const UpdateError(
          'Update is available, but immediate update is not allowed.',
        ));
        return;
      }

      final immediateUpdateResult =
          await _updateRepository.performImmediateUpdate().timeout(
                const Duration(seconds: 60),
              );

      switch (immediateUpdateResult) {
        case ImmediateUpdateResult.success:
          _logger.i('Immediate update completed successfully.');
          _setState(const UpdateNotAvailable());
          return;
        case ImmediateUpdateResult.userDenied:
          _setState(const UpdateError('Update was canceled by the user.'));
          return;
        case ImmediateUpdateResult.failed:
          _setState(const UpdateError('Immediate update failed.'));
          return;
      }
    } on TimeoutException catch (e, stackTrace) {
      _logger.e('Update flow timeout', error: e, stackTrace: stackTrace);
      _setState(const UpdateError(
        'Update check timed out. Please check your connection and try again.',
      ));
    } on UpdateException catch (e, stackTrace) {
      _logger.e('UpdateException in update flow', error: e, stackTrace: stackTrace);
      _setState(UpdateError(e.message));
    } catch (e, stackTrace) {
      _logger.e('Unexpected update flow error', error: e, stackTrace: stackTrace);
      _setState(const UpdateError(
          'Unable to check for updates right now. Please try again later.'));
    }
  }

  void _setState(UpdateState nextState) {
    _state = nextState;
    notifyListeners();
  }
}
