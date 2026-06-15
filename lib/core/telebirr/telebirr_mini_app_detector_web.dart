// ignore_for_file: avoid_web_libraries_in_flutter
// This file is ONLY loaded on Flutter Web via conditional imports.
// On Android/iOS/Desktop the stub implementation is used instead.

// ignore: unnecessary_import
import 'dart:async';
import 'dart:js_util' as js_util;

import 'package:helloequb/core/logging/app_logger.dart';

import 'telebirr_mini_app_detector.dart';

/// Web implementation of Telebirr Mini App detection.
///
/// Detects:
/// - `window.xm` (Telebirr JS Bridge with `.native` function)
/// - `window.consumerapp` (alternative Telebirr bridge, often with `.evaluate`)
/// - User-Agent fallback (contains "Telebirr" or "consumerapp")
class _TelebirrMiniAppDetectorWeb implements TelebirrMiniAppDetector {
  bool? _cachedIsTelebirr;
  dynamic _cachedXm;
  dynamic _cachedConsumerApp;

  @override
  bool isTelebirrMiniApp() {
    if (_cachedIsTelebirr != null) return _cachedIsTelebirr!;

    final detected = _detectNow();
    _cachedIsTelebirr = detected;
    return detected;
  }

  bool _detectNow() {
    try {
      final win = js_util.globalThis;

      // 1) Direct consumerapp bridge (preferred for payments in some flows)
      final consumerapp = _safeGet(win, 'consumerapp');
      if (consumerapp != null) {
        _cachedConsumerApp = consumerapp;
        AppLogger.log('[TelebirrDetector] window.consumerapp detected');
        return true;
      }

      // 2) xm bridge (primary Telebirr JS Bridge)
      final xm = _safeGet(win, 'xm');
      if (xm != null) {
        final nativeFn = _safeGet(xm, 'native');
        final isFn = nativeFn != null &&
            js_util.typeofEquals(nativeFn, 'function');
        if (isFn) {
          _cachedXm = xm;
          AppLogger.log('[TelebirrDetector] window.xm.native detected');
          return true;
        }
      }

      // 3) User-Agent fallback (some Telebirr WebViews set this)
      try {
        final nav = _safeGet(win, 'navigator');
        final ua = nav != null ? _safeGet(nav, 'userAgent') : null;
        if (ua is String) {
          final lower = ua.toLowerCase();
          if (lower.contains('telebirr') ||
              lower.contains('consumerapp') ||
              lower.contains('xm/')) {
            AppLogger.log(
                '[TelebirrDetector] Telebirr detected via User-Agent');
            return true;
          }
        }
      } catch (_) {
        // ignore UA errors
      }

      return false;
    } catch (e, st) {
      AppLogger.warn('[TelebirrDetector] detection exception: $e\n$st');
      return false;
    }
  }

  dynamic _safeGet(dynamic target, String prop) {
    try {
      if (target == null) return null;
      if (!js_util.hasProperty(target, prop)) return null;
      final v = js_util.getProperty(target, prop);
      return v;
    } catch (_) {
      return null;
    }
  }

  @override
  Map<String, dynamic> getBridgeSnapshot() {
    final win = js_util.globalThis;
    final out = <String, dynamic>{};

    try {
      final consumerapp = _safeGet(win, 'consumerapp');
      out['has.consumerapp'] = consumerapp != null;
      if (consumerapp != null) {
        out['consumerapp.keys'] = _getOwnKeys(consumerapp);
        _cachedConsumerApp = consumerapp;
      }
    } catch (e) {
      out['consumerapp.error'] = e.toString();
    }

    try {
      final xm = _safeGet(win, 'xm');
      out['has.xm'] = xm != null;
      if (xm != null) {
        final nativeFn = _safeGet(xm, 'native');
        out['has.xm.native'] = nativeFn != null;
        out['xm.native.type'] =
            nativeFn == null ? 'null' : js_util.typeofEquals(nativeFn, 'function')
                ? 'function'
                : 'other';
        _cachedXm = xm;
      }
    } catch (e) {
      out['xm.error'] = e.toString();
    }

    try {
      final nav = _safeGet(win, 'navigator');
      final ua = nav != null ? _safeGet(nav, 'userAgent') : null;
      if (ua is String) out['userAgent'] = ua;
    } catch (_) {}

    out['isTelebirrMiniApp'] = isTelebirrMiniApp();
    out['detectedAt'] = DateTime.now().toIso8601String();
    return out;
  }

