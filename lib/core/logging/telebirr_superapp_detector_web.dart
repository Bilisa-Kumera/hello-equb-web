// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js' as js;

import 'package:helloequb/core/logging/app_logger.dart';

import 'telebirr_superapp_detector.dart';

Future<TelebirrDetectResult> detectTelebirrSuperApp({
  required String merchantId,
}) async {
  const location = 'lib/core/logging/telebirr_superapp_detector_web.dart';

  try {
    AppLogger.log(
      'Telebirr detect start | location=$location | merchantIdLen=${merchantId.length}',
    );
    AppLogger.log(
        'Telebirr detect step=bridge.lookup | checking window.consumerapp');
    final hasConsumerApp = js.context.hasProperty('consumerapp');

    if (!hasConsumerApp) {
      AppLogger.warn(
        'Telebirr detect failed | stage=bridge.lookup | location=$location | error=window.consumerapp not found | result=not inside Telebirr or bridge not injected yet',
      );
      return const TelebirrDetectResult(
        isWeb: true,
        hasConsumerApp: false,
        hasEvaluateFunction: false,
        authCalled: false,
        stage: 'bridge.lookup',
        location: location,
        result: 'failure',
        error: "window.consumerapp not found",
      );
    }

    final consumerApp = js.context['consumerapp'];

    if (consumerApp == null) {
      AppLogger.warn(
        'Telebirr detect failed | stage=bridge.lookup | location=$location | error=window.consumerapp is null | result=bridge object missing',
      );
      return const TelebirrDetectResult(
        isWeb: true,
        hasConsumerApp: false,
        hasEvaluateFunction: false,
        authCalled: false,
        stage: 'bridge.lookup',
        location: location,
        result: 'failure',
        error: "window.consumerapp is null",
      );
    }

    AppLogger.success(
      'Telebirr detect step=bridge.lookup | location=$location | result=window.consumerapp found',
    );
    final hasEvaluateFunction = consumerApp.hasProperty('evaluate');

    if (!hasEvaluateFunction) {
      AppLogger.warn(
        'Telebirr detect failed | stage=bridge.evaluate.lookup | location=$location | error=window.consumerapp.evaluate not found | result=auth request cannot be sent',
      );
      return const TelebirrDetectResult(
        isWeb: true,
        hasConsumerApp: true,
        hasEvaluateFunction: false,
        authCalled: false,
        stage: 'bridge.evaluate.lookup',
        location: location,
        result: 'failure',
        error: "window.consumerapp.evaluate not found",
      );
    }

    AppLogger.success(
      'Telebirr detect step=bridge.evaluate.lookup | location=$location | result=window.consumerapp.evaluate found',
    );

    return const TelebirrDetectResult(
      isWeb: true,
      hasConsumerApp: true,
      hasEvaluateFunction: true,
      authCalled: false,
      stage: 'bridge.evaluate.lookup',
      location: location,
      result: 'success.bridge_found',
      message: 'Telebirr bridge found. Token request is handled by token gate.',
    );
  } catch (e, st) {
    AppLogger.error(
      'Telebirr detect exception | stage=exception | location=$location | error=$e | stack=$st',
    );
    return TelebirrDetectResult(
      isWeb: true,
      hasConsumerApp: false,
      hasEvaluateFunction: false,
      authCalled: false,
      stage: 'exception',
      location: location,
      result: 'failure.exception',
      error: e.toString(),
    );
  }
}
