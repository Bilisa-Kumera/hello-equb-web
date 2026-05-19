import 'superapp_bridge_stub.dart'
    if (dart.library.html) 'superapp_bridge_web.dart';

abstract class SuperAppBridge {
  bool get isAvailable;
  Future<bool> waitUntilAvailable({
    Duration timeout,
    Duration pollInterval,
  });
  Future<String> getMiniAppToken({required String appId});
}

SuperAppBridge createSuperAppBridge() => createSuperAppBridgeImpl();
