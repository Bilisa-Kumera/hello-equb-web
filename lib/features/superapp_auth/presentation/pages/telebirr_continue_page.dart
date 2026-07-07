import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/superapp/superapp_bridge.dart';
import 'package:helloequb/core/superapp/superapp_diagnostics.dart';
import 'package:helloequb/features/superapp_auth/config/superapp_auth_config.dart';
import 'package:helloequb/features/superapp_auth/data/repositories/superapp_auth_repository_impl.dart';
import 'package:helloequb/features/superapp_auth/domain/usecases/attempt_superapp_auto_login.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_bloc.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_event.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_state.dart';
import 'package:helloequb/features/superapp_auth/presentation/widgets/superapp_log_panel.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:flutter/services.dart';

SuperAppAuthRepositoryImpl _createSuperAppRepo(SuperAppAuthConfig cfg) {
  final apiBase = cfg.apiBaseUrlOverride ?? '$baseUrl/';
  return SuperAppAuthRepositoryImpl(
    apiBaseUrl: apiBase,
    tokenExchangePath: cfg.tokenExchangePath,
    profilePath: cfg.profilePath,
    telebirrGatewayAuthTokenUrl: cfg.telebirrGatewayAuthTokenUrl,
    cbeBirrPlusAutoLoginUrl: cfg.cbeBirrPlusAutoLoginUrl,
  );
}

// ─── Step types ──────────────────────────────────────────────────────────────

enum _StepStatus { idle, loading, success, error }

class _LogStep {
  _LogStep(this.label);
  final String label;
  _StepStatus status = _StepStatus.idle;
  String? detail;
}

// ─── Token gate page ─────────────────────────────────────────────────────────

class TelebirrContinuePage extends StatelessWidget {
  const TelebirrContinuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = SuperAppAuthConfig.fromEnv();
    return _TelebirrTokenGateView(
      cfg: cfg,
      repo: _createSuperAppRepo(cfg),
    );
  }
}

class _TelebirrTokenGateView extends StatefulWidget {
  const _TelebirrTokenGateView({required this.cfg, required this.repo});

  final SuperAppAuthConfig cfg;
  final SuperAppAuthRepositoryImpl repo;

  @override
  State<_TelebirrTokenGateView> createState() => _TelebirrTokenGateViewState();
}

class _TelebirrTokenGateViewState extends State<_TelebirrTokenGateView> {
  final List<_LogStep> _steps = [];
  String? _appToken;
  String? _error;
  bool _canRetry = false;
  bool _isFromCbeBirr = false;

  String? _authApiUrl;
  Map<String, dynamic>? _authRequestBody;
  Map<String, dynamic>? _authResponseBody;

  @override


