import 'cbebirr_plus_bridge_stub.dart'
    if (dart.library.html) 'cbebirr_plus_bridge_web.dart';

abstract class CbeBirrPlusBridge {
  bool get isAvailable;
  String? get launchToken;

  Future<bool> sendPaymentToken(String token);

  Future<bool> waitUntilAvailable({
    Duration timeout,
    Duration pollInterval,
  });
}

CbeBirrPlusBridge createCbeBirrPlusBridge() => createCbeBirrPlusBridgeImpl();
