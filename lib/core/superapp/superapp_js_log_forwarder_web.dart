// import 'dart:async';
// import 'dart:html' as html;
// import 'dart:js_util' as js_util;
//
// import 'package:helloequb/core/logging/app_logger.dart';
//
// bool _initialized = false;
// Timer? _pollTimer;
// int _bufferCursor = 0;
//
// void initSuperAppJsLogForwarderImpl() {
//   if (_initialized) return;
//   _initialized = true;
//
//   // Listen to CustomEvent('superapp:log') if supported.
//   try {
//     html.window.addEventListener('superapp:log', (event) {
//       try {
//         final custom = event as dynamic;
//         final detail = custom.detail;
//         _consumeDetail(detail);
//       } catch (_) {
//         // Ignore; polling fallback will still capture buffer logs.
//       }
//     });
//   } catch (_) {}
//
//   // Poll the global buffer as a fallback (some WebViews block CustomEvent).
//   _pollTimer?.cancel();
//   _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
//     _drainBuffer();
//   });
//
//   // Replay any logs that happened before Flutter booted.
//   _drainBuffer();
//   AppLogger.log('SuperApp JS log forwarder initialized');
// }
//
// void _drainBuffer() {
//   final win = js_util.globalThis;
//   if (!js_util.hasProperty(win, '__superappDebugBuffer')) return;
//
//   final buffer = js_util.getProperty(win, '__superappDebugBuffer');
//   if (buffer == null) return;
//
//   final length = _tryGetLength(buffer);
//   if (length <= 0) return;
//
//   for (var i = _bufferCursor; i < length; i++) {
//     try {
//       final entry = js_util.getProperty(buffer, i);
//       _consumeDetail(entry);
//     } catch (_) {
//       // Skip broken entries.
//     }
//   }
//   _bufferCursor = length;
// }
//
// int _tryGetLength(Object buffer) {
//   try {
//     final len = js_util.getProperty(buffer, 'length');
//     if (len is int) return len;
//     if (len is num) return len.toInt();
//   } catch (_) {}
//   return 0;
// }
//
// void _consumeDetail(dynamic detail) {
//   if (detail == null) return;
//
//   String level = 'INFO';
//   String message = '(no message)';
//   String? ts;
//
//   try {
//     final rawLevel = js_util.getProperty(detail, 'level');
//     if (rawLevel != null) level = rawLevel.toString();
//   } catch (_) {}
//   try {
//     final rawMsg = js_util.getProperty(detail, 'message');
//     if (rawMsg != null) message = rawMsg.toString();
//   } catch (_) {}
//   try {
//     final rawTs = js_util.getProperty(detail, 'ts');
//     if (rawTs != null) ts = rawTs.toString();
//   } catch (_) {}
//
//   final prefix = ts == null || ts.isEmpty ? 'JS' : 'JS@$ts';
//   final line = '$prefix: $message';
//
//   switch (level.toUpperCase()) {
//     case 'ERROR':
//       AppLogger.error(line);
//       break;
//     case 'WARN':
//     case 'WARNING':
//       AppLogger.warn(line);
//       break;
//     case 'SUCCESS':
//       AppLogger.success(line);
//       break;
//     default:
//       AppLogger.log(line);
//   }
// }
//
