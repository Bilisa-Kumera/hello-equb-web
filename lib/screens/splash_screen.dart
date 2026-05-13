import 'dart:async';
import 'package:ekubee/features/app_update/presentation/providers/update_provider.dart';
import 'package:ekubee/features/app_update/presentation/providers/update_state.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/screens/LoginScreenWithPin.dart';
import 'package:ekubee/screens/home_screen.dart';
import 'package:ekubee/screens/language_screen.dart';
import 'package:provider/provider.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';

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
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      return;
    }

    if (dataController.retrieveData<bool>('isFirstTime') == false) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreenWithPin(
            phoneNumber: '',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LanguageSelection()),
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
