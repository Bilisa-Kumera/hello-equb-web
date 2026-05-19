import 'dart:js_util' as js_util;

import 'superapp_diagnostics.dart';

class _SuperAppDiagnosticsWeb implements SuperAppDiagnostics {
  @override
  Map<String, String> snapshot() {
    final out = <String, String>{};
    final win = js_util.globalThis;

    out['has.window.isSuperAppWebView'] =
        js_util.hasProperty(win, 'isSuperAppWebView').toString();
    out['has.window.getMiniAppToken'] =
        js_util.hasProperty(win, 'getMiniAppToken').toString();

    try {
      if (js_util.hasProperty(win, 'isSuperAppWebView')) {
        final r = js_util.callMethod(win, 'isSuperAppWebView', const []);
        out['call.isSuperAppWebView'] = r.toString();
      }
    } catch (e) {
      out['call.isSuperAppWebView.error'] = e.toString();
    }

    try {
      final xm = js_util.getProperty(win, 'xm');
      out['has.window.xm'] = (xm != null).toString();
      if (xm != null) {
        final nativeFn = js_util.getProperty(xm, 'native');
        out['has.window.xm.native'] = (nativeFn != null).toString();
        out['type.window.xm.native'] = nativeFn == null
            ? 'null'
            : js_util.typeofEquals(nativeFn, 'function')
                ? 'function'
                : 'non-function';
      }
    } catch (e) {
      out['window.xm.error'] = e.toString();
    }

    try {
      final navigator = js_util.getProperty(win, 'navigator');
      if (navigator != null) {
        final ua = js_util.getProperty(navigator, 'userAgent');
        if (ua != null) out['userAgent'] = ua.toString();
      }
    } catch (_) {}

    return out;
  }
}

SuperAppDiagnostics createSuperAppDiagnosticsImpl() => _SuperAppDiagnosticsWeb();

