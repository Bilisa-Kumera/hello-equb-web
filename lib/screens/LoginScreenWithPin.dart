// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/logic/check_network.dart';
import 'package:ekubee/screens/forget_screen.dart';
import 'package:ekubee/screens/home_screen.dart';
import 'package:ekubee/screens/login_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:ekubee/utils/custom_progress_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';

import '../utils/secure_storage.dart';

class LoginScreenWithPin extends StatefulWidget {
  final String? phoneNumber;

  const LoginScreenWithPin({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<LoginScreenWithPin> createState() => _LoginScreenWithPinState();
}

class _LoginScreenWithPinState extends State<LoginScreenWithPin> {
  final Dio _dio = Dio();

  final DataController dataController = DataController();

  late TextEditingController phoneController;
  final TextEditingController pinController = TextEditingController();

  bool waiting = false;
  bool _obscureText = true;

  String errorMessage = '';
  String phoneNumber = '';

  late Connectivity _connectivity;
  late List<ConnectivityResult> _connectionStatus;

  @override
  void initState() {
    super.initState();

    _connectivity = Connectivity();

    phoneNumber = widget.phoneNumber ?? '';

    phoneController = TextEditingController(
      text: phoneNumber.isNotEmpty
          ? phoneNumber
          : dataController.retrieveData('phoneNumber') ?? '',
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> registerUser(BuildContext context) async {
    FocusScope.of(context).unfocus();

    _validateAndNormalize(phoneController.text);

    if (phoneNumber.isEmpty || pinController.text.trim().isEmpty) {
      setState(() {
        errorMessage = phoneNumber.isEmpty
            ? AppKeys.pleaseEnterPhoneNumber.tr(context)
            : AppKeys.pleaseEnterValid.tr(context);
      });

      return;
    }

    bool dialogOpen = false;

    try {
      setState(() {
        waiting = true;
      });

      if (!kIsWeb) {
        dialogOpen = true;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const WaitingProgressPage(),
        );
      }

      final Response response = await _dio.post(
        loginUrl,
        data: {
          "phoneNumber": phoneNumber,
          "password": pinController.text.trim(),
        },

        /// VERY IMPORTANT FOR WEB
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (kDebugMode) {
        debugPrint('Login request URL: ${response.realUri}');
      }

      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode == 200) {
        Map<String, dynamic> body;
        final dynamic raw = response.data;
        if (raw is String) {
          final trimmed = raw.trimLeft();
          if (trimmed.startsWith('<!DOCTYPE html') ||
              trimmed.startsWith('<html')) {
            throw FormatException(
              'Received HTML instead of JSON from ${response.realUri}. '
              'Your app likely called Firebase Hosting (rewrite to index.html) instead of the API. '
              'Check BASE_URL/.env and hard refresh.',
            );
          }
          body = jsonDecode(raw) as Map<String, dynamic>;
        } else if (raw is Map) {
          body = Map<String, dynamic>.from(raw as Map);
        } else {
          throw const FormatException('Unexpected login response format');
        }

        final dynamic userDynamic = body['user'] ?? body['data']?['user'];
        if (userDynamic is! Map) {
          throw const FormatException('Login response missing user');
        }
        final user = Map<String, dynamic>.from(userDynamic);

        final accessToken = body['accessToken'] ?? body['data']?['accessToken'];
        final refreshToken =
            body['refreshToken'] ?? body['data']?['refreshToken'];
        if (accessToken == null || refreshToken == null) {
          throw const FormatException('Login response missing token(s)');
        }

        dataController.storeData('isLoggedIn', true);

        await SecureStorageHelper.saveUserId(user['id'].toString());

        await SecureStorageHelper.saveAccessToken(
          accessToken.toString(),
        );

        await SecureStorageHelper.saveRefreshToken(
          refreshToken.toString(),
        );

        dataController.storeData('userId', user['id']);
        dataController.storeData('fullName', user['fullName']);
        dataController.storeData('phoneNumber', user['phoneNumber']);
        dataController.storeData('lastName', user['lastName']);
        dataController.storeData('firstName', user['firstName']);
        dataController.storeData('middleName', user['middleName']);
        dataController.storeData('email', user['email']);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } on DioError catch (e) {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      String message = "Login failed";

      if (e.type == DioErrorType.connectionError) {
        message = "Unable to connect to server";
      } else if (e.response?.statusCode == 400) {
        if (e.response?.data['status'] == 'fail') {
          message = e.response?.data['message'];
        } else {
          message = e.response?.data['errors'][0]['msg'];
        }
      } else if (e.response?.statusCode == 401) {
        message = "Invalid credentials";
      }

      setState(() {
        errorMessage = message;
      });

      if (mounted) {
        CustomSnackBar.show(context, message, AppColors.red);
      }
    } catch (e) {
      if (dialogOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (mounted) {
        CustomSnackBar.show(
          context,
          kDebugMode
              ? 'Unexpected error: $e'
              : (e is FormatException
                  ? 'Unexpected server response. Check app BASE_URL config.'
                  : "Unexpected error occurred $e"),
          AppColors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          waiting = false;
        });
      }
    }
  }

  Future<void> _checkNetworkStatus() async {
    _connectionStatus = await _connectivity.checkConnectivity();

    if (_connectionStatus.contains(ConnectivityResult.none)) {
      _showNetworkCheckScreen();
    }
  }

  void _showNetworkCheckScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: CheckNetwork(
          onRetry: _retryConnection,
        ),
      ),
    );
  }

  void _retryConnection() {
    Navigator.of(context).pop();
    _checkNetworkStatus();
  }

  void _validateAndNormalize(String? value) {
    if (value == null || value.trim().isEmpty) {
      phoneNumber = '';
      return;
    }

    final String v = value.trim();

    if (v.startsWith('+251') && v.length == 13) {
      phoneNumber = v;
    } else if (v.startsWith('9') && v.length == 9) {
      phoneNumber = '+251$v';
    } else if (v.startsWith('09') && v.length == 10) {
      phoneNumber = '+251${v.substring(1)}';
    } else {
      phoneNumber = v;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlueBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 30.h),

                  /// WEB RESPONSIVE
                  Image.asset(
                    'assets/splash.png',
                    height: kIsWeb ? 180 : 230.h,
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppKeys.welcomeBack.tr(context),
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlueGray,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: _validateAndNormalize,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.grayOverlay,
                        hintText: AppKeys.enterPhoneOrEmail.tr(context),
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextFormField(
                      controller: pinController,
                      obscureText: _obscureText,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.grayOverlay,
                        hintText: AppKeys.pin.tr(context),
                        prefixIcon: const Icon(Icons.lock_outline),

                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppColors.red,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgetScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppKeys.forgetPassword.tr(context),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.darkTeal,
                            fontWeight: FontWeight.w600,
                          ),
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
                        onPressed: waiting
                            ? null
                            : () async {
                                await _checkNetworkStatus();

                                dataController.storeData(
                                  'phoneNumber',
                                  phoneNumber,
                                );

                                registerUser(context);
                              },
                        child: waiting
                            ? const CircularProgressIndicator()
                            : Text(
                                AppKeys.login.tr(context),
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppKeys.dontHaveAccount.tr(context),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppKeys.register.tr(context),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
