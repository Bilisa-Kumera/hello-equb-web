import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/core/superapp/superapp_bridge.dart';
import 'package:helloequb/features/superapp_auth/domain/usecases/attempt_superapp_auto_login.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_event.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_state.dart';

class SuperAppAuthBloc extends Bloc<SuperAppAuthEvent, SuperAppAuthState> {
  SuperAppAuthBloc({
    required AttemptSuperAppAutoLogin attemptAutoLogin,
    required bool Function() isSuperAppAvailable,
  })  : _attemptAutoLogin = attemptAutoLogin,
        _isSuperAppAvailable = isSuperAppAvailable,
        super(const SuperAppAuthInitial()) {
    on<SuperAppAuthStarted>(_onStarted);
  }

  final AttemptSuperAppAutoLogin _attemptAutoLogin;
  final bool Function() _isSuperAppAvailable;

  Future<void> _onStarted(
    SuperAppAuthStarted event,
    Emitter<SuperAppAuthState> emit,
  ) async {
    AppLogger.log('auth started');
    if (!kIsWeb) {
      emit(const SuperAppAuthNotInSuperApp());
      return;
    }

    if (!_isSuperAppAvailable()) {
      AppLogger.warn('bridge not detected yet; waiting briefly...');
      final ok = await createSuperAppBridge().waitUntilAvailable(
        timeout: const Duration(seconds: 12),
        pollInterval: const Duration(milliseconds: 140),
      );
      if (!ok) {
        AppLogger.log('not in SuperApp WebView');
        emit(const SuperAppAuthNotInSuperApp());
        return;
      }
    }

    if (event.merchantAppId.trim().isEmpty) {
      emit(const SuperAppAuthFailure(
        'Missing merchant app id (set MERCHANT_APP_ID or SUPERAPP_APP_ID in .env).',
      ));
      return;
    }

    emit(const SuperAppAuthInProgress());

    try {
      await _attemptAutoLogin(merchantAppId: event.merchantAppId.trim());
      emit(const SuperAppAuthSuccess());
    } catch (e) {
      AppLogger.error('auth failed: $e');
      emit(SuperAppAuthFailure(e.toString()));
    }
  }
}
