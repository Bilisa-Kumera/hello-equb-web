import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/core/superapp/superapp_bridge.dart';
import 'package:helloequb/core/superapp/superapp_diagnostics.dart';
import 'package:helloequb/core/network/dio_error_formatter.dart';
import 'package:helloequb/features/superapp_auth/config/superapp_auth_config.dart';
import 'package:helloequb/features/superapp_auth/data/repositories/superapp_auth_repository_impl.dart';
import 'package:helloequb/features/superapp_auth/domain/usecases/attempt_superapp_auto_login.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_bloc.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_event.dart';
import 'package:helloequb/features/superapp_auth/presentation/bloc/superapp_auth_state.dart';
import 'package:helloequb/features/superapp_auth/presentation/widgets/superapp_log_panel.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

SuperAppAuthRepositoryImpl _createSuperAppRepo(SuperAppAuthConfig cfg) {
  final apiBase = cfg.apiBaseUrlOverride ?? '$baseUrl/';
  return SuperAppAuthRepositoryImpl(
    apiBaseUrl: apiBase,
    tokenExchangePath: cfg.tokenExchangePath,
    profilePath: cfg.profilePath,
    telebirrGatewayAuthTokenUrl: cfg.telebirrGatewayAuthTokenUrl,
  );
}

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
  const _TelebirrTokenGateView({
    required this.cfg,
    required this.repo,
  });

  final SuperAppAuthConfig cfg;
  final SuperAppAuthRepositoryImpl repo;

  @override
  State<_TelebirrTokenGateView> createState() => _TelebirrTokenGateViewState();
}

