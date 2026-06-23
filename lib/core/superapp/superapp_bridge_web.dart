// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

import 'package:helloequb/core/logging/app_logger.dart';

import 'superapp_bridge.dart';

class _SuperAppBridgeWeb implements SuperAppBridge {
  static const _tokenRequestTimeout = Duration(seconds: 30);

  @override
  bool get isAvailable {
    final win = js_util.globalThis;
    try {
      if (js_util.hasProperty(win, 'isSuperAppWebView')) {
        final result = js_util.callMethod(win, 'isSuperAppWebView', const []);
        final ok = result == true;
        AppLogger.log('SuperApp helper bridge available=$ok');
        if (ok) return true;
      }
    } catch (_) {
      // Fall back to property checks.
    }

    try {
      final consumerApp = js_util.getProperty(win, 'consumerapp');
      final evaluate = consumerApp == null
          ? null
          : js_util.getProperty(consumerApp, 'evaluate');
      final hasConsumerAppEvaluate =
          evaluate != null && js_util.typeofEquals(evaluate, 'function');
      if (hasConsumerAppEvaluate) {
        AppLogger.log('SuperApp bridge available=true (consumerapp.evaluate)');
        return true;
      }

      final xm = js_util.getProperty(win, 'xm');
      final nativeFn = xm == null ? null : js_util.getProperty(xm, 'native');
      final ok = nativeFn != null && js_util.typeofEquals(nativeFn, 'function');
      AppLogger.log('SuperApp bridge available=$ok (xm.native)');
      return ok;
    } catch (_) {
      AppLogger.log('SuperApp bridge available=false');
      return false;
    }
  }

  @override
  Future<bool> waitUntilAvailable({
    Duration timeout = const Duration(seconds: 12),
    Duration pollInterval = const Duration(milliseconds: 120),
  }) async {
    if (isAvailable) return true;

    final win = js_util.globalThis;
    final deadline = DateTime.now().add(timeout);

    // Prefer JS-side polling because the native bridge can be injected late.
    try {
      if (js_util.hasProperty(win, 'SuperAppBridge')) {
        final superAppBridge = js_util.getProperty(win, 'SuperAppBridge');
        if (superAppBridge != null &&
            js_util.hasProperty(superAppBridge, 'waitForBridge')) {
          AppLogger.log(
            'waiting for Telebirr bridge (timeoutMs=${timeout.inMilliseconds})',
          );
          final promise = js_util.callMethod(
            superAppBridge,
            'waitForBridge',
            [
              js_util.jsify({
                'timeoutMs': timeout.inMilliseconds,
                'intervalMs': pollInterval.inMilliseconds,
              }),
            ],
          );
          final resolved = await js_util.promiseToFuture(promise);
          final ok = resolved == true;
          AppLogger.log('waitForBridge resolved=$ok');
          if (ok) return true;
          if (isAvailable) return true;
        }
      }
    } catch (e) {
      AppLogger.warn('waitForBridge failed; falling back to Dart polling: $e');
    }

    // Fallback: Dart-side polling.
    var attempt = 0;
    while (DateTime.now().isBefore(deadline)) {
      attempt += 1;
      AppLogger.log('Checking Telebirr bridge... attempt $attempt');
      if (isAvailable) {
        AppLogger.success('Telebirr bridge ready');
        return true;
      }
      await Future<void>.delayed(pollInterval);
    }

    AppLogger.warn('Bridge unavailable (timeout after ${timeout.inSeconds}s)');
    return false;
  }

