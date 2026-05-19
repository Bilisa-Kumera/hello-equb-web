import 'superapp_diagnostics.dart';

class _SuperAppDiagnosticsStub implements SuperAppDiagnostics {
  @override
  Map<String, String> snapshot() => <String, String>{
        'platform': 'non-web',
      };
}

SuperAppDiagnostics createSuperAppDiagnosticsImpl() => _SuperAppDiagnosticsStub();