class _TelebirrTokenGateViewState extends State<_TelebirrTokenGateView> {
  String? _error;
  String? _appToken;
  String? _openId;
  String? _identityId;
  String? _gatewayRawResponse;
  bool _continuingToApp = false;
  bool _bridgeReady = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareBridge());
  }

  String _maskToken(String token) {
    if (token.length <= 16) return token;
    return '${token.substring(0, 8)}...${token.substring(token.length - 6)}';
  }

  Future<void> _prepareBridge() async {
    AppLogger.log('Telebirr token gate preparing bridge');

    if (widget.cfg.merchantAppId.trim().isEmpty) {
      setState(() {
        _error =
            'Missing merchant app id (set MERCHANT_APP_ID or SUPERAPP_APP_ID in .env).';
      });
      return;
    }

    final bridge = createSuperAppBridge();
    AppLogger.log('Waiting for Telebirr bridge');
    final ok = await bridge.waitUntilAvailable(
      timeout: const Duration(seconds: 30),
      pollInterval: const Duration(milliseconds: 140),
    );
    AppLogger.log('Telebirr bridge wait result=$ok');

    if (!mounted) return;
    if (!ok) {
      AppLogger.warn('Telebirr bridge unavailable; redirecting to /login');
      context.go('/login');
      return;
    }

    setState(() => _bridgeReady = true);
  }

  Future<void> _loadAppToken() async {
    if (!_bridgeReady || _isLoading) return;

    AppLogger.log('Telebirr auto-login tapped (user gesture)');
    setState(() {
      _isLoading = true;
      _error = null;
      _appToken = null;
      _openId = null;
      _identityId = null;
      _gatewayRawResponse = null;
    });

    if (widget.cfg.merchantAppId.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _error =
            'Missing merchant app id (set MERCHANT_APP_ID or SUPERAPP_APP_ID in .env).';
      });
      return;
    }

    try {
      AppLogger.log('Requesting Telebirr app token');
      final appToken = await widget.repo.getMiniAppToken(
        merchantAppId: widget.cfg.merchantAppId.trim(),
      );
      AppLogger.success('Telebirr app token received (len=${appToken.length})');

      String? openId;
      String? identityId;
      String? rawPayload;
      String? gatewayWarning;

      try {
        AppLogger.log('Calling Telebirr gateway auth/token');
        final gatewayResult =
            await widget.repo.exchangeAppTokenWithTelebirrGateway(
          appToken: appToken,
        );
        openId = gatewayResult['openId']?.toString();
        identityId = gatewayResult['identityId']?.toString();
        rawPayload = gatewayResult['gatewayPayload']?.toString();
        AppLogger.success(
          'Telebirr gateway user info openId=$openId identityId=$identityId',
        );
      } catch (e) {
        final gatewayUrl = widget.cfg.telebirrGatewayAuthTokenUrl;
        gatewayWarning =
            '${formatTelebirrGatewayError(e, gatewayUrl: gatewayUrl)} '
            'App token was received — tap Continue to log in via Hello Equb.';
        AppLogger.warn('Telebirr gateway exchange failed (non-fatal): $e');
      }

      if (!mounted) return;
      setState(() {
        _appToken = appToken;
        _openId = openId;
        _identityId = identityId;
        _gatewayRawResponse = gatewayWarning ?? rawPayload;
        if (gatewayWarning != null) _error = null;
      });
      // Automatically continue to app login immediately after obtaining the app token.
      // This posts the token to the backend (auto-login) without requiring user tap.
      if (mounted && _appToken != null && _appToken!.isNotEmpty) {
        await _continueToApp();
      }
    } catch (e) {
      AppLogger.error('Telebirr app token failed: $e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueToApp() async {
    final appToken = _appToken;
    if (appToken == null || appToken.isEmpty) return;

    setState(() {
      _continuingToApp = true;
      _error = null;
    });

    try {
      AppLogger.log('Exchanging Telebirr app token with backend');
      if (_openId != null) {
        DataController().storeData('open_id', _openId);
      }
      if (_identityId != null) {
        DataController().storeData('identityId', _identityId);
      }
      await widget.repo.loginWithMiniAppToken(
        appToken: appToken,
        phoneNumber: '',
      );
      if (!mounted) return;
      AppLogger.success('Telebirr backend auth completed');
      context.go('/home');
    } catch (e) {
      AppLogger.error('Telebirr backend login failed: $e');
      if (!mounted) return;
      setState(() {
        _continuingToApp = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final diag = createSuperAppDiagnostics().snapshot();
    final hasUserInfo = _appToken != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420.w),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 24.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TelebirrLogo(),
                SizedBox(height: 18.h),
                Text(
                  'Telebirr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepForestGreen,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  hasUserInfo
                      ? 'Telebirr login data received'
                      : _bridgeReady
                          ? 'Tap Auto Login to get your Telebirr token.'
                          : 'Preparing Telebirr bridge...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),
                if (!_bridgeReady)
                  const CircularProgressIndicator()
                else if (_isLoading)
                  const CircularProgressIndicator()
                else if (hasUserInfo) ...[
                  _ResultPanel(
                    title: 'App token',
                    value: _maskToken(_appToken!),
                    subtitle: 'Length: ${_appToken!.length}',
                  ),
                  SizedBox(height: 10.h),
                  _ResultPanel(
                    title: 'openId',
                    value: _openId ?? '(not returned)',
                    highlight: _openId != null,
                  ),
                  SizedBox(height: 10.h),
                  _ResultPanel(
                    title: 'identityId',
                    value: _identityId ?? '(not returned)',
                    highlight: _identityId != null,
                  ),
                  if (_gatewayRawResponse != null) ...[
                    SizedBox(height: 10.h),
                    _ResultPanel(
                      title: _openId == null && _identityId == null
                          ? 'Gateway note'
                          : 'Gateway response',
                      value: _gatewayRawResponse!,
                      monospace: true,
                    ),
                  ],
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continuingToApp ? null : _continueToApp,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: _continuingToApp
                            ? SizedBox(
                                height: 18.h,
                                width: 18.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Continue to app'),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  TextButton(
                    onPressed: _continuingToApp ? null : _loadAppToken,
                    child: const Text('Refresh token'),
                  ),
                ] else ...[
                  if (_error != null)
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.red.shade700,
                      ),
                    ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loadAppToken,
                      child: const Text('Auto Login'),
                    ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: 8.h),
                    TextButton(
                      onPressed: _loadAppToken,
                      child: const Text('Try again'),
                    ),
                  ],
                ],
                SizedBox(height: 12.h),
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

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.title,
    required this.value,
    this.subtitle,
    this.highlight = false,
    this.monospace = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final bool highlight;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8.r),
        color: const Color(0xFFF7F7F7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 6.h),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: highlight ? Colors.red.shade700 : AppColors.deepForestGreen,
              fontFamily: monospace ? 'monospace' : null,
              height: 1.3,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4.h),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 11.sp, color: Colors.black45),
            ),
          ],
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