  @override
  Future<String> getMiniAppToken({required String appId}) async {
    final win = js_util.globalThis;

    AppLogger.log('requesting mini-app token (appId=$appId)');
    _ensureXmBridgeInstalled();
    _logBridgeSnapshot();

    // Prefer JS implementation (xm.js + superapp.js) so callbacks stay on window.
    if (js_util.hasProperty(win, 'SuperAppBridge')) {
      final superAppBridge = js_util.getProperty(win, 'SuperAppBridge');
      if (superAppBridge != null &&
          js_util.hasProperty(superAppBridge, 'getMiniAppToken')) {
        try {
          AppLogger.log('delegating token request to SuperAppBridge.getMiniAppToken');
          final result = js_util.callMethod(
            superAppBridge,
            'getMiniAppToken',
            [appId],
          );
          final resolved = await js_util
              .promiseToFuture<dynamic>(result)
              .timeout(_tokenRequestTimeout);
          final token = _readToken(resolved);
          if (token != null && token.isNotEmpty) {
            AppLogger.success(
              'mini-app token received via SuperAppBridge (len=${token.length})',
            );
            return token;
          }
        } catch (e) {
          AppLogger.warn('SuperAppBridge.getMiniAppToken failed: $e');
        }
      }
    }

    if (js_util.hasProperty(win, 'getMiniAppToken')) {
      try {
        AppLogger.log('delegating token request to window.getMiniAppToken');
        final result = js_util.callMethod(win, 'getMiniAppToken', [appId]);
        final resolved = await js_util
            .promiseToFuture<dynamic>(result)
            .timeout(_tokenRequestTimeout);
        final token = _readToken(resolved);
        if (token != null && token.isNotEmpty) {
          AppLogger.success(
            'mini-app token received via window.getMiniAppToken (len=${token.length})',
          );
          return token;
        }
      } catch (e) {
        AppLogger.warn('window.getMiniAppToken failed: $e');
      }
    }

    final xmToken = await _getTokenFromXmNative(appId);
    if (xmToken != null && xmToken.isNotEmpty) {
      AppLogger.log(
        'mini-app token received via xm.native (len=${xmToken.length})',
      );
      return xmToken;
    }

    final consumerAppToken = await _getTokenFromConsumerApp(appId);
    if (consumerAppToken != null && consumerAppToken.isNotEmpty) {
      AppLogger.log(
        'mini-app token received via consumerapp.evaluate (len=${consumerAppToken.length})',
      );
      return consumerAppToken;
    }

    throw StateError(
      'Unable to obtain Telebirr mini-app token. '
      'has.xm=${_hasXmNative()} has.consumerapp.evaluate=${_hasConsumerEvaluate()}',
    );
  }

  void _ensureXmBridgeInstalled() {
    try {
      final win = js_util.globalThis;
      if (!js_util.hasProperty(win, 'SuperAppBridge')) return;
      final superAppBridge = js_util.getProperty(win, 'SuperAppBridge');
      if (superAppBridge == null) return;
      if (js_util.hasProperty(superAppBridge, 'installXmBridge')) {
        js_util.callMethod(superAppBridge, 'installXmBridge', const []);
      }
    } catch (e) {
      AppLogger.warn('installXmBridge failed: $e');
    }
  }

  void _logBridgeSnapshot() {
    AppLogger.log(
      'bridge snapshot has.xm=${_hasXmNative()} '
      'has.consumerapp.evaluate=${_hasConsumerEvaluate()}',
    );
  }

  bool _hasXmNative() {
    try {
      final win = js_util.globalThis;
      final xm = js_util.getProperty(win, 'xm');
      if (xm == null) return false;
      final nativeFn = js_util.getProperty(xm, 'native');
      return nativeFn != null && js_util.typeofEquals(nativeFn, 'function');
    } catch (_) {
      return false;
    }
  }

  bool _hasConsumerEvaluate() {
    try {
      final win = js_util.globalThis;
      final consumerApp = js_util.getProperty(win, 'consumerapp');
      if (consumerApp == null) return false;
      final evaluate = js_util.getProperty(consumerApp, 'evaluate');
      return evaluate != null && js_util.typeofEquals(evaluate, 'function');
    } catch (_) {
      return false;
    }
  }

