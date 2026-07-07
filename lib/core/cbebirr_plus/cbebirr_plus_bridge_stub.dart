import 'cbebirr_plus_bridge.dart';

class _CbeBirrPlusBridgeStub implements CbeBirrPlusBridge {
  @override
  bool get isAvailable => false;

  @override
  String? get launchToken => null;

  @override
  Future<bool> sendPaymentToken(String token) async {
    return false;
  }

  @override
  Future<bool> waitUntilAvailable({
    Duration timeout = const Duration(seconds: 0),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    return false;
  }
}

CbeBirrPlusBridge createCbeBirrPlusBridgeImpl() => _CbeBirrPlusBridgeStub();
