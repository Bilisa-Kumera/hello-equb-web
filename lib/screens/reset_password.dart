// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';

import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/custom_progress_screen.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/custom_text_field.dart';
import 'package:dio/dio.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class ResetPassword extends StatelessWidget {
  final String otp;
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final Dio _dio = Dio();
  bool waiting = false;
  String errorMessage = "";
  // SharedPreferences? prefs;
  final DataController dataController = DataController();

  ResetPassword({super.key, required this.otp});

  Future<void> registerUser(BuildContext context) async {
    if (passwordController.text == confirmPasswordController.text) {
      try {
        // Retrieve the bearer token from the stored data

        Response response = await _dio.post(
          resetPasswordUrl,
          data: {'otp': otp, 'password': passwordController.text},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

        if (response.statusCode == 400) {
          Map<String, dynamic> responseData = json.decode(response.toString());
          errorMessage = responseData['message'];
        }

        if (response.statusCode == 200) {
          CustomSnackBar.show(
              context, "Password resetted successfully", AppColors.primary);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreenWithPin(
                phoneNumber: '',
              ),
            ),
          );
          // Successfully received OTP
          waiting = false;
        }
      } catch (e) {
        if (e is DioError && e.response != null) {
          if (e.response!.statusCode == 400) {
            CustomSnackBar.show(
                context, "Error resetting the password", AppColors.red);

            Map<String, dynamic> responseData =
                json.decode(e.response.toString());
            String errorMessage = responseData['msg'] ?? '';

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text(textScaleFactor: 1.0, 'Error'),
                content: Text(textScaleFactor: 1.0, errorMessage),
                actions: <Widget>[
                  TextButton(
                    child: const Text(textScaleFactor: 1.0, 'OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          }
        }
      }
    } else {
      waiting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.only(left: 18.0, top: 40),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(13)),
                      border:
                          Border.all(color: AppColors.lightBlueGray, width: 1)),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.black),
                    ), // Set icon color to black
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 26.0, right: 8),
              child: SizedBox(
                child: Text(
                  textScaleFactor: 1.0,
                  AppKeys.resetPassword.tr(context),
                  style: AppTextStyles.poppins70024.copyWith(color: AppColors.darkBlueGray),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 26.0, right: 8),
              child: SizedBox(
                child: Text(
                  textScaleFactor: 1.0,
                  AppKeys.yourNewPinMustBe.tr(context),
                  style: AppTextStyles.poppins50014.copyWith(color: AppColors.coolGray),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26.0, right: 26, top: 36),
              child: PasswordTextField(
                hintText: AppKeys.newPin.tr(context),
                controller: passwordController,
                borderRadius: BorderRadius.circular(8),
                height: 56,
                width: double.infinity,
                borderWidth: 0.6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 26.0, right: 26, top: 16, bottom: 20),
              child: PasswordTextField(
                hintText: AppKeys.confirmPin.tr(context),
                controller: confirmPasswordController,
                borderRadius: BorderRadius.circular(8),
                height: 56,
                width: double.infinity,
                borderWidth: 0.6,
              ),
            ),
            errorMessage != ""
                ? Text(
                    textScaleFactor: 1.0,
                    errorMessage,
                    style: AppTextStyles.poppins40014.copyWith(color: AppColors.red),
                  )
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.all(26.0),
              child: CustomTextButton(
                text: AppKeys.done.tr(context),
                onPressed: () {
                  if (passwordController.text.isNotEmpty &&
                      confirmPasswordController.text.isNotEmpty) {
                    waiting = true;

                    waiting
                        ? showDialog(
                            context: context,
                            builder: (context) => const WaitingProgressPage())
                        : null;
                    registerUser(context);
                  }
                },
                textColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
