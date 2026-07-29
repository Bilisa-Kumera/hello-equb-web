import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/superapp/superapp_bridge.dart';
import 'package:helloequb/features/superapp_auth/config/superapp_auth_config.dart';
import 'package:helloequb/features/superapp_auth/data/repositories/superapp_auth_repository_impl.dart';
import 'package:helloequb/features/superapp_auth/domain/usecases/attempt_superapp_auto_login.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_bloc.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_event.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_state.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

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
  String? _error;
  bool _canRetry = false;
  bool _isAuthenticating = true;
  bool _isFromCbeBirr = false;

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
      _isAuthenticating = true;
      _isFromCbeBirr = false;
      for (final s in _steps) {
        s.status = _StepStatus.idle;
        s.detail = null;
      }
    });

    // ── CBE Birr Plus early check ─────────────────────────────────────────────
    final cbeBridge = createCbeBirrPlusBridge();
    if (cbeBridge.isAvailable) {
      AppLogger.log('CBEBirr Plus detected on Telebirr page');
      final loggedIn =
          DataController().retrieveData<bool>('isLoggedIn') == true;
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
      setState(() => _isAuthenticating = false);
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
        _isAuthenticating = false;
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
        _isAuthenticating = false;
      });
      return;
    }

    // ── Step 2: backend auto-login ────────────────────────────────────────────
    _updateStep(2, _StepStatus.loading);
    AppLogger.log('Telebirr: sending token to Hello Equb backend');
    try {
      await widget.repo.autoLoginTelebirrMiniApp(appToken: appToken);
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
        _isAuthenticating = false;
      });
      return;
    }

    // ── Step 3: navigate ──────────────────────────────────────────────────────
    _updateStep(3, _StepStatus.success, detail: 'Redirecting to home');
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
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
                  'Continue with telebirr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepForestGreen,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Setting up your Hello Equb session...',
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
                  if (_isAuthenticating && _error == null) ...[
                    SizedBox(
                      height: 28.w,
                      width: 28.w,
                      child: const CircularProgressIndicator(strokeWidth: 2.5),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startLogin(context);
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Signing you in with Telebirr...',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp),
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
                    if (isLoading || error == null)
                      Column(
                        children: [
                          SizedBox(
                            height: 18.h,
                            width: 18.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Redirecting to home...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    if (error != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : () => _startLogin(context),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            child: const Text('Retry'),
                          ),
                        ),
                      ),
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
      'Starting Telebirr backend login phone=${_phoneController.text.trim()} tokenLen=${widget.appToken.length}',
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
