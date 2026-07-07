import 'telebirr_mini_app_detector.dart';

/// Stub implementation used on Android / iOS / Desktop.
///
/// All methods safely return "not in Telebirr" behavior.
/// This file is **never** used on Flutter Web.
class _TelebirrMiniAppDetectorStub implements TelebirrMiniAppDetector {
  @override
  bool isTelebirrMiniApp() => false;

  @override
  Map<String, dynamic> getBridgeSnapshot() => const {
        'platform': 'non-web',
        'isTelebirrMiniApp': false,
        'reason': 'Stub implementation (Android/iOS/Desktop)',
      };

  @override
  Future<String?> getMiniAppToken({String? appId}) async => null;

  @override
  Future<Map<String, dynamic>> startTelebirrPayment(dynamic rawRequest) async =>
      const {
        'success': false,
        'error': 'NOT_WEB',
        'message': 'Telebirr Mini App bridge is only available on Flutter Web.',
      };

  @override
  dynamic get consumerappBridge => null;

  @override
  dynamic get xmBridge => null;
}

TelebirrMiniAppDetector createTelebirrMiniAppDetectorImpl() =>
    _TelebirrMiniAppDetectorStub();
