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

    final bridgeToken = _readTokenFromCbeBridge(win);
    if (bridgeToken != null) return bridgeToken;

    for (final key in const <String>[
      '__CBEBIRR_PLUS_TOKEN',
      'CBEBIRR_PLUS_TOKEN',
      'cbebirrPlusToken',
      'cbebirrToken',
      'cbeBirrToken',
      'cbe_token',
      'appToken',
      'apptoken',
      'authorization',
      'Authorization',
    ]) {
      try {
        if (!js_util.hasProperty(win, key)) continue;
        final value = js_util.getProperty(win, key);
        final token = _readToken(value);
        if (token != null) return token;
      } catch (_) {}
    }

    final urlToken = _readTokenFromUrl(win);
    if (urlToken != null) return urlToken;

    final storageToken = _readTokenFromBrowserStorage(win);
    if (storageToken != null) return storageToken;

    final cookieToken = _readTokenFromCookies(win);
    if (cookieToken != null) return cookieToken;

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

  String? _readTokenFromCbeBridge(Object win) {
    try {
      if (!js_util.hasProperty(win, 'CBEBirrPlusBridge')) return null;
      final bridge = js_util.getProperty(win, 'CBEBirrPlusBridge');
      if (bridge == null) return null;

      for (final property in const <String>[
        'authorization',
        'Authorization',
        'appToken',
        'apptoken',
        'token',
        'launchToken',
      ]) {
        if (!js_util.hasProperty(bridge, property)) continue;
        final token = _readToken(js_util.getProperty(bridge, property));
        if (token != null) return token;
      }

      for (final method in const <String>[
        'getAuthorization',
        'getAppToken',
        'getToken',
        'getLaunchToken',
      ]) {
        if (!js_util.hasProperty(bridge, method)) continue;
        final fn = js_util.getProperty(bridge, method);
        if (fn == null || !js_util.typeofEquals(fn, 'function')) continue;
        final token = _readToken(js_util.callMethod(bridge, method, const []));
        if (token != null) return token;
      }
    } catch (e) {
      AppLogger.warn('CBEBirr Plus bridge token read failed: $e');
    }
    return null;
  }

  String? _readTokenFromUrl(Object win) {
    try {
      final location = js_util.getProperty(win, 'location');
      final search = js_util.getProperty(location, 'search')?.toString() ?? '';
      final hash = js_util.getProperty(location, 'hash')?.toString() ?? '';
      final queryToken = _readTokenFromQuery(search);
      if (queryToken != null) return queryToken;
      return _readTokenFromQuery(hash);
    } catch (_) {
      return null;
    }
  }

  String? _readTokenFromQuery(String rawQuery) {
    final cleanQuery = rawQuery
        .replaceFirst(RegExp(r'^[?#]'), '')
        .replaceFirst(RegExp(r'^/[^?]*\?'), '');
    if (cleanQuery.trim().isEmpty) return null;

    try {
      final queryParameters = Uri.splitQueryString(cleanQuery);
      for (final key in const <String>[
        'authorization',
        'Authorization',
        'appToken',
        'apptoken',
        'token',
        'cbebirrToken',
        'cbeBirrToken',
        'cbe_token',
      ]) {
        final token = _readToken(queryParameters[key]);
        if (token != null) return token;
      }
    } catch (_) {}
    return null;
  }

  String? _readTokenFromBrowserStorage(Object win) {
    for (final storageName in const <String>[
      'sessionStorage',
      'localStorage'
    ]) {
      try {
        if (!js_util.hasProperty(win, storageName)) continue;
        final storage = js_util.getProperty(win, storageName);
        if (storage == null || !js_util.hasProperty(storage, 'getItem')) {
          continue;
        }
        for (final key in const <String>[
          'authorization',
          'Authorization',
          'appToken',
          'apptoken',
          'token',
          'cbebirrToken',
          'cbeBirrToken',
          'cbe_token',
          'CBEBIRR_PLUS_TOKEN',
        ]) {
          final token =
              _readToken(js_util.callMethod(storage, 'getItem', [key]));
          if (token != null) return token;
        }
      } catch (_) {}
    }
    return null;
  }

  String? _readTokenFromCookies(Object win) {
    try {
      if (!js_util.hasProperty(win, 'document')) return null;
      final document = js_util.getProperty(win, 'document');
      final cookie = js_util.getProperty(document, 'cookie')?.toString() ?? '';
      if (cookie.trim().isEmpty) return null;

      for (final entry in cookie.split(';')) {
        final index = entry.indexOf('=');
        if (index <= 0) continue;
        final key = Uri.decodeComponent(entry.substring(0, index).trim());
        if (!const <String>{
          'authorization',
          'Authorization',
          'appToken',
          'apptoken',
          'token',
          'cbebirrToken',
          'cbeBirrToken',
          'cbe_token',
        }.contains(key)) {
          continue;
        }
        final value = Uri.decodeComponent(entry.substring(index + 1).trim());
        final token = _readToken(value);
        if (token != null) return token;
      }
    } catch (_) {}
    return null;
  }

  String? _readToken(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return _stripBearerPrefix(trimmed);
    }

    try {
      for (final key in const <String>[
        'authorization',
        'Authorization',
        'appToken',
        'apptoken',
        'token',
        'accessToken',
        'launchToken',
      ]) {
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
