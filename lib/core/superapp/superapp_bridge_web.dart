import 'dart:js_util' as js_util;

import 'package:helloequb/core/logging/app_logger.dart';

import 'superapp_bridge.dart';

class _SuperAppBridgeWeb implements SuperAppBridge {
  @override
  bool get isAvailable {
    final win = js_util.globalThis;
    try {
      if (js_util.hasProperty(win, 'isSuperAppWebView')) {
        final result = js_util.callMethod(win, 'isSuperAppWebView', const []);
        final ok = result == true;
        AppLogger.log('SuperApp bridge available=$ok');
        return ok;
      }
    } catch (_) {
      // Fall back to property checks.
    }

    try {
      final xm = js_util.getProperty(win, 'xm');
      final nativeFn = xm == null ? null : js_util.getProperty(xm, 'native');
      final ok = nativeFn != null && js_util.typeofEquals(nativeFn, 'function');
      AppLogger.log('SuperApp bridge available=$ok');
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
          return ok;
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

    if (!js_util.hasProperty(win, 'getMiniAppToken')) {
      throw StateError('getMiniAppToken is not defined on window.');
    }

    AppLogger.log('requesting mini-app token (appId=$appId)');
    final result = js_util.callMethod(win, 'getMiniAppToken', [appId]);

    final resolved = await js_util.promiseToFuture<dynamic>(result);

    if (resolved is String && resolved.isNotEmpty) {
      AppLogger.log('mini-app token received (len=${resolved.length})');
      return resolved;
    }

    throw StateError('Invalid SuperApp token response.');
  }
}

SuperAppBridge createSuperAppBridgeImpl() => _SuperAppBridgeWeb();
