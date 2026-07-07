import 'superapp_diagnostics_stub.dart'
    if (dart.library.html) 'superapp_diagnostics_web.dart';

abstract class SuperAppDiagnostics {
  Map<String, String> snapshot();
}

SuperAppDiagnostics createSuperAppDiagnostics() => createSuperAppDiagnosticsImpl();

