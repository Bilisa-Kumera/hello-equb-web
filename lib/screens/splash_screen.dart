import 'dart:async';
import 'package:helloequb/features/app_update/presentation/providers/update_provider.dart';
import 'package:helloequb/features/app_update/presentation/providers/update_state.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/main_navigation_screen.dart';
import 'package:helloequb/screens/language_screen.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/telebirr/telebirr.dart';
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
      final cbeBirrPlusBridge = createCbeBirrPlusBridge();
      final telebirrDetector = createTelebirrMiniAppDetector();
      AppLogger.log('App started (web)');

      final telebirrDetected = await _waitForTelebirrMiniApp(
        telebirrDetector,
      );
      if (telebirrDetected) {
        AppLogger.success('Telebirr mini app detected first');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _hasScheduledNavigation = true;
          context.go('/telebirr');
        });
        return;
      }

      // Prefer CBEBirr Plus when its channel is available.
      final cbeOk = await cbeBirrPlusBridge.waitUntilAvailable(
        timeout: const Duration(seconds: 4),
        pollInterval: const Duration(milliseconds: 140),
      );

      if (cbeOk) {
        AppLogger.success('CBEBirr Plus channel detected');
        dataController.storeData('isCbeBirr', true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _hasScheduledNavigation = true;
          // Navigate to home if logged in, otherwise to login
          if (dataController.retrieveData<bool>('isLoggedIn') == true) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        });
        return;
      }

      // Some SuperApp webviews inject the bridge after Flutter starts rendering.
      final ok = await bridge.waitUntilAvailable(
        timeout: const Duration(seconds: 12),
        pollInterval: const Duration(milliseconds: 140),
      );

      if (!ok) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _hasScheduledNavigation = true;
          AppLogger.log('No SuperApp bridge detected; redirecting to login');
          context.go('/login');
        });
        return;
      }

      AppLogger.success('Telebirr bridge detected');
      if (dataController.retrieveData<bool>('isLoggedIn') != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _hasScheduledNavigation = true;
          context.go('/telebirr');
        });
        return;
      }
    }
  }

  Future<bool> _waitForTelebirrMiniApp(
    TelebirrMiniAppDetector detector,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(deadline)) {
      if (detector.isTelebirrMiniApp()) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return detector.isTelebirrMiniApp();
  }

  void _onUpdateStateChanged() {
    if (!mounted) return;
    _handleUpdateState(_updateProvider.state);
  }

  void _handleUpdateState(UpdateState state) {
    if (!_hasTriggeredUpdateCheck) {
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
      _go('/home', fallback: const MainNavigationScreen());
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
              style: AppTextStyles.splashTitle
                  .copyWith(color: AppColors.deepForestGreen),
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
