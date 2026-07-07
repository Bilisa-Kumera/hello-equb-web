import 'telebirr_mini_app_detector_stub.dart'
    if (dart.library.html) 'telebirr_mini_app_detector_web.dart';

/// Telebirr Mini App detection and bridge access for Flutter Web.
///
/// This class is **Web-only**. On Android/iOS it always returns safe no-op values.
///
/// Usage (never import the _web or _stub files directly):
/// ```dart
/// import 'package:helloequb/core/telebirr/telebirr_mini_app_detector.dart';
///
/// final detector = createTelebirrMiniAppDetector();
/// if (detector.isTelebirrMiniApp()) {
///   final token = await detector.getMiniAppToken();
/// }
/// ```
abstract class TelebirrMiniAppDetector {
  /// Returns true only when running inside the Telebirr Mini App WebView on web.
  bool isTelebirrMiniApp();

  /// Returns a snapshot of detected bridge objects for diagnostics.
  Map<String, dynamic> getBridgeSnapshot();

  /// Requests a mini-app auth token from the Telebirr bridge.
  ///
  /// Returns null if not inside Telebirr or if the bridge call fails.
  Future<String?> getMiniAppToken({String? appId});

  /// Starts a Telebirr in-app payment using the native bridge (web only).
  ///
  /// [rawRequest] is typically the `raw_request` string returned by your backend
  /// (the long base64/URL-encoded string containing appid, sign, etc.).
  ///
  /// Returns a map with at least `{ 'success': bool, ... }`.
  Future<Map<String, dynamic>> startTelebirrPayment(dynamic rawRequest);

  /// Optional: returns the detected consumerapp object reference (for advanced use).
  dynamic get consumerappBridge;

  /// Optional: returns the detected xm bridge reference.
  dynamic get xmBridge;
}

TelebirrMiniAppDetector createTelebirrMiniAppDetector() =>
    createTelebirrMiniAppDetectorImpl();
