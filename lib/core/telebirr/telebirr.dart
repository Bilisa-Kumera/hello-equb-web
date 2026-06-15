/// Telebirr Mini App integration (Web only).
///
/// This library provides safe, web-only detection and bridge access
/// for running inside the Telebirr Mini App (Telebirr's WebView).
///
/// ## Key Points
/// - **Never import the `_web.dart` or `_stub.dart` files directly.**
/// - Use `kIsWeb` + this library to keep Android code 100% untouched.
/// - The stub implementation (used on Android) always returns safe no-op values.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:flutter/foundation.dart';
/// import 'package:helloequb/core/telebirr/telebirr.dart';
///
/// // Detection
/// final detector = createTelebirrMiniAppDetector();
/// if (kIsWeb && detector.isTelebirrMiniApp()) {
///   // Running inside Telebirr Mini App
/// }
///
/// // Payment helper (recommended)
/// final paymentHelper = TelebirrWebPaymentHelper();
/// if (paymentHelper.isInsideTelebirrMiniApp) {
///   final result = await paymentHelper.startPayment(rawRequest);
/// }
/// ```
library telebirr;

export 'telebirr_mini_app_detector.dart';
export 'telebirr_web_payment_helper.dart';