  void initState() {
    super.initState();
    _steps.addAll([
      _LogStep('Connecting to Telebirr bridge'),
      _LogStep('Getting app token from Telebirr'),
      _LogStep('Authenticating with Hello Equb'),
      _LogStep('Redirecting to app'),
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAutoLogin());
  }

  void _updateStep(int index, _StepStatus status, {String? detail}) {
    if (!mounted) return;
    setState(() {
      _steps[index].status = status;
      if (detail != null) _steps[index].detail = detail;
    });
  }

  Future<void> _runAutoLogin() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _canRetry = false;
      _appToken = null;
      _isFromCbeBirr = false;
      _authApiUrl = null;
      _authRequestBody = null;
      _authResponseBody = null;
      for (final s in _steps) {
        s.status = _StepStatus.idle;
        s.detail = null;
      }
    });

    // ── CBE Birr Plus early check ─────────────────────────────────────────────
    final cbeBridge = createCbeBirrPlusBridge();
    if (cbeBridge.isAvailable) {
      AppLogger.log('CBEBirr Plus detected on Telebirr page');
      final loggedIn = DataController().retrieveData<bool>('isLoggedIn') == true;
      if (!mounted) return;
      if (loggedIn) {
        context.go('/home');
      } else {
        context.go('/login');
      }
      return;
    }

    if (widget.cfg.merchantAppId.trim().isEmpty) {
      setState(() => _error =
          'Missing merchant app id (set MERCHANT_APP_ID or SUPERAPP_APP_ID in .env).');
      return;
    }

    // ── Step 0: wait for bridge ───────────────────────────────────────────────
    _updateStep(0, _StepStatus.loading);
    AppLogger.log('Telebirr: waiting for bridge');
    final bridge = createSuperAppBridge();
    final bridgeOk = await bridge.waitUntilAvailable(
      timeout: const Duration(seconds: 30),
      pollInterval: const Duration(milliseconds: 140),
    );
    if (!mounted) return;
    if (!bridgeOk) {
      _updateStep(0, _StepStatus.error, detail: 'Bridge not found after 30 s');
      setState(() {
        _error = 'Not running inside Telebirr super app.';
        _canRetry = true;
      });
      return;
    }
    _updateStep(0, _StepStatus.success, detail: 'Bridge connected');

    // ── Step 1: get app token ─────────────────────────────────────────────────
    _updateStep(1, _StepStatus.loading);
    AppLogger.log('Telebirr: requesting app token');
    String appToken;
    try {
      appToken = await widget.repo.getMiniAppToken(
        merchantAppId: widget.cfg.merchantAppId.trim(),
      );
      if (!mounted) return;
      appToken = appToken.replaceFirst(RegExp(r'^InApp:'), '');
      setState(() => _appToken = appToken);
      _updateStep(1, _StepStatus.success,
          detail: 'Received ${appToken.length} chars');
      AppLogger.success('Telebirr app token received (len=${appToken.length})');
    } catch (e) {
      AppLogger.error('Telebirr get token failed: $e');
      if (!mounted) return;
      _updateStep(1, _StepStatus.error, detail: e.toString());
      setState(() {
        _error = 'Failed to get Telebirr token.\n$e';
        _canRetry = true;
      });
      return;
    }

    // ── Step 2: backend auto-login ────────────────────────────────────────────
    _updateStep(2, _StepStatus.loading);
    AppLogger.log('Telebirr: sending token to Hello Equb backend');
    setState(() {
      _authApiUrl = widget.cfg.telebirrGatewayAuthTokenUrl;
      _authRequestBody = {'token': appToken};
    });
    try {
      await widget.repo.autoLoginTelebirrMiniApp(
        appToken: appToken,
        onResponse: (url, reqBody, resPayload) {
          if (mounted) setState(() => _authResponseBody = resPayload);
        },
      );
      if (!mounted) return;
      _updateStep(2, _StepStatus.success, detail: 'Login successful');
      AppLogger.success('Telebirr backend auto-login completed');
    } catch (e) {
      AppLogger.error('Telebirr backend login failed: $e');
      if (!mounted) return;
      _updateStep(2, _StepStatus.error, detail: e.toString());
      setState(() {
        _error = 'Login failed.\n$e';
        _canRetry = true;
      });
      return;
    }

    // ── Step 3: navigate ──────────────────────────────────────────────────────
    _updateStep(3, _StepStatus.success, detail: 'Ready to continue');
  }

  @override
  Widget build(BuildContext context) {
    final diag = createSuperAppDiagnostics().snapshot();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420.w),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 32.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TelebirrLogo(),
                SizedBox(height: 18.h),
                Text(
                  'Telebirr Super App',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepForestGreen,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Setting up your Hello Equb session…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: Colors.black54),
                ),
                SizedBox(height: 20.h),
                if (_isFromCbeBirr) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      border: Border.all(color: const Color(0xFFFFB300)),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            size: 36.sp, color: const Color(0xFFFFB300)),
                        SizedBox(height: 8.h),
                        Text(
                          'This is rendering from CBE Birr Plus',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7B5800),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/cbebirr'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepForestGreen,
                              foregroundColor: AppColors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: const Text('Navigate to CBE Birr'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _StepLogPanel(steps: _steps),
                  if (_authApiUrl != null) ...[
                    SizedBox(height: 14.h),
                    _AuthCallPanel(
                      apiUrl: _authApiUrl!,
                      requestBody: _authRequestBody ?? const {},
                      responseBody: _authResponseBody,
                    ),
                  ],
                  if (_appToken != null) ...[
                    SizedBox(height: 14.h),
                    _TokenPanel(
                      title: 'App Token',
                      token: _appToken!,
                    ),
                  ],
                  if (_error != null) ...[
                    SizedBox(height: 14.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.red.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (_canRetry) ...[
                      SizedBox(height: 10.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _runAutoLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepForestGreen,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ],
                ],
                SizedBox(height: 20.h),
                _DiagnosticsPanel(diag: diag),
                SizedBox(height: 12.h),
                const SuperAppLogPanel(title: 'Telebirr logs'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Telebirr Mini-App Login Page (phone-confirmation flow) ──────────────────

class TelebirrMiniAppLoginPage extends StatelessWidget {
  const TelebirrMiniAppLoginPage({super.key, required this.appToken});

  final String appToken;

  @override
  Widget build(BuildContext context) {
    final cfg = SuperAppAuthConfig.fromEnv();
    final repo = _createSuperAppRepo(cfg);

    return BlocProvider(
      create: (_) => SuperAppAuthBloc(
        attemptAutoLogin: AttemptSuperAppAutoLogin(repo),
        isSuperAppAvailable: () => repo.isSuperAppAvailable,
      ),
      child: _TelebirrMiniAppLoginView(appToken: appToken),
    );
  }
}

class _TelebirrMiniAppLoginView extends StatefulWidget {
  const _TelebirrMiniAppLoginView({required this.appToken});

  final String appToken;

  @override
  State<_TelebirrMiniAppLoginView> createState() =>
      _TelebirrMiniAppLoginViewState();
}

class _TelebirrMiniAppLoginViewState extends State<_TelebirrMiniAppLoginView> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final savedPhoneNumber =
        DataController().retrieveData<String>('phoneNumber')?.trim() ?? '';
    _phoneController = TextEditingController(text: savedPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diag = createSuperAppDiagnostics().snapshot();
    return BlocConsumer<SuperAppAuthBloc, SuperAppAuthState>(
      listener: (context, state) {
        if (state is SuperAppAuthSuccess) {
          AppLogger.log('navigate to dashboard');
          context.go('/home');
        }
      },
      builder: (context, state) {
        final isLoading = state is SuperAppAuthInProgress;
        final error = state is SuperAppAuthFailure ? state.message : null;

        return Scaffold(
          backgroundColor: AppColors.white,
          body: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420.w),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TelebirrLogo(),
                    SizedBox(height: 18.h),
                    Text(
                      'Continue with Telebirr',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepForestGreen,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Confirm your phone number to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: _phoneController,
                      enabled: !isLoading,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+2519...',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onSubmitted: (_) => _startLogin(context),
                    ),
                    SizedBox(height: 12.h),
                    if (error != null) ...[
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.red.shade700,
                        ),
                      ),
                      SizedBox(height: 10.h),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            isLoading ? null : () => _startLogin(context),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: isLoading
                              ? SizedBox(
                                  height: 18.h,
                                  width: 18.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Continue with Telebirr'),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _DiagnosticsPanel(diag: diag),
                    SizedBox(height: 12.h),
                    const SuperAppLogPanel(title: 'Auth / Network logs'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startLogin(BuildContext context) {
    AppLogger.log(
      'Continue with Telebirr tapped; sending backend login phone=${_phoneController.text.trim()} tokenLen=${widget.appToken.length}',
    );
    context.read<SuperAppAuthBloc>().add(
          SuperAppAuthStarted(
            appToken: widget.appToken,
            phoneNumber: _phoneController.text,
          ),
        );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _StepLogPanel extends StatelessWidget {
  const _StepLogPanel({required this.steps});

  final List<_LogStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8.r),
        color: const Color(0xFFF7F7F7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps.map((s) => _StepRow(step: s)).toList(),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _LogStep step;

  @override
  Widget build(BuildContext context) {
    final Widget leading;
    final Color labelColor;

    switch (step.status) {
      case _StepStatus.loading:
        leading = SizedBox(
          width: 16.sp,
          height: 16.sp,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.deepForestGreen,
          ),
        );
        labelColor = AppColors.deepForestGreen;
        break;
      case _StepStatus.success:
        leading = Icon(Icons.check_circle_rounded,
            size: 16.sp, color: Colors.green.shade600);
        labelColor = Colors.green.shade700;
        break;
      case _StepStatus.error:
        leading =
            Icon(Icons.error_rounded, size: 16.sp, color: Colors.red.shade600);
        labelColor = Colors.red.shade700;
        break;
      case _StepStatus.idle:
      default:
        leading = Icon(Icons.radio_button_unchecked_rounded,
            size: 16.sp, color: Colors.black26);
        labelColor = Colors.black38;
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 20.w, child: Center(heightFactor: 1, child: leading)),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
                if (step.detail != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      step.detail!,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: labelColor.withOpacity(0.75),
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a token value with a copy-to-clipboard button.
class _TokenPanel extends StatelessWidget {
  const _TokenPanel({required this.title, required this.token});

  final String title;
  final String token;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.deepForestGreen.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(8.r),
        color: AppColors.deepForestGreen.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _copy(context),
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded,
                          size: 16.sp, color: AppColors.deepForestGreen),
                      SizedBox(width: 4.w),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.deepForestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          SelectableText(
            token,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'monospace',
              color: AppColors.deepForestGreen,
              height: 1.35,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${token.length} chars',
            style: TextStyle(fontSize: 10.sp, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

class _TelebirrLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/telebirr.png',
      width: 110.w,
      height: 110.w,
      errorBuilder: (_, __, ___) => Icon(
        Icons.account_balance_wallet,
        size: 90.sp,
        color: AppColors.deepForestGreen,
      ),
    );
  }
}

class _DiagnosticsPanel extends StatelessWidget {
  const _DiagnosticsPanel({required this.diag});

  final Map<String, String> diag;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8.r),
        color: const Color(0xFFF7F7F7),
      ),
      child: SelectableText(
        diag.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11.sp,
          height: 1.25,
        ),
      ),
    );
  }
}

// ─── Auth call inspector panel ────────────────────────────────────────────────

class _AuthCallPanel extends StatelessWidget {
  const _AuthCallPanel({
    required this.apiUrl,
    required this.requestBody,
    this.responseBody,
  });

  final String apiUrl;
  final Map<String, dynamic> requestBody;
  final Map<String, dynamic>? responseBody;

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String _prettyJson(Map<String, dynamic> map) {
    final buffer = StringBuffer('{\n');
    final entries = map.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final key = entries[i].key;
      var value = entries[i].value;
      if (value is String && value.length > 60) {
        value = '${value.substring(0, 60)}…';
      }
      final comma = i < entries.length - 1 ? ',' : '';
      buffer.writeln('  "$key": "$value"$comma');
    }
    buffer.write('}');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.deepForestGreen.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(8.r),
        color: const Color(0xFFF2F8F4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(label: 'API', value: 'POST'),
          _MonoBlock(text: apiUrl),
          const _Divider(),
          const _SectionHeader(label: 'Headers', value: ''),
          _MonoBlock(
            text: _headers.entries.map((e) => '${e.key}: ${e.value}').join('\n'),
          ),
          const _Divider(),
          const _SectionHeader(label: 'Request body', value: ''),
          _MonoBlock(text: _prettyJson(requestBody)),
          const _Divider(),
          _SectionHeader(
            label: 'Response',
            value: responseBody == null ? 'pending…' : '200 OK',
            valueColor: responseBody == null
                ? Colors.black38
                : Colors.green.shade700,
          ),
          if (responseBody != null)
            _MonoBlock(text: _prettyJson(responseBody!)),
          if (responseBody == null)
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 10.h),
              child: SizedBox(
                height: 12.h,
                width: 12.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.deepForestGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 2.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.deepForestGreen,
              letterSpacing: 0.5,
            ),
          ),
          if (value.isNotEmpty) ...[
            SizedBox(width: 6.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonoBlock extends StatelessWidget {
  const _MonoBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 8.h),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10.sp,
          color: Colors.black87,
          height: 1.45,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Colors.black.withOpacity(0.06));
  }
}
