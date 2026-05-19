import 'superapp_js_log_forwarder_stub.dart'
    if (dart.library.html) 'superapp_js_log_forwarder_web.dart';

/// Starts forwarding JS-side SuperApp logs (from `web/superapp.js`) into
/// [AppLogger] so they appear in the in-app debug overlay.
void initSuperAppJsLogForwarder() => initSuperAppJsLogForwarderImpl();

