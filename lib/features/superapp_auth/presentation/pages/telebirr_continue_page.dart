import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/logging/app_logger.dart';
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

class TelebirrContinuePage extends StatelessWidget {
  const TelebirrContinuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cfg = SuperAppAuthConfig.fromEnv();
    final apiBase = cfg.apiBaseUrlOverride ?? '$baseUrl/';

    final repo = SuperAppAuthRepositoryImpl(
      apiBaseUrl: apiBase,
      tokenExchangePath: cfg.tokenExchangePath,
      profilePath: cfg.profilePath,
    );

    return BlocProvider(
      create: (_) => SuperAppAuthBloc(
        attemptAutoLogin: AttemptSuperAppAutoLogin(repo),
        isSuperAppAvailable: () => repo.isSuperAppAvailable,
      ),
      child: _TelebirrContinueView(cfg: cfg),
    );
  }
}

class _TelebirrContinueView extends StatelessWidget {
  const _TelebirrContinueView({required this.cfg});

  final SuperAppAuthConfig cfg;

  @override
  Widget build(BuildContext context) {
    final bridgeAvailable = createSuperAppBridge().isAvailable;
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
        final notInSuperApp = !bridgeAvailable || state is SuperAppAuthNotInSuperApp;
        final statusText = state.runtimeType.toString();

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
                    Image.asset(
                      'assets/telebirr.png',
                      width: 110.w,
                      height: 110.w,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_balance_wallet,
                        size: 90.sp,
                        color: AppColors.deepForestGreen,
                      ),
                    ),
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
                      notInSuperApp
                          ? 'This page only works inside the Telebirr SuperApp.'
                          : 'If you opened this app inside the Telebirr SuperApp, you can sign in automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(height: 16.h),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Auth status: $statusText',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
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
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isLoading || notInSuperApp)
                            ? null
                            : () {
                                context.read<SuperAppAuthBloc>().add(
                                      SuperAppAuthStarted(
                                        merchantAppId: cfg.merchantAppId,
                                      ),
                                    );
                              },
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
                              : const Text('Continue'),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (notInSuperApp)
                      Text(
                        'You are not on the SuperApp.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.red.shade700,
                        ),
                      ),
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
}
