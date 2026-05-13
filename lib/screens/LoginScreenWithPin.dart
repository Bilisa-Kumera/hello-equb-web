// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/logic/check_network.dart';
import 'package:ekubee/screens/forget_screen.dart';
import 'package:ekubee/screens/home_screen.dart';
import 'package:ekubee/screens/login_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:dio/dio.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:ekubee/utils/custom_progress_screen.dart';

import '../utils/secure_storage.dart';

class LoginScreenWithPin extends StatefulWidget {
  String? phoneNumber;
  LoginScreenWithPin({super.key, required this.phoneNumber});

  @override
  State<LoginScreenWithPin> createState() => _LoginScreenWithPinState();
}

class _LoginScreenWithPinState extends State<LoginScreenWithPin> {
  final Dio _dio = Dio();
  bool waiting = false;
  String errorMessage = '';
  final DataController dataController = DataController();

  TextEditingController? phoneController;
  TextEditingController pinController = TextEditingController();
  String phoneNumber = '';

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(
      text: dataController.retrieveData(deviceId ?? ''),
    );
  }

  @override
  void dispose() {
    phoneController?.dispose();
    pinController.dispose();
    super.dispose();
  }

  void registerUser(BuildContext context) async {
    if (phoneNumber.isEmpty || pinController.text.isEmpty) {
      setState(() {
        errorMessage = phoneNumber.isEmpty
            ? AppKeys.pleaseEnterPhoneNumber.tr(context)
            : AppKeys.pleaseEnterValid.tr(context);
      });
      return;
    }
    waiting = true;
    bool dialogOpen = true;
    if (!kIsWeb) {
  showDialog(
    context: context,
    builder: (_) => const WaitingProgressPage(),
  );
}
   
    Future.delayed(const Duration(seconds: 15), () {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
    });
    try {
      Response response = await _dio.post(
        loginUrl,
        data: {
          "phoneNumber": phoneNumber,
          "password": pinController.text,
        },
      );
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      if (response.statusCode == 200) {
        dataController.storeData('isLoggedIn', true);
        await SecureStorageHelper.saveUserId(response.data['user']['id']);
        await SecureStorageHelper.saveAccessToken(response.data['accessToken']);
        await SecureStorageHelper.saveRefreshToken(
            response.data['refreshToken']);
        dataController.storeData('fullName', response.data['user']['fullName']);
        dataController.storeData('userId', response.data['user']['id']);
        dataController.storeData(
            'phoneNumber', response.data['user']['phoneNumber']);
        dataController.storeData('lastName', response.data['user']['lastName']);
        dataController.storeData(
            'firstName', response.data['user']['firstName']);
        dataController.storeData('middleName', response.data['user']['middleName']);
        dataController.storeData('email', response.data['user']['email']);
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } on DioError catch (e) {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      waiting = false;
      if (e.response?.statusCode == 400) {
        if (e.response?.data['status'] == 'fail') {
          errorMessage = e.response?.data['message'];
        } else {
          errorMessage = e.response?.data['errors'][0]['msg'];
        }
        setState(() {});
        CustomSnackBar.show(context, errorMessage, AppColors.red);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreenWithPin(
              phoneNumber: widget.phoneNumber,
            ),
          ),
        );
      }
    } catch (e) {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = false;
      }
      waiting = false;
      CustomSnackBar.show(context, "Unexpected oerror ocurred", AppColors.red);
    }
  }

  late Connectivity _connectivity;
  late List<ConnectivityResult> _connectionStatus;
  String? deviceId;

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
      builder: (_) => Dialog(child: CheckNetwork(onRetry: _retryConnection)),
    );
  }

  void _retryConnection() {
    _checkNetworkStatus();
    Navigator.of(context).pop();
  }

  void _showPopup(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content,
              style: TextStyle(fontSize: 16.sp, color: AppColors.black87)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close",
                style: TextStyle(color: AppColors.primary, fontSize: 16.sp)),
          ),
        ],
      ),
    );
  }

  void _validateAndNormalize(String? value) {
    if (value == null || value.trim().isEmpty) return;

    String v = value.trim();
    String normalized = v;

    if (v.startsWith('+251') && v.length == 13) {
      normalized = v;
    } else if (v.startsWith('9') && v.length == 9) {
      normalized = '+251$v';
    } else if (v.startsWith('09') && v.length == 10) {
      normalized = '+251${v.substring(1)}';
    } else {
      normalized = v;
    }

    phoneNumber = normalized;
  }

  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlueBackground,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 30.h),
                  Center(
                      child: Image.asset('assets/splash.png', height: 230.h)),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppKeys.welcomeBack.tr(context),
                        style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlueGray),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.grayOverlay,
                        hintText: AppKeys.enterPhoneOrEmail.tr(context),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        errorStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onChanged: _validateAndNormalize,
                      validator: (value) {
                        if (phoneNumber.startsWith('+251')) {
                          return (phoneNumber.length != 13)
                              ? AppKeys.invalidPhoneOrEmail.tr(context)
                              : null;
                        } else {
                          final emailRegex = RegExp(
                              r'^[^@]+@(?:gmail\.com|somecompany\.com)$');
                          return emailRegex.hasMatch(phoneNumber)
                              ? null
                              : AppKeys.invalidPhoneOrEmail.tr(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextFormField(
                      controller: pinController,
                      obscureText: _obscureText,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.grayOverlay,
                        hintText: AppKeys.pin.tr(context),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.redAccent,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        suffixIcon: Material(
                          color: Colors.transparent,
                          child: IconButton(
                            splashRadius: 24,
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _obscureText
                                  ? Colors.grey.shade500
                                  : Theme.of(context).primaryColor,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (errorMessage.isNotEmpty)
                    Center(
                      child: Text(errorMessage,
                          style: const TextStyle(color: AppColors.red)),
                    ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgetScreen())),
                        child: Text(
                          AppKeys.forgetPassword.tr(context),
                          style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.darkTeal,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          _connectivity = Connectivity();
                          _checkNetworkStatus();
                          dataController.storeData('phoneNumber', phoneNumber);
                          registerUser(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 2,
                          textStyle: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.bold),
                          backgroundColor: Colors.transparent,
                        ).copyWith(
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                                  (states) {
                            return Colors.transparent;
                          }),
                          shadowColor:
                              MaterialStateProperty.all(Colors.transparent),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Text(
                              AppKeys.login.tr(context),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50.h),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppKeys.dontHaveAccount.tr(context),
                          style: TextStyle(
                              fontSize: 16.sp, color: AppColors.darkBlueGray),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen())),
                          child: Text(
                            AppKeys.register.tr(context),
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 24),
                  //   child: Wrap(
                  //     alignment: WrapAlignment.center,
                  //     spacing: 8.w,
                  //     runSpacing: 4.h,
                  //     children: [
                  //       Text(
                  //         AppKeys.byLoggingIn.tr(context),
                  //         style: TextStyle(
                  //             fontSize: 16.sp,
                  //             color: AppColors.lightGrayNeutral),
                  //       ),
                  //       GestureDetector(
                  //         onTap: () => _showPopup(context, "Terms of Service",
                  //             AppKeys.termsConditions.tr(context)),
                  //         child: Text(
                  //           AppKeys.termsOfService.tr(context),
                  //           style: TextStyle(
                  //               fontSize: 16.sp,
                  //               fontWeight: FontWeight.bold,
                  //               color: AppColors.black),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}