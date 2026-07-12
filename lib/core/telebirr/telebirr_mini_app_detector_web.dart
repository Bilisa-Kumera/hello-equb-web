// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:helloequb/core/logging/app_logger.dart';

import 'telebirr_mini_app_detector.dart';

class _TelebirrMiniAppDetectorWeb implements TelebirrMiniAppDetector {
  dynamic _cachedXm;
  dynamic _cachedConsumerApp;

  @override
  bool isTelebirrMiniApp() {
    final win = js_util.globalThis;
    _cachedConsumerApp = _safeGet(win, 'consumerapp');
    if (_cachedConsumerApp != null) return true;

    _cachedXm = _safeGet(win, 'xm');
    final nativeFn = _safeGet(_cachedXm, 'native');
    if (nativeFn != null && js_util.typeofEquals(nativeFn, 'function')) {
      return true;
    }

    final navigator = _safeGet(win, 'navigator');
    final ua = _safeGet(navigator, 'userAgent')?.toString().toLowerCase();
    return ua != null &&
        (ua.contains('telebirr') ||
            ua.contains('consumerapp') ||
            ua.contains('xm/'));
  }

  @override
  Map<String, dynamic> getBridgeSnapshot() {
    final win = js_util.globalThis;
    final consumerapp = _safeGet(win, 'consumerapp');
    final xm = _safeGet(win, 'xm');
    final nativeFn = _safeGet(xm, 'native');
    final navigator = _safeGet(win, 'navigator');
    return <String, dynamic>{
      'has.consumerapp': consumerapp != null,
      'has.xm': xm != null,
      'has.xm.native':
          nativeFn != null && js_util.typeofEquals(nativeFn, 'function'),
      'userAgent': _safeGet(navigator, 'userAgent')?.toString(),
      'isTelebirrMiniApp': isTelebirrMiniApp(),
      'detectedAt': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<String?> getMiniAppToken({String? appId}) async {
    final win = js_util.globalThis;
    for (final target in <dynamic>[
      _cachedConsumerApp ?? _safeGet(win, 'consumerapp'),
      win,
    ]) {
      final token = await _callTokenMethod(target, appId);
      if (token != null && token.isNotEmpty) return token;
    }

    try {
      final xm = _cachedXm ?? _safeGet(win, 'xm');
      final nativeFn = _safeGet(xm, 'native');
      if (nativeFn != null && js_util.typeofEquals(nativeFn, 'function')) {
        final result = js_util.callMethod(xm, 'native', [
          'getMiniAppToken',
          js_util.jsify({'appId': appId ?? ''}),
        ]);
        final resolved = await _unwrapMaybePromise(result);
        return _readToken(resolved);
      }
    } catch (e) {
      AppLogger.warn('[TelebirrDetector] xm.native token error: $e');
    }

    return null;
  }

  @override
  Future<Map<String, dynamic>> startTelebirrPayment(dynamic rawRequest) async {
    final rawRequestText = rawRequest?.toString().trim() ?? '';
    if (rawRequestText.isEmpty) {
      return const {'success': false, 'error': 'NO_RAW_REQUEST'};
    }

    final win = js_util.globalThis;
    for (final call in <Future<dynamic> Function()>[
      () async {
        final consumerapp = _cachedConsumerApp ?? _safeGet(win, 'consumerapp');
        final evaluate = _safeGet(consumerapp, 'evaluate');
        if (consumerapp == null ||
            evaluate == null ||
            !js_util.typeofEquals(evaluate, 'function')) {
          return null;
        }
        js_util.setProperty(
          win,
          'handleinitDataCallback',
          js.allowInterop(() {
            html.window.location.href = html.window.location.origin;
          }),
        );
        final payload = jsonEncode({
          'functionName': 'js_fun_start_pay',
          'params': {
            'rawRequest': rawRequestText,
            'functionCallBackName': 'handleinitDataCallback',
          },
        });
        return js_util.callMethod(consumerapp, 'evaluate', [
          payload,
        ]);
      },
      () async {
        final xm = _cachedXm ?? _safeGet(win, 'xm');
        final nativeFn = _safeGet(xm, 'native');
        if (nativeFn == null || !js_util.typeofEquals(nativeFn, 'function')) {
          return null;
        }
        return js_util.callMethod(xm, 'native', [
          'startTelebirrPayment',
          js_util.jsify({'rawRequest': rawRequestText}),
        ]);
      },
      () async {
        if (!js_util.hasProperty(win, 'startTelebirrPayment')) return null;
        return js_util.callMethod(win, 'startTelebirrPayment', [
          rawRequestText,
        ]);
      },
    ]) {
      try {
        final result = await _unwrapMaybePromise(await call());
        if (result != null) {
          return {'success': true, 'data': result.toString()};
        }
      } catch (e) {
        AppLogger.warn('[TelebirrDetector] payment bridge call failed: $e');
      }
    }

    return const {
      'success': false,
      'error': 'NO_TELEBIRR_BRIDGE',
      'message': 'Not running inside Telebirr Mini App or bridge not ready.',
    };
  }

  @override
  dynamic get consumerappBridge =>
      _cachedConsumerApp ??= _safeGet(js_util.globalThis, 'consumerapp');

  @override
  dynamic get xmBridge => _cachedXm ??= _safeGet(js_util.globalThis, 'xm');

  dynamic _safeGet(dynamic target, String prop) {
    try {
      if (target == null || !js_util.hasProperty(target, prop)) return null;
      return js_util.getProperty(target, prop);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _callTokenMethod(dynamic target, String? appId) async {
    if (target == null) return null;
    for (final method in const <String>['getMiniAppToken', 'getToken']) {
      try {
        if (!js_util.hasProperty(target, method)) continue;
        final args = appId == null ? const [] : [appId];
        final result = js_util.callMethod(target, method, args);
        final token = _readToken(await _unwrapMaybePromise(result));
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        AppLogger.warn('[TelebirrDetector] $method failed: $e');
      }
    }
    return null;
  }

  Future<dynamic> _unwrapMaybePromise(dynamic value) async {
    if (value == null) return null;
    try {
      if (js_util.hasProperty(value, 'then')) {
        return await js_util.promiseToFuture<dynamic>(value);
      }
    } catch (_) {}
    return value;
  }

  String? _readToken(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value;
    try {
      for (final key in const ['token', 'accessToken', 'authToken']) {
        if (!js_util.hasProperty(value, key)) continue;
        final token = _readToken(js_util.getProperty(value, key));
        if (token != null) return token;
      }
      if (js_util.hasProperty(value, 'data')) {
        return _readToken(js_util.getProperty(value, 'data'));
      }
    } catch (_) {}
    return null;
  }
}

TelebirrMiniAppDetector createTelebirrMiniAppDetectorImpl() =>
    _TelebirrMiniAppDetectorWeb();
