// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/logic/check_network.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/otp_verification_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_progress_screen.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController inputController = TextEditingController();
  final Dio _dio = Dio();
  final FocusNode _inputFocusNode = FocusNode();

  bool showError = false;
  String errorMessage = '';
  bool progress = false;
  bool _isFieldFocused = false;

  late Connectivity _connectivity;
  late List<ConnectivityResult> _connectionStatus;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _checkNetworkStatus();
    _connectivity.onConnectivityChanged.listen((_) {
      setState(() {});
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();

    _inputFocusNode.addListener(() {
      setState(() {
        _isFieldFocused = _inputFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _inputFocusNode.dispose();
    inputController.dispose();
    super.dispose();
  }

  void _checkNetworkStatus() async {
    _connectionStatus = await _connectivity.checkConnectivity();
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      _showNetworkCheckScreen();
    }
  }

  void _showNetworkCheckScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: CheckNetwork(onRetry: _retryConnection),
        );
      },
    );
  }

  void _retryConnection() {
    _checkNetworkStatus();
    Navigator.of(context).pop();
  }

  void stopProgressAfterDelay() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          progress = false;
        });
      }
    });
  }

  bool isValidEmail(String input) {
    return EmailValidator.validate(input);
  }

  bool isValidPhone(String input) {
    final RegExp phoneRegex = RegExp(r'^(?:\+2519\d{8}|09\d{8}|96\d{7})$');
    return phoneRegex.hasMatch(input);
  }

  String formatPhoneNumber(String input) {
    if (input.startsWith('+2519')) {
      return input;
    } else if (input.startsWith('09')) {
      return '+251${input.substring(1)}';
    } else if (input.startsWith('96')) {
      return '+251$input';
    } else {
      return input;
    }
  }
Future<void> _sendOtpRequest(BuildContext context, String to) async {
  setState(() {
    showError = false;
    errorMessage = '';
  });

 

  try {
    final data = {'to': to};
   

    final response = await _dio.post(sendOtpUrl, data: data);
    if (kDebugMode) {
    }

    

    if (response.statusCode == 200) {

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            code: response.data['code'] ?? '',
            isForget: false,
            phoneNumber: data['to']!,
          ),
        ),
      );
    } else {

      Navigator.pop(context);
      setState(() {
        showError = true;
        errorMessage = 'Failed to send OTP. Please try again.';
      });
    }
  } on DioError catch (e) {
  

    Navigator.pop(context);

    if (e.response?.statusCode == 400) {
      if (e.response?.data['message'] == 'Phone number exists.') {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreenWithPin(phoneNumber: to),
          ),
        );
      }

      setState(() {
        showError = true;
        errorMessage = e.response?.data['message'] ??
            AppKeys.invalidCredentials.tr(context);
      });
    } else {

      setState(() {
        showError = true;
        errorMessage = AppKeys.errorTryAgain.tr(context);
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 28.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 60.h),
                        Center(
                          child: Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.primary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18.r),
                              child: Image.asset(
                                'assets/splash.png',
                                height: 40.sp,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32.h),
                        Center(
                          child: Text(
                            AppKeys.welcomeToHello.tr(context),
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black87,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Center(
                          child: Text(
                            AppKeys.loginToContinue.tr(context),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.grey600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                        // Input Field Label
                        Text(
                          AppKeys.enterPhoneEmail.tr(context),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.grey800,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Enhanced TextField
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: _isFieldFocused
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.primary.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: AppColors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: TextFormField(
                            controller: inputController,
                            focusNode: _inputFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppColors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                margin: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: _isFieldFocused
                                      ? AppColors.primary.withOpacity(0.1)
                                      : AppColors.grey100,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.person_outline,
                                  color: _isFieldFocused
                                      ? AppColors.primary
                                      : AppColors.grey600,
                                  size: 20.sp,
                                ),
                              ),
                              hintText: AppKeys.pleaseEnterEmail.tr(context),
                              hintStyle: TextStyle(
                                color: AppColors.grey400,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w400,
                              ),
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 18.h,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide(
                                  color: AppColors.red.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Error Message
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height:
                              (showError || errorMessage.isNotEmpty) ? 50.h : 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity:
                                (showError || errorMessage.isNotEmpty) ? 1 : 0,
                            child: Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.red,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      errorMessage.isNotEmpty
                                          ? errorMessage
                                          : AppKeys.invalidCredentials
                                              .tr(context),
                                      style: TextStyle(
                                        color: AppColors.red,
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16.r),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.8),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: () {
                                final input = inputController.text.trim();
                                if (input.isEmpty) {
                                  setState(() {
                                    showError = true;
                                    errorMessage =
                                        AppKeys.pleaseEnterEmail.tr(context);
                                  });
                                  return;
                                }
                                if (isValidEmail(input)) {
                                  setState(() => progress = true);
                                  stopProgressAfterDelay();
                                  showDialog(
                                    context: context,
                                    builder: (_) => const WaitingProgressPage(),
                                  );
                                  _sendOtpRequest(context, input);
                                } else if (isValidPhone(input)) {
                                  final formattedPhone =
                                      formatPhoneNumber(input);
                                  setState(() => progress = true);
                                  stopProgressAfterDelay();
                                  showDialog(
                                    context: context,
                                    builder: (_) => const WaitingProgressPage(),
                                  );
                                  _sendOtpRequest(context, formattedPhone);
                                } else {
                                  setState(() {
                                    showError = true;
                                    errorMessage = AppKeys
                                        .pleaseEnterPhoneNumber
                                        .tr(context);
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: Center(
                                  child: Text(
                                    AppKeys.sendCode.tr(context),
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.grey200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppKeys.alreadyHaveAccount.tr(context),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.grey600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LoginScreenWithPin(
                                        phoneNumber: '',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    AppKeys.login.tr(context),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
