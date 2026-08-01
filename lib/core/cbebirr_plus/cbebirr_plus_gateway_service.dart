import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:helloequb/core/env_config.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

class CbeBirrPlusGatewaySession {
  const CbeBirrPlusGatewaySession({
    required this.token,
    required this.phone,
  });

  final String token;
  final String phone;

  bool get isValid => token.trim().isNotEmpty && phone.trim().isNotEmpty;
}

class CbeBirrPlusPaymentRequest {
  const CbeBirrPlusPaymentRequest({
    required this.amount,
    required this.transactionId,
    this.tillCode,
    this.callBackURL,
    this.transactionTime,
  });

  final num amount;
  final String transactionId;

  /// TODO: Prefer configuring this in the gateway through CBE_TILL_CODE.
  final String? tillCode;

  /// TODO: Prefer configuring this in the gateway through CBE_CALLBACK_URL.
  final String? callBackURL;
  final DateTime? transactionTime;

  Map<String, dynamic> toJson({required String token}) => <String, dynamic>{
        'amount': amount,
        'transactionId': transactionId,
        'token': token,
        if (tillCode != null && tillCode!.trim().isNotEmpty)
          'tillCode': tillCode,
        if (callBackURL != null && callBackURL!.trim().isNotEmpty)
          'callBackURL': callBackURL,
        if (transactionTime != null)
          'transactionTime': transactionTime!.toIso8601String(),
      };
}

class CbeBirrPlusGatewayService {
  CbeBirrPlusGatewayService({
    Dio? dio,
    DataController? dataController,
    CbeBirrPlusBridge? bridge,
  })  : _dio = dio ?? Dio(),
        _dataController = dataController ?? DataController(),
        _bridge = bridge ?? createCbeBirrPlusBridge();

  static const _tokenKey = 'cbeBirrPlusToken';
  static const _phoneKey = 'cbeBirrPlusPhone';

  final Dio _dio;
  final DataController _dataController;
  final CbeBirrPlusBridge _bridge;

  String get _gatewayBaseUrl {
    final raw = EnvConfig.cbeGatewayBaseUrl;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  CbeBirrPlusGatewaySession? readSession() {
    final token = _dataController.retrieveData<String>(_tokenKey)?.trim() ?? '';
    final phone = _dataController.retrieveData<String>(_phoneKey)?.trim() ?? '';
    if (token.isEmpty || phone.isEmpty) return null;
    return CbeBirrPlusGatewaySession(token: token, phone: phone);
  }

  CbeBirrPlusGatewaySession? captureLaunchQueryParams() {
    if (!kIsWeb) return null;

    final params = Uri.base.queryParameters;
    final token = (params['token'] ?? params['appToken'] ?? '').trim();
    final phone = (params['phone'] ?? params['phoneNumber'] ?? '').trim();

    if (token.isEmpty || phone.isEmpty) {
      AppLogger.log('CBEBirr Plus gateway query params not present');
      return readSession();
    }

    _dataController.storeData(_tokenKey, token);
    _dataController.storeData(_phoneKey, phone);
    _dataController.storeData('phoneNumber', phone);
    AppLogger.success(
      'CBEBirr Plus gateway session captured (tokenLen=${token.length})',
    );
    return CbeBirrPlusGatewaySession(token: token, phone: phone);
  }

  Future<Map<String, dynamic>> requestPayment(
    CbeBirrPlusPaymentRequest request,
  ) async {
    final session = readSession();
    if (session == null || !session.isValid) {
      throw StateError('CBEBirr Plus token and phone are not available.');
    }

    if (_gatewayBaseUrl.isEmpty) {
      throw StateError(
        'Missing CBE_GATEWAY_BASE_URL in Flutter environment.',
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '$_gatewayBaseUrl/api/pay',
      data: request.toJson(token: session.token),
      options: Options(headers: const {
        'content-type': 'application/json',
        'accept': 'application/json',
      }),
    );

    return response.data ?? <String, dynamic>{};
  }

  Future<bool> requestPaymentAndPostToCbe(
    CbeBirrPlusPaymentRequest request,
  ) async {
    final result = await requestPayment(request);
    final processedPaymentToken =
        (result['token'] ?? result['processedPaymentToken'] ?? '').toString();

    if (processedPaymentToken.trim().isEmpty) {
      throw StateError('CBEBirr Plus gateway did not return a payment token.');
    }

    return _bridge.sendPaymentToken(processedPaymentToken);
  }
}
