import 'superapp_bridge.dart';

class _SuperAppBridgeStub implements SuperAppBridge {
  @override
  bool get isAvailable => false;

  @override
  Future<bool> waitUntilAvailable({
    Duration timeout = const Duration(seconds: 0),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    return false;
  }

  @override
  Future<String> getMiniAppToken({required String appId}) {
    throw StateError('SuperApp bridge is only available on Flutter Web.');
  }
}

SuperAppBridge createSuperAppBridgeImpl() => _SuperAppBridgeStub();
