import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;

import 'package:flutter/foundation.dart';
import 'package:helloequb/core/logging/app_logger.dart';

import 'telebirr_superapp_detector.dart';

Future<TelebirrDetectResult> detectTelebirrSuperApp({
  required String merchantId,
}) async {
  const location = 'lib/core/logging/telebirr_superapp_detector_web.dart';
  const callbackName = 'handleAuthCallback';
  final completer = Completer<TelebirrDetectResult>();

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
    AppLogger.log(
      'Telebirr detect step=callback.register | location=$location | callback=$callbackName',
    );

    js.context[callbackName] = js.JsFunction.withThis(
      (dynamic self, dynamic res, dynamic message, [dynamic data]) {
        debugPrint("TELEBIRR AUTH CALLBACK TOKEN: $res");
        debugPrint("TELEBIRR AUTH CALLBACK MESSAGE: $message");
        debugPrint("TELEBIRR AUTH CALLBACK DATA: $data");
        final tokenLen = res?.toString().length ?? 0;
        AppLogger.success(
          'Telebirr detect callback received | stage=callback.receive | location=$location | callback=$callbackName | tokenLen=$tokenLen | message=${message ?? '(none)'}',
        );
        AppLogger.log(
          'Telebirr detect callback data | stage=callback.receive | result=${data ?? '(no data)'}',
        );

        if (!completer.isCompleted) {
          completer.complete(
            TelebirrDetectResult(
              isWeb: true,
              hasConsumerApp: true,
              hasEvaluateFunction: true,
              authCalled: true,
              stage: 'callback.receive',
              location: location,
              result: tokenLen > 0
                  ? 'success.token_received'
                  : 'success.callback_without_token',
              token: res?.toString(),
              message: message?.toString(),
            ),
          );
        }
      },
    );

    final payload = jsonEncode({
      "functionName": "js_fun_h5GetAccessToken",
      "params": {
        "appid": merchantId,
        "functionCallBackName": callbackName,
      },
    });

    AppLogger.log(
      'Telebirr detect step=auth.call | location=$location | method=window.consumerapp.evaluate | functionName=js_fun_h5GetAccessToken | callback=$callbackName | payload=$payload',
    );
    consumerApp.callMethod('evaluate', [payload]);
    AppLogger.success(
      'Telebirr detect step=auth.call | location=$location | result=evaluate invoked, waiting for callback up to 8s',
    );

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        AppLogger.warn(
          'Telebirr detect timeout | stage=callback.wait | location=$location | callback=$callbackName | waited=8s | result=no callback received after evaluate call',
        );
        return const TelebirrDetectResult(
          isWeb: true,
          hasConsumerApp: true,
          hasEvaluateFunction: true,
          authCalled: true,
          stage: 'callback.wait',
          location: location,
          result: 'failure.timeout',
          error: "Telebirr callback timeout",
        );
      },
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
