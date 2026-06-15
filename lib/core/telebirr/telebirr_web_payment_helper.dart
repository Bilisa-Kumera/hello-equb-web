import 'package:flutter/foundation.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/core/telebirr/telebirr_mini_app_detector.dart';

/// Web-only helper for Telebirr Mini App payments.
///
/// This is a **companion** to the existing [TelebirrService] (which is Android-only).
///
/// Usage pattern (in any screen):
///
/// ```dart
/// if (kIsWeb) {
///   final helper = TelebirrWebPaymentHelper();
///   if (helper.isInsideTelebirrMiniApp) {
///     final result = await helper.startPayment(rawRequestFromBackend);
///     // handle result
///   } else {
///     // show "Please open inside Telebirr" message
///   }
/// } else {
///   // existing Android path using TelebirrService + MethodChannel
/// }
/// ```
class TelebirrWebPaymentHelper {
  TelebirrWebPaymentHelper() : _detector = createTelebirrMiniAppDetector();

  final TelebirrMiniAppDetector _detector;

  /// Quick check: are we inside the Telebirr Mini App on web?
  bool get isInsideTelebirrMiniApp => kIsWeb && _detector.isTelebirrMiniApp();

  /// Returns detailed bridge information (useful for debug overlay).
  Map<String, dynamic> getBridgeInfo() => _detector.getBridgeSnapshot();

  /// Attempts to get the current mini-app auth token (if available).
  Future<String?> getMiniAppToken({String? appId}) async {
    if (!kIsWeb) return null;
    return _detector.getMiniAppToken(appId: appId);
  }

  /// Starts a Telebirr payment using the injected bridge (consumerapp or xm).
  ///
  /// [rawRequest] = the `raw_request` string you received from your backend
  /// after calling the payment initiation endpoint.
  Future<TelebirrWebPaymentResult> startPayment(dynamic rawRequest) async {
    if (!kIsWeb) {
      return const TelebirrWebPaymentResult(
        success: false,
        errorCode: 'NOT_WEB',
        message: 'This helper only works on Flutter Web.',
      );
    }

    if (!_detector.isTelebirrMiniApp()) {
      AppLogger.warn('[TelebirrWebPayment] Not inside Telebirr Mini App');
      return const TelebirrWebPaymentResult(
        success: false,
        errorCode: 'NOT_IN_TELEBIRR',
        message:
            'App is not running inside Telebirr Mini App. Open the web app from within Telebirr.',
      );
    }

    AppLogger.log('[TelebirrWebPayment] Starting Telebirr payment via bridge...');

    try {
      final rawResult =
          await _detector.startTelebirrPayment(rawRequest);

      final bool ok = rawResult['success'] == true;

      return TelebirrWebPaymentResult(
        success: ok,
        data: rawResult,
        errorCode: ok ? null : (rawResult['error']?.toString() ?? 'BRIDGE_ERROR'),
        message: ok
            ? 'Payment initiated via Telebirr bridge'
            : (rawResult['message']?.toString() ??
                'Telebirr bridge rejected the payment request'),
      );
    } catch (e, st) {
      AppLogger.error('[TelebirrWebPayment] Exception: $e\n$st');
      return TelebirrWebPaymentResult(
        success: false,
        errorCode: 'EXCEPTION',
        message: e.toString(),
      );
    }
  }
}

/// Result object returned by [TelebirrWebPaymentHelper.startPayment].
class TelebirrWebPaymentResult {
  const TelebirrWebPaymentResult({
    required this.success,
    this.data,
    this.errorCode,
    this.message,
  });

  final bool success;
  final Map<String, dynamic>? data;
  final String? errorCode;
  final String? message;

  @override
  String toString() =>
      'TelebirrWebPaymentResult(success: $success, error: $errorCode, msg: $message)';
}
