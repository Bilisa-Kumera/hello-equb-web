import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/core/superapp/superapp_diagnostics.dart';
import 'package:helloequb/features/superapp_auth/config/superapp_auth_config.dart';
import 'package:helloequb/features/superapp_auth/data/repositories/superapp_auth_repository_impl.dart';
import 'package:helloequb/features/superapp_auth/presentation/widgets/superapp_log_panel.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/style_constants.dart';

// ─── Step types ──────────────────────────────────────────────────────────────

enum _StepStatus { idle, loading, success, error }

class _LogStep {
  _LogStep(this.label);
  final String label;
  _StepStatus status = _StepStatus.idle;
  String? detail;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class CbeBirrPlusContinuePage extends StatefulWidget {
  const CbeBirrPlusContinuePage({super.key});

  @override
  State<CbeBirrPlusContinuePage> createState() =>
      _CbeBirrPlusContinuePageState();
}

class _CbeBirrPlusContinuePageState extends State<CbeBirrPlusContinuePage> {
  late final CbeBirrPlusBridge _bridge;
  late final SuperAppAuthRepositoryImpl _repo;

  final List<_LogStep> _steps = [];
  String? _launchToken;
  String? _error;
  bool _canRetry = false;

  @override
  void initState() {
    super.initState();
    _bridge = createCbeBirrPlusBridge();

    final cfg = SuperAppAuthConfig.fromEnv();
    final apiBase = cfg.apiBaseUrlOverride ?? '$baseUrl/';
    _repo = SuperAppAuthRepositoryImpl(
      apiBaseUrl: apiBase,
      tokenExchangePath: cfg.tokenExchangePath,
      profilePath: cfg.profilePath,
      telebirrGatewayAuthTokenUrl: cfg.telebirrGatewayAuthTokenUrl,
      cbeBirrPlusAutoLoginUrl: cfg.cbeBirrPlusAutoLoginUrl,
    );

    _steps.addAll([
      _LogStep('Connecting to CBEBirr Plus channel'),
      _LogStep('Reading launch token'),
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
      _launchToken = null;
      for (final s in _steps) {
        s.status = _StepStatus.idle;
        s.detail = null;
      }
    });

    // ── Step 0: wait for channel ──────────────────────────────────────────────
    _updateStep(0, _StepStatus.loading);
    AppLogger.log('CBEBirr Plus: waiting for channel');
    final channelOk = await _bridge.waitUntilAvailable(
      timeout: const Duration(seconds: 8),
      pollInterval: const Duration(milliseconds: 140),
    );
    if (!mounted) return;
    if (!channelOk) {
      _updateStep(0, _StepStatus.error, detail: 'Channel not found');
      setState(() {
        _error = 'Not running inside CBEBirr Plus.';
        _canRetry = false;
      });
      AppLogger.warn('CBEBirr Plus: channel unavailable, redirecting to login');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
      return;
    }
    _updateStep(0, _StepStatus.success, detail: 'Channel connected');

    // ── Step 1: read launch token ─────────────────────────────────────────────
    _updateStep(1, _StepStatus.loading);
    AppLogger.log('CBEBirr Plus: reading launch token');
    final token = _bridge.launchToken;
    if (token == null || token.trim().isEmpty) {
      _updateStep(1, _StepStatus.error, detail: 'No launch token provided');
      setState(() {
        _error =
            'CBEBirr Plus channel is connected but did not supply a token.\nPlease re-open via CBEBirr Plus.';
        _canRetry = true;
      });
      AppLogger.warn('CBEBirr Plus: launchToken is null/empty');
      return;
    }
    setState(() => _launchToken = token);
    _updateStep(1, _StepStatus.success,
        detail: 'Received ${token.length} chars');
    AppLogger.success('CBEBirr Plus launch token received (len=${token.length})');

    // ── Step 2: backend auto-login ────────────────────────────────────────────
    _updateStep(2, _StepStatus.loading);
    AppLogger.log('CBEBirr Plus: sending token to Hello Equb backend');
   try {
  await _repo.autoLoginCbeBirrPlusMiniApp(launchToken: token);

  if (!mounted) return;

  _updateStep(2, _StepStatus.success, detail: 'Login successful');
  AppLogger.success('CBEBirr Plus backend auto-login completed');
} on DioException catch (e) {
  String errorMessage;

  if (e.response != null) {
    errorMessage = '''
Status: ${e.response?.statusCode}

${e.response?.data}
''';
  } else {
    errorMessage = e.message ?? 'Unknown network error';
  }

  AppLogger.error('CBEBirr Plus backend login failed:\n$errorMessage');

  if (!mounted) return;

  _updateStep(2, _StepStatus.error, detail: errorMessage);

  setState(() {
    _error = errorMessage;
    _canRetry = true;
  });
} catch (e, stackTrace) {
  AppLogger.error('Unexpected login error: $e\n$stackTrace');

  if (!mounted) return;

  _updateStep(2, _StepStatus.error, detail: e.toString());

  setState(() {
    _error = e.toString();
    _canRetry = true;
  });
}

    // ── Step 3: navigate ──────────────────────────────────────────────────────
    _updateStep(3, _StepStatus.loading);
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final diag = createSuperAppDiagnostics().snapshot();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420.w),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 32.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CbeBirrPlusLogo(),
                  SizedBox(height: 18.h),
                  Text(
                    'CBEBirr Plus',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.poppins70022
                        .copyWith(color: AppColors.deepForestGreen),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Setting up your Hello Equb session…',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitleMuted,
                  ),
                  SizedBox(height: 20.h),
                  _StepLogPanel(steps: _steps),
                  if (_launchToken != null) ...[
                    SizedBox(height: 14.h),
                    _TokenPanel(
                      title: 'Launch Token',
                      token: _launchToken!,
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
                        style: AppTextStyles.poppins40013.copyWith(
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
                  SizedBox(height: 20.h),
                  _DiagnosticsPanel(diag: diag),
                  SizedBox(height: 12.h),
                  const SuperAppLogPanel(title: 'CBEBirr Plus logs'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _CbeBirrPlusLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        color: AppColors.deepForestGreen.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: 54.sp,
        color: AppColors.deepForestGreen,
      ),
    );
  }
}

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
        leading = Icon(Icons.error_rounded,
            size: 16.sp, color: Colors.red.shade600);
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
                  style: AppTextStyles.poppins50013.copyWith(color: labelColor),
                ),
                if (step.detail != null)
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Text(
                      step.detail!,
                      style: AppTextStyles.poppins40011.copyWith(
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
        border:
            Border.all(color: AppColors.deepForestGreen.withOpacity(0.35)),
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
                  style: AppTextStyles.poppins60012
                      .copyWith(color: Colors.black54),
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
                        style: AppTextStyles.poppins60011
                            .copyWith(color: AppColors.deepForestGreen),
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
            style: AppTextStyles.caption.copyWith(
              fontFamily: 'monospace',
              color: AppColors.deepForestGreen,
              height: 1.35,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${token.length} chars',
            style: AppTextStyles.captionSmall.copyWith(color: Colors.black38),
          ),
        ],
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
        style: AppTextStyles.poppins40011
            .copyWith(fontFamily: 'monospace', height: 1.25),
      ),
    );
  }
}