  Future<String?> _getTokenFromXmNative(String appId) async {
    if (!_hasXmNative()) {
      AppLogger.log('xm.native unavailable; skipping direct xm call');
      return null;
    }

    try {
      final win = js_util.globalThis;
      final xm = js_util.getProperty<dynamic>(win, 'xm');
      final result = js_util.callMethod<dynamic>(xm, 'native', [
        'getMiniAppToken',
        js_util.jsify({'appId': appId}),
      ]);
      final resolved = await js_util
          .promiseToFuture<dynamic>(result)
          .timeout(_tokenRequestTimeout);
      final token = _readToken(resolved);
      if (token == null || token.isEmpty) {
        throw StateError('xm.native response did not contain token.');
      }
      return token;
    } catch (e) {
      AppLogger.warn('xm.native getMiniAppToken failed: $e');
      return null;
    }
  }

  Future<String?> _getTokenFromConsumerApp(String appId) async {
    if (!_hasConsumerEvaluate()) {
      AppLogger.log('consumerapp.evaluate unavailable; skipping direct evaluate');
      return null;
    }

    for (final functionName in const [
      'getMiniAppToken',
      'js_fun_h5GetAccessToken',
      'js_fun_getAccessToken',
    ]) {
      AppLogger.log('consumerapp.evaluate trying functionName=$functionName');
      final token = await _evaluateConsumerAppForToken(
        appId: appId,
        functionName: functionName,
      );
      if (token != null && token.isNotEmpty) return token;
    }
    return null;
  }

  Future<String?> _evaluateConsumerAppForToken({
    required String appId,
    required String functionName,
  }) async {
    const callbackPrefix = '__helloEqubMiniAppTokenCallback';
    final consumerApp = js.context.hasProperty('consumerapp')
        ? js.context['consumerapp']
        : null;

    if (consumerApp == null || !consumerApp.hasProperty('evaluate')) {
      return null;
    }

    final callbackName =
        '${callbackPrefix}_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<String>();

    js.context[callbackName] = js.JsFunction.withThis(
      (dynamic self, dynamic res, dynamic message, [dynamic data]) {
        final token = _readToken(res) ?? _readToken(data);
        if (!completer.isCompleted) {
          if (token != null && token.isNotEmpty) {
            completer.complete(token);
          } else {
            completer.completeError(
              StateError(
                message?.toString() ??
                    'consumerapp.evaluate callback did not contain token',
              ),
            );
          }
        }
      },
    );

    final payloadMap = {
      'functionName': functionName,
      'params': {
        'appid': appId,
        'appId': appId,
        'functionCallBackName': callbackName,
        'functionCallbackName': callbackName,
      },
    };

    try {
      try {
        consumerApp.callMethod('evaluate', [js_util.jsify(payloadMap)]);
      } catch (_) {
        consumerApp.callMethod('evaluate', [jsonEncode(payloadMap)]);
      }

      return await completer.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw StateError(
          'consumerapp.evaluate token callback timeout ($functionName)',
        ),
      );
    } catch (e) {
      AppLogger.warn('consumerapp.evaluate $functionName failed: $e');
      return null;
    } finally {
      js.context.deleteProperty(callbackName);
    }
  }

  String? _readToken(dynamic response) {
    dynamic data = response;

    if (data == null) return null;

    if (data is String) {
      if (data.isEmpty) return null;
      try {
        data = jsonDecode(data);
      } catch (_) {
        return data;
      }
    }

    if (data is Map) {
      final token = data['token'] ?? data['accessToken'];
      if (token is String && token.isNotEmpty) return token;

      final nested = data['data'];
      if (nested is Map) {
        final nestedToken = nested['token'] ?? nested['accessToken'];
        if (nestedToken is String && nestedToken.isNotEmpty) {
          return nestedToken;
        }
      }
    }

    try {
      final token = js_util.getProperty<dynamic>(data, 'token');
      if (token is String && token.isNotEmpty) return token;
      final accessToken = js_util.getProperty<dynamic>(data, 'accessToken');
      if (accessToken is String && accessToken.isNotEmpty) return accessToken;
      final nested = js_util.getProperty<dynamic>(data, 'data');
      if (nested != null) return _readToken(nested);
    } catch (_) {
      // Response was not a JS object.
    }

    return null;
  }
}

SuperAppBridge createSuperAppBridgeImpl() => _SuperAppBridgeWeb();
