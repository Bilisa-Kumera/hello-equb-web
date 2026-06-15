import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/utils/colors_constant.dart';

class CbeBirrPlusContinuePage extends StatefulWidget {
  const CbeBirrPlusContinuePage({super.key});

  @override
  State<CbeBirrPlusContinuePage> createState() =>
      _CbeBirrPlusContinuePageState();
}

class _CbeBirrPlusContinuePageState extends State<CbeBirrPlusContinuePage> {
  late final CbeBirrPlusBridge _bridge;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _bridge = createCbeBirrPlusBridge();
    _checkBridge();
  }

  Future<void> _checkBridge() async {
    final ok = await _bridge.waitUntilAvailable(
      timeout: const Duration(seconds: 6),
      pollInterval: const Duration(milliseconds: 140),
    );

    if (!mounted) return;

    if (!ok) {
      AppLogger.warn('CBEBirr Plus continue page opened without bridge');
      context.go('/not-superapp');
      return;
    }

    final hasLaunchToken = _bridge.launchToken != null;
    AppLogger.success(
      'CBEBirr Plus continue page ready (launchToken=$hasLaunchToken)',
    );
    setState(() => _checking = false);
  }

  void _continueToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: AppColors.deepForestGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      size: 42,
                      color: AppColors.deepForestGreen,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'CBEBirr Plus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.deepForestGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Continue to Hello Equb using your CBEBirr Plus session.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.35),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _checking ? null : _continueToLogin,
                      icon: _checking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Continue with CBEBirr Plus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepForestGreen,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor:
                            AppColors.deepForestGreen.withOpacity(0.35),
                        disabledForegroundColor: AppColors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
