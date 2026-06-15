import 'dart:async';
import 'dart:convert';

import 'telebirr_superapp_detector_stub.dart'
    if (dart.library.html) 'telebirr_superapp_detector_web.dart';

class TelebirrSuperAppDetector {
  static Future<TelebirrDetectResult> detect({
    required String merchantId,
  }) {
    return detectTelebirrSuperApp(merchantId: merchantId);
  }
}

class TelebirrDetectResult {
  final bool isWeb;
  final bool hasConsumerApp;
  final bool hasEvaluateFunction;
  final bool authCalled;
  final String? stage;
  final String? location;
  final String? result;
  final String? token;
  final String? message;
  final String? error;

  const TelebirrDetectResult({
    required this.isWeb,
    required this.hasConsumerApp,
    required this.hasEvaluateFunction,
    required this.authCalled,
    this.stage,
    this.location,
    this.result,
    this.token,
    this.message,
    this.error,
  });

  bool get hasTelebirrBridge => isWeb && hasConsumerApp && hasEvaluateFunction;

  bool get authSucceeded =>
      hasTelebirrBridge && error == null && token != null && token!.isNotEmpty;

  bool get isTelebirrSuperApp => authSucceeded;

  @override
  String toString() {
    return jsonEncode({
      "isWeb": isWeb,
      "hasConsumerApp": hasConsumerApp,
      "hasEvaluateFunction": hasEvaluateFunction,
      "authCalled": authCalled,
      "hasTelebirrBridge": hasTelebirrBridge,
      "authSucceeded": authSucceeded,
      "isTelebirrSuperApp": isTelebirrSuperApp,
      "stage": stage,
      "location": location,
      "result": result,
      "token": token,
      "message": message,
      "error": error,
    });
  }
}
