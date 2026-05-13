// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/main.dart';
import 'package:ekubee/screens/LoginScreenWithPin.dart';
import 'package:ekubee/screens/otp_verification_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/custom_progress_screen.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';

class ForgetScreen extends StatefulWidget {
  const ForgetScreen({super.key});

  @override
  State<ForgetScreen> createState() => _ForgetScreenState();
}

class _ForgetScreenState extends State<ForgetScreen> {
  final TextEditingController contactController = TextEditingController();
  final Dio dio = Dio();
  final DataController dataController = DataController();

  String? _parseContact(String input) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    final phoneRegex = RegExp(r'^0?9\d{8}$');

    if (emailRegex.hasMatch(input)) {
      return input;
    } else if (phoneRegex.hasMatch(input)) {
      if (input.startsWith('0')) {
        input = input.substring(1); // remove leading zero
      }
      return '+251$input';
    }
    return null;
  }

  Future<void> submit(BuildContext context, String phoneOrEmail) async {
    showDialog(
      context: context,
      builder: (context) => const WaitingProgressPage(),
    );

    try {
      final response = await dio.post(
        forgetPasswordUrl,
        data: {"phoneNumber": phoneOrEmail},
        options: Options(headers: {
          "Content-Type": "application/json",
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              code: response.data['otp'],
              phoneNumber: phoneOrEmail,
              isForget: true,
            ),
          ),
        );
      } else {
        CustomSnackBar.show(context, "Something went wrong", AppColors.red);
      }
    } catch (error) {
      Navigator.pop(context);
      CustomSnackBar.show(
          context, AppKeys.seemsLikeNoAccount.tr(context), AppColors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18.0, top: 40),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border:
                        Border.all(color: AppColors.lightBlueGray, width: 1),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.arrow_back_ios, color: AppColors.black),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 26.0, right: 8),
              child: Text(
                textScaleFactor: 1.0,
                AppKeys.forgetPassword.tr(context),
                style: TextStyle(
                    color: AppColors.darkBlueGray,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                    fontSize: 30.sp),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 26.0, right: 8),
              child: Text(
                textScaleFactor: 1.0,
                AppKeys.dontWorry.tr(context),
                style: TextStyle(
                    color: AppColors.coolGray,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Urbanist',
                    fontSize: 16.sp),
              ),
            ),
            SizedBox(height: 20.h),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: contactController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.grayOverlay,
                    hintText: AppKeys.phoneOrEmail.tr(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(26.0),
              child: CustomTextButton(
                text: AppKeys.sendCode.tr(context),
                onPressed: () {
                  final input = contactController.text.trim();
                  final parsed = _parseContact(input);
                  if (parsed != null) {
                    submit(context, parsed);
                  } else {
                    CustomSnackBar.show(
                      context,
                      AppKeys.invalidPhoneOrEmail.tr(context),
                      AppColors.red,
                    );
                  }
                },
                textColor: AppColors.white,
              ),
            ),
            SizedBox(height: 240.h),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppKeys.rememberPassword.tr(context),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.darkBlueGray,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LoginScreenWithPin(phoneNumber: ''),
                          ),
                        );
                      },
                      child: Text(
                        AppKeys.login.tr(context),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
