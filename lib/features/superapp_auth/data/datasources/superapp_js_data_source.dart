import 'package:helloequb/core/superapp/superapp_bridge.dart';

class SuperAppJsDataSource {
  SuperAppJsDataSource({SuperAppBridge? bridge})
      : _bridge = bridge ?? createSuperAppBridge();

  final SuperAppBridge _bridge;

  bool get isAvailable => _bridge.isAvailable;

  Future<String> getMiniAppToken({required String merchantAppId}) {
    return _bridge.getMiniAppToken(appId: merchantAppId);
  }
}
