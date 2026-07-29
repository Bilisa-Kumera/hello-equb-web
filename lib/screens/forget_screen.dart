// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/main.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/otp_verification_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/custom_progress_screen.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';

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
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black),
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
                style: AppTextStyles.poppins70032.copyWith(color: AppColors.darkBlueGray),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 26.0, right: 8),
              child: Text(
                textScaleFactor: 1.0,
                AppKeys.dontWorry.tr(context),
                style: AppTextStyles.poppins50016.copyWith(color: AppColors.coolGray),
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
            SizedBox(height: 24.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Text(
                AppKeys.rememberPassword.tr(context),
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins50014.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreenWithPin(
                          phoneNumber: contactController.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    AppKeys.login.tr(context),
                    style: AppTextStyles.poppins60015.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
