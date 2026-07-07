// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
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
        if (result == true) return true;
      }

      final consumerApp = js_util.getProperty(win, 'consumerapp');
      final evaluate = consumerApp == null
          ? null
          : js_util.getProperty(consumerApp, 'evaluate');
      if (evaluate != null && js_util.typeofEquals(evaluate, 'function')) {
        return true;
      }

      final xm = js_util.getProperty(win, 'xm');
      final nativeFn = xm == null ? null : js_util.getProperty(xm, 'native');
      return nativeFn != null && js_util.typeofEquals(nativeFn, 'function');
    } catch (_) {
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
    try {
      if (js_util.hasProperty(win, 'SuperAppBridge')) {
        final bridge = js_util.getProperty(win, 'SuperAppBridge');
        if (bridge != null && js_util.hasProperty(bridge, 'waitForBridge')) {
          final promise = js_util.callMethod(bridge, 'waitForBridge', [
            js_util.jsify({
              'timeoutMs': timeout.inMilliseconds,
              'intervalMs': pollInterval.inMilliseconds,
            }),
          ]);
          final resolved = await js_util.promiseToFuture<dynamic>(promise);
          if (resolved == true || isAvailable) return true;
        }
      }
    } catch (e) {
      AppLogger.warn('SuperApp waitForBridge failed: $e');
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (isAvailable) return true;
      await Future<void>.delayed(pollInterval);
    }
    return false;
  }

  @override
  Future<String> getMiniAppToken({required String appId}) async {
    final win = js_util.globalThis;

    for (final target in <dynamic>[
      _getProperty(win, 'SuperAppBridge'),
      win,
      _getProperty(win, 'consumerapp'),
    ]) {
      final token = await _callTokenMethod(target, appId);
      if (token != null && token.isNotEmpty) return token;
    }

    final xmToken = await _getTokenFromXmNative(appId);
    if (xmToken != null && xmToken.isNotEmpty) return xmToken;

    throw StateError('Unable to obtain mini-app token from SuperApp bridge.');
  }

  dynamic _getProperty(dynamic target, String property) {
    try {
      if (target == null || !js_util.hasProperty(target, property)) return null;
      return js_util.getProperty(target, property);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _callTokenMethod(dynamic target, String appId) async {
    if (target == null) return null;
    for (final method in const <String>[
      'getMiniAppToken',
      'getAppToken',
      'getToken',
    ]) {
      try {
        if (!js_util.hasProperty(target, method)) continue;
        final result = js_util.callMethod(target, method, [appId]);
        final resolved = await _unwrapMaybePromise(result);
        final token = _readToken(resolved);
        if (token != null && token.isNotEmpty) return token;
      } catch (e) {
        AppLogger.warn('$method failed: $e');
      }
    }
    return null;
  }

  Future<String?> _getTokenFromXmNative(String appId) async {
    try {
      final xm = _getProperty(js_util.globalThis, 'xm');
      final nativeFn = _getProperty(xm, 'native');
      if (nativeFn == null || !js_util.typeofEquals(nativeFn, 'function')) {
        return null;
      }
      final result = js_util.callMethod(xm, 'native', [
        'getMiniAppToken',
        js_util.jsify({'appId': appId}),
      ]);
      final resolved = await _unwrapMaybePromise(result);
      return _readToken(resolved);
    } catch (e) {
      AppLogger.warn('xm.native getMiniAppToken failed: $e');
      return null;
    }
  }

  Future<dynamic> _unwrapMaybePromise(dynamic value) async {
    if (value == null) return null;
    try {
      if (js_util.hasProperty(value, 'then')) {
        return await js_util
            .promiseToFuture<dynamic>(value)
            .timeout(_tokenRequestTimeout);
      }
    } catch (_) {}
    return value;
  }

  String? _readToken(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim().isEmpty ? null : value.trim();
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

SuperAppBridge createSuperAppBridgeImpl() => _SuperAppBridgeWeb();
