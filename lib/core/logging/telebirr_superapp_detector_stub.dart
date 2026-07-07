import 'telebirr_superapp_detector.dart';

Future<TelebirrDetectResult> detectTelebirrSuperApp({
  required String merchantId,
}) async {
  return const TelebirrDetectResult(
    isWeb: false,
    hasConsumerApp: false,
    hasEvaluateFunction: false,
    authCalled: false,
    error: "Not running on Flutter Web",
  );
}