// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/logic/check_network.dart';
import 'package:helloequb/screens/forget_screen.dart';
import 'package:helloequb/utils/main_nav_helper.dart';
import 'package:helloequb/screens/login_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/custom_progress_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:email_validator/email_validator.dart';
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
  final TextEditingController emailController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  bool waiting = false;
  bool _obscureText = true;
  bool _isPhoneTabActive = true;

  String errorMessage = '';
  String phoneNumber = '';

  late Connectivity _connectivity;
  late List<ConnectivityResult> _connectionStatus;

  @override
  void initState() {
    super.initState();

    _connectivity = Connectivity();

    phoneNumber = widget.phoneNumber ?? '';

    final initialValue = phoneNumber.isNotEmpty
        ? phoneNumber
        : dataController.retrieveData('phoneNumber')?.toString() ?? '';

    phoneController = TextEditingController();
    if (initialValue.contains('@')) {
      _isPhoneTabActive = false;
      emailController.text = initialValue;
    } else {
      phoneController.text = initialValue;
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    pinController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _switchInputTab(bool isPhoneTab) {
    if (_isPhoneTabActive == isPhoneTab) return;
    _phoneFocusNode.unfocus();
    _emailFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _isPhoneTabActive = isPhoneTab;
      errorMessage = '';
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      if (isPhoneTab) {
        _phoneFocusNode.requestFocus();
      } else {
        _emailFocusNode.requestFocus();
      }
    });
  }

  Future<void> registerUser(BuildContext context) async {
    FocusScope.of(context).unfocus();

    if (_isPhoneTabActive) {
      _validateAndNormalize(phoneController.text);
      if (phoneNumber.isEmpty) {
        setState(() {
          errorMessage = AppKeys.pleaseEnterPhoneNumber.tr(context);
        });
        return;
      }
    } else {
      final email = emailController.text.trim();
      if (!EmailValidator.validate(email)) {
        setState(() {
          phoneNumber = '';
          errorMessage = AppKeys.pleaseEnterEmail.tr(context);
        });
        return;
      }
      phoneNumber = email;
    }

    if (pinController.text.trim().isEmpty) {
      setState(() {
        errorMessage = AppKeys.pleaseEnterValid.tr(context);
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

        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );

      if (kDebugMode) {
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

        await navigateToMainShell(context);
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
                        style: AppTextStyles.screenTitleLarge.copyWith(
                          color: AppColors.darkBlueGray,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInputTypeTab(
                              label: AppKeys.phoneNumber.tr(context),
                              isSelected: _isPhoneTabActive,
                              onTap: () => _switchInputTab(true),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _buildInputTypeTab(
                              label: AppKeys.email.tr(context),
                              isSelected: !_isPhoneTabActive,
                              onTap: () => _switchInputTab(false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _isPhoneTabActive
                        ? TextFormField(
                            controller: phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            onChanged: _validateAndNormalize,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.grayOverlay,
                              hintText:
                                  AppKeys.pleaseEnterPhoneNumber.tr(context),
                              prefixIcon: const Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          )
                        : TextFormField(
                            controller: emailController,
                            focusNode: _emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.grayOverlay,
                              hintText: AppKeys.pleaseEnterEmail.tr(context),
                              prefixIcon: const Icon(Icons.email_outlined),
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
                      style: AppTextStyles.error.copyWith(color: AppColors.red),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                AppKeys.login.tr(context),
                                style: AppTextStyles.onPrimaryBold.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgetScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppKeys.forgetPassword.tr(context),
                          style: AppTextStyles.poppins60014.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 28.h),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      AppKeys.dontHaveAccount.tr(context),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.poppins50014.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.12),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppKeys.register.tr(context),
                          style: AppTextStyles.poppins60015.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
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

  Widget _buildInputTypeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.poppins60014.copyWith(
                color: isSelected ? AppColors.white : AppColors.grey700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