  List<String> _getOwnKeys(dynamic obj) {
    try {
      final keys = js_util.callMethod(
        js_util.getProperty(js_util.globalThis, 'Object'),
        'keys',
        [obj],
      );
      return (keys as List).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> getMiniAppToken({String? appId}) async {
    final win = js_util.globalThis;

    // Try consumerapp first (some Telebirr flows expose this)
    final consumerapp = _cachedConsumerApp ?? _safeGet(win, 'consumerapp');
    if (consumerapp != null) {
      try {
        // Common patterns: consumerapp.getToken() or consumerapp.getMiniAppToken()
        if (js_util.hasProperty(consumerapp, 'getMiniAppToken')) {
          final res = js_util.callMethod(
            consumerapp,
            'getMiniAppToken',
            appId != null ? [appId] : const [],
          );
          final token = await _unwrapMaybePromise(res);
          if (token is String && token.isNotEmpty) return token;
        }
        if (js_util.hasProperty(consumerapp, 'getToken')) {
          final res = js_util.callMethod(consumerapp, 'getToken', const []);
          final token = await _unwrapMaybePromise(res);
          if (token is String && token.isNotEmpty) return token;
        }
      } catch (e) {
        AppLogger.warn('[TelebirrDetector] consumerapp token error: $e');
      }
    }

    // Fallback to xm bridge (re-uses the existing global helper if present)
    try {
      if (js_util.hasProperty(win, 'getMiniAppToken')) {
        final res = js_util.callMethod(
          win,
          'getMiniAppToken',
          appId != null ? [appId] : const [],
        );
        final token = await _unwrapMaybePromise(res);
        if (token is String && token.isNotEmpty) return token;
      }
    } catch (e) {
      AppLogger.warn('[TelebirrDetector] xm getMiniAppToken error: $e');
    }

    // Direct xm.native call as last resort
    final xm = _cachedXm ?? _safeGet(win, 'xm');
    if (xm != null) {
      try {
        final nativeFn = _safeGet(xm, 'native');
        if (nativeFn != null &&
            js_util.typeofEquals(nativeFn, 'function')) {
          dynamic res;
          try {
            res = js_util.callMethod(nativeFn, 'call', [
              xm,
              'getMiniAppToken',
              js_util.jsify({'appId': appId ?? ''}),
            ]);
          } catch (_) {
            // Some bridges take different signatures
            res = js_util.callMethod(nativeFn, 'call', [
              xm,
              'getMiniAppToken',
              appId ?? '',
            ]);
          }
          final token = await _unwrapMaybePromise(res);
          if (token is String && token.isNotEmpty) return token;
        }
      } catch (e) {
        AppLogger.warn('[TelebirrDetector] xm.native token error: $e');
      }
    }

    AppLogger.warn('[TelebirrDetector] getMiniAppToken failed - no bridge');
    return null;
  }

  Future<dynamic> _unwrapMaybePromise(dynamic value) async {
    if (value == null) return null;
    try {
      if (js_util.hasProperty(value, 'then')) {
        return await js_util.promiseToFuture(value);
      }
    } catch (_) {}
    return value;
  }

  @override
  Future<Map<String, dynamic>> startTelebirrPayment(dynamic rawRequest) async {
    if (rawRequest == null) {
      return {'success': false, 'error': 'NO_RAW_REQUEST'};
    }

    final win = js_util.globalThis;

    // 1) Try consumerapp.evaluate (common Telebirr Mini App payment pattern)
    final consumerapp = _cachedConsumerApp ?? _safeGet(win, 'consumerapp');
    if (consumerapp != null) {
      try {
        if (js_util.hasProperty(consumerapp, 'evaluate')) {
          AppLogger.log(
              '[TelebirrDetector] calling consumerapp.evaluate for payment');

          final payload = js_util.jsify({
            'action': 'startTelebirrPayment',
            'rawRequest': rawRequest.toString(),
          });

          final res = js_util.callMethod(consumerapp, 'evaluate', [payload]);
          final result = await _unwrapMaybePromise(res);

          if (result is Map) {
            return {'success': true, 'data': result};
          }
          if (result is String) {
            return {'success': true, 'raw': result};
          }
          return {'success': true, 'data': result?.toString()};
        }
      } catch (e) {
        AppLogger.warn('[TelebirrDetector] consumerapp.evaluate failed: $e');
      }
    }

    // 2) Try xm.native("startTelebirrPayment", ...)
    final xm = _cachedXm ?? _safeGet(win, 'xm');
    if (xm != null) {
      try {
        final nativeFn = _safeGet(xm, 'native');
        if (nativeFn != null &&
            js_util.typeofEquals(nativeFn, 'function')) {
          AppLogger.log(
              '[TelebirrDetector] calling xm.native(startTelebirrPayment)');

          dynamic res;
          try {
            res = js_util.callMethod(nativeFn, 'call', [
              xm,
              'startTelebirrPayment',
              js_util.jsify({'rawRequest': rawRequest.toString()}),
            ]);
          } catch (_) {
            res = js_util.callMethod(nativeFn, 'call', [
              xm,
              'startTelebirrPayment',
              rawRequest.toString(),
            ]);
          }

          final result = await _unwrapMaybePromise(res);
          return {'success': true, 'data': result?.toString()};
        }
      } catch (e) {
        AppLogger.warn('[TelebirrDetector] xm.native payment failed: $e');
      }
    }

    // 3) Fallback: try the global helper injected by superapp.js if present
    try {
      if (js_util.hasProperty(win, 'startTelebirrPayment')) {
        final res = js_util.callMethod(
          win,
          'startTelebirrPayment',
          [rawRequest.toString()],
        );
        final result = await _unwrapMaybePromise(res);
        return {'success': true, 'data': result?.toString()};
      }
    } catch (e) {
      AppLogger.warn('[TelebirrDetector] global startTelebirrPayment failed: $e');
    }

    AppLogger.warn('[TelebirrDetector] No Telebirr payment bridge available');
    return {
      'success': false,
      'error': 'NO_TELEBIRR_BRIDGE',
      'message':
          'Not running inside Telebirr Mini App or bridge not ready.',
    };
  }

  @override
  dynamic get consumerappBridge {
    if (_cachedConsumerApp != null) return _cachedConsumerApp;
    try {
      final win = js_util.globalThis;
      _cachedConsumerApp = _safeGet(win, 'consumerapp');
    } catch (_) {}
    return _cachedConsumerApp;
  }

  @override
  dynamic get xmBridge {
    if (_cachedXm != null) return _cachedXm;
    try {
      final win = js_util.globalThis;
      _cachedXm = _safeGet(win, 'xm');
    } catch (_) {}
    return _cachedXm;
  }
}

TelebirrMiniAppDetector createTelebirrMiniAppDetectorImpl() =>
    _TelebirrMiniAppDetectorWeb();
