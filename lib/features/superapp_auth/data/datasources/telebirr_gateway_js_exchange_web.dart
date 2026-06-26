// // ignore_for_file: avoid_web_libraries_in_flutter
//
// import 'dart:convert';
//
// import 'package:helloequb/core/logging/app_logger.dart';
// import 'dart:js_util' as js_util;
//
// Future<Map<String, dynamic>?> exchangeTelebirrAuthTokenViaJs({
//   required String gatewayUrl,
//   required String authToken,
// }) async {
//   final win = js_util.globalThis;
//
//   try {
//     if (js_util.hasProperty(win, 'SuperAppBridge')) {
//       final bridge = js_util.getProperty(win, 'SuperAppBridge');
//       if (bridge != null &&
//           js_util.hasProperty(bridge, 'exchangeAuthToken')) {
//         AppLogger.log('delegating gateway auth/token to SuperAppBridge.fetch');
//         final promise = js_util.callMethod(
//           bridge,
//           'exchangeAuthToken',
//           [gatewayUrl, authToken],
//         );
//         final result = await js_util.promiseToFuture<dynamic>(promise);
//         return _normalizeMap(result);
//       }
//     }
//   } catch (e) {
//     AppLogger.warn('SuperAppBridge.exchangeAuthToken failed: $e');
//     rethrow;
//   }
//
//   return null;
// }
//
// Map<String, dynamic>? _normalizeMap(dynamic data) {
//   if (data == null) return null;
//   if (data is Map<String, dynamic>) return data;
//   if (data is Map) return Map<String, dynamic>.from(data);
//   if (data is String) {
//     final decoded = jsonDecode(data);
//     if (decoded is Map<String, dynamic>) return decoded;
//     if (decoded is Map) return Map<String, dynamic>.from(decoded);
//   }
//   return <String, dynamic>{'data': data};
// }
