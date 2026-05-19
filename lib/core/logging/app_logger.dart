import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppLogger {
  // Telebirr SuperApp WebView typically has no accessible console, so we keep
  // logging enabled on Flutter Web unless explicitly disabled by UI.
  static bool _enabled = kDebugMode || kIsWeb;
  static const int _maxLines = 600;
  static final ValueNotifier<List<String>> _lines =
      ValueNotifier<List<String>>(<String>[]);

  static bool get enabled => _enabled;
  static ValueListenable<List<String>> get lines => _lines;

  static void initFromEnv() {
    final raw = (dotenv.env['SUPERAPP_DEBUG'] ?? '').trim().toLowerCase();
    if (raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on') {
      _enabled = true;
    }
  }

  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  static void clear() {
    _lines.value = <String>[];
  }

  static void log(String message) {
    if (!_enabled) return;
    _add('INFO', message);
  }

  static void warn(String message) {
    if (!_enabled) return;
    _add('WARN', message);
  }

  static void success(String message) {
    if (!_enabled) return;
    _add('SUCCESS', message);
  }

  static void error(String message) {
    if (!_enabled) return;
    _add('ERROR', message);
  }

  static void _add(String level, String message) {
    final now = DateTime.now();
    final ts =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final line = '[$ts][$level] $message';
    debugPrint('[SuperApp] $line');

    final next = List<String>.from(_lines.value);
    next.add(line);
    if (next.length > _maxLines) {
      next.removeRange(0, next.length - _maxLines);
    }
    _lines.value = next;
  }
}
