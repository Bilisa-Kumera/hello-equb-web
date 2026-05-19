import 'dart:async';
import 'package:helloequb/features/app_update/presentation/providers/update_provider.dart';
import 'package:helloequb/features/app_update/presentation/providers/update_state.dart';
import 'package:helloequb/features/superapp_auth/config/superapp_auth_config.dart';
import 'package:helloequb/features/superapp_auth/data/repositories/superapp_auth_repository_impl.dart';
import 'package:helloequb/features/superapp_auth/domain/usecases/attempt_superapp_auto_login.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/language_screen.dart';
import 'package:helloequb/core/superapp/superapp_bridge.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final UpdateProvider _updateProvider;
  Timer? _timer;
  bool _hasScheduledNavigation = false;
  bool _hasTriggeredUpdateCheck = false;
  bool _blockNavigationForSuperAppLogin = false;
  String? _shownErrorMessage;
  final DataController dataController = DataController();

  @override
  void initState() {
    super.initState();
    _updateProvider = context.read<UpdateProvider>();
    _updateProvider.addListener(_onUpdateStateChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _updateProvider.removeListener(_onUpdateStateChanged);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      await dataController.initialize();
    } catch (_) {
      // Continue startup even if local cache initialization fails.
    }

    if (!mounted) return;
    _hasTriggeredUpdateCheck = true;
    unawaited(_updateProvider.checkForUpdateOnStartup());

    // Web is only supported inside the SuperApp webview.
    if (kIsWeb) {
      final bridge = createSuperAppBridge();
      AppLogger.log('App started (web)');

      // Some SuperApp webviews inject the bridge after Flutter starts rendering.
      final ok = await bridge.waitUntilAvailable(
        timeout: const Duration(seconds: 12),
        pollInterval: const Duration(milliseconds: 140),
      );

      if (!ok) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/not-superapp');
        });
        return;
      }

      AppLogger.success('Telebirr bridge detected');

      // If rendered inside SuperApp, attempt auto-login from splash.
      if (dataController.retrieveData<bool>('isLoggedIn') != true) {
        final cfg = SuperAppAuthConfig.fromEnv();
        if (cfg.merchantAppId.trim().isNotEmpty) {
          try {
            _blockNavigationForSuperAppLogin = true;
            AppLogger.log('Backend authentication started');
            final apiBase = cfg.apiBaseUrlOverride ?? '$baseUrl/';
            final repo = SuperAppAuthRepositoryImpl(
              apiBaseUrl: apiBase,
              tokenExchangePath: cfg.tokenExchangePath,
              profilePath: cfg.profilePath,
            );
            await AttemptSuperAppAutoLogin(repo)(
              merchantAppId: cfg.merchantAppId.trim(),
            );
            AppLogger.success('Authentication success');
            _blockNavigationForSuperAppLogin = false;
            if (mounted) {
              _handleUpdateState(_updateProvider.state);
            }
          } catch (e) {
            _blockNavigationForSuperAppLogin = false;
            AppLogger.error('Authentication failed: $e');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.go('/telebirr');
            });
            return;
          }
        }
      }
    }
  }

  void _onUpdateStateChanged() {
    if (!mounted) return;
    _handleUpdateState(_updateProvider.state);
  }

  void _handleUpdateState(UpdateState state) {
    if (!_hasTriggeredUpdateCheck) {
      return;
    }

    if (_blockNavigationForSuperAppLogin) {
      return;
    }

    if (state is UpdateChecking) {
      return;
    }

    if (state is UpdateError && _shownErrorMessage != state.message) {
      _shownErrorMessage = state.message;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text(state.message)),
        // );
      });
    }

    _scheduleNavigationIfNeeded();
  }

  void _scheduleNavigationIfNeeded() {
    if (_hasScheduledNavigation) {
      return;
    }

    _hasScheduledNavigation = true;
    _timer = Timer(const Duration(seconds: 2), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;

    if (dataController.retrieveData<bool>('isLoggedIn') == true) {
      _go('/home', fallback: const HomeScreen());
      return;
    }

    if (dataController.retrieveData<bool>('isFirstTime') == false) {
      _go('/login', fallback: const LoginScreenWithPin(phoneNumber: ''));
      return;
    }

    _go('/language', fallback: const LanguageSelection());
  }

  void _go(String location, {required Widget fallback}) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      context.go(location);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => fallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    final updateState = context.watch<UpdateProvider>().state;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splash.png',
              width: 210.w,
              height: 210.h,
            ),
            SizedBox(height: 25.h),
            Text(
              textScaleFactor: 1.0,
              'Hello Equb',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.deepForestGreen,
              ),
            ),
            if (updateState is UpdateChecking) ...[
              SizedBox(height: 18.h),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
