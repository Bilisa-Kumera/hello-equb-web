// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist

import 'dart:js_util' as js_util;

import 'package:helloequb/core/logging/app_logger.dart';

import 'cbebirr_plus_bridge.dart';

class _CbeBirrPlusBridgeWeb implements CbeBirrPlusBridge {
  @override
  bool get isAvailable {
    final win = js_util.globalThis;

    try {
      if (js_util.hasProperty(win, 'CBEBirrPlusBridge')) {
        final bridge = js_util.getProperty(win, 'CBEBirrPlusBridge');
        if (bridge != null && js_util.hasProperty(bridge, 'isAvailable')) {
          final result = js_util.callMethod(bridge, 'isAvailable', const []);
          final ok = result == true;
          AppLogger.log('CBEBirr Plus bridge available=$ok');
          return ok;
        }
      }
    } catch (e) {
      AppLogger.warn('CBEBirr Plus bridge availability check failed: $e');
    }

    final ok = _hasPostMessageChannel(win);
    AppLogger.log('CBEBirr Plus channel available=$ok');
    return ok;
  }

  @override
  String? get launchToken {
    final win = js_util.globalThis;

    for (final key in const <String>[
      '__CBEBIRR_PLUS_TOKEN',
      'CBEBIRR_PLUS_TOKEN',
      'cbebirrPlusToken',
    ]) {
      try {
        if (!js_util.hasProperty(win, key)) continue;
        final value = js_util.getProperty(win, key);
        if (value is String && value.trim().isNotEmpty) {
          return _stripBearerPrefix(value);
        }
      } catch (_) {}
    }

    try {
      final location = js_util.getProperty(win, 'location');
      final search = js_util.getProperty(location, 'search')?.toString() ?? '';
      final query = search.startsWith('?') ? search.substring(1) : search;
      final queryParameters = Uri.splitQueryString(query);
      for (final key in const <String>[
        'cbebirrToken',
        'cbeBirrToken',
        'cbe_token',
      ]) {
        final value = queryParameters[key];
        if (value != null && value.trim().isNotEmpty) {
          return _stripBearerPrefix(value);
        }
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<bool> sendPaymentToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      AppLogger.warn('CBEBirr Plus payment token is empty');
      return false;
    }

    final win = js_util.globalThis;
    try {
      if (!_hasPostMessageChannel(win)) {
        AppLogger.warn('CBEBirr Plus myJsChannel.postMessage unavailable');
        return false;
      }

      final channel = js_util.getProperty(win, 'myJsChannel');
      js_util.callMethod(channel, 'postMessage', <Object>[trimmed]);
      AppLogger.success(
        'CBEBirr Plus payment token sent (len=${trimmed.length})',
      );
      return true;
    } catch (e) {
      AppLogger.warn('CBEBirr Plus payment token send failed: $e');
      return false;
    }
  }

  @override
  Future<bool> waitUntilAvailable({
    Duration timeout = const Duration(seconds: 12),
    Duration pollInterval = const Duration(milliseconds: 120),
  }) async {
    if (isAvailable) return true;

    final deadline = DateTime.now().add(timeout);
    var attempt = 0;
    while (DateTime.now().isBefore(deadline)) {
      attempt += 1;
      AppLogger.log('Checking CBEBirr Plus channel... attempt $attempt');
      if (isAvailable) {
        AppLogger.success('CBEBirr Plus channel ready');
        return true;
      }
      await Future<void>.delayed(pollInterval);
    }

    AppLogger.warn(
      'CBEBirr Plus channel unavailable (timeout after ${timeout.inSeconds}s)',
    );
    return false;
  }

  bool _hasPostMessageChannel(Object win) {
    try {
      if (!js_util.hasProperty(win, 'myJsChannel')) return false;
      final channel = js_util.getProperty(win, 'myJsChannel');
      if (channel == null || !js_util.hasProperty(channel, 'postMessage')) {
        return false;
      }
      final postMessage = js_util.getProperty(channel, 'postMessage');
      return postMessage != null &&
          js_util.typeofEquals(postMessage, 'function');
    } catch (_) {
      return false;
    }
  }

  String _stripBearerPrefix(String value) {
    final trimmed = value.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }
}

CbeBirrPlusBridge createCbeBirrPlusBridgeImpl() => _CbeBirrPlusBridgeWeb();
