import 'package:flutter/services.dart';
import 'dart:async';

class TelebirrService {
  static const MethodChannel _channel = MethodChannel('app_channel');

  static final StreamController<Map<String, dynamic>> _paymentResultController =
      StreamController.broadcast();
  static Stream<Map<String, dynamic>> get paymentResultStream =>
      _paymentResultController.stream;

  TelebirrService() {
    _channel.setMethodCallHandler(_nativeCallbackHandler);
  }

  Future<void> _nativeCallbackHandler(MethodCall call) async {
    if (call.method == "onPaymentResult") {
      final Map<dynamic, dynamic> result = call.arguments;
      _paymentResultController.add({
        'code': result['code'],
        'errMsg': result['errMsg'],
      });
    }
  }

  Future<Map<String, dynamic>> initiatePayment({
    required String appId,
    required String appKey,
    required String shortCode,
    required String totalAmount,
    required String receiveCode,
  }) async {
   

    try {
      final result = await _channel.invokeMethod<String>(
        'startTelebirrPayment',
        {
          'appId': appId,
          'appKey': appKey,
          'shortCode': shortCode,
          'receiveCode': receiveCode,
          'totalAmount': totalAmount,
        },
      );

      return {
        'success': true,
        'data': result,
      };
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message ?? 'Unknown error'};
    }
  }
}
