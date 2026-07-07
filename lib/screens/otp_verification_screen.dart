// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/reset_password.dart';
import 'package:helloequb/screens/signup_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/custom_progress_screen.dart';
import 'package:helloequb/utils/lang_constants.dart';

class OtpVerificationScreen extends StatefulWidget {
  String code;
  final String phoneNumber;
  final bool isForget;

  OtpVerificationScreen({
    super.key,
    required this.code,
    required this.phoneNumber,
    required this.isForget,
  });

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otpCode = '';
  bool showError = false;
  bool isCountingDown = false;
  int countdown = 20;
  Timer? timer;
  final Dio dio = Dio();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void startCountdown() {
    setState(() {
      isCountingDown = true;
      countdown = 20;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });
      if (countdown == 0) {
        timer.cancel();
        setState(() {
          isCountingDown = false;
        });
      }
    });
  }

  Future<void> submit(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const WaitingProgressPage(),
    );

    try {
      final response = await dio.post(
        forgetPasswordUrl,
        data: {"phoneNumber": widget.phoneNumber},
        options: Options(
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );
      Navigator.pop(context);

      if (response.statusCode == 200) {
        widget.code = response.data['otp'];
        startCountdown();
      }
    } catch (error) {
      Navigator.pop(context);
    }
  }

  void _verifyOtp() {
    if (_otpCode == widget.code && !widget.isForget) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SignUpScreen(phoneNumber: widget.phoneNumber)),
      );
    } else if (widget.isForget && _otpCode == widget.code) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResetPassword(otp: _otpCode)),
      );
    } else {
      setState(() {
        showError = true;
      });
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
              padding: const EdgeInsets.only(top: 20, left: 26.0, right: 8),
              child: Text(
                textScaleFactor: 1.0,
                AppKeys.otpVerification.tr(context),
                style: TextStyle(
                  color: AppColors.darkBlueGray,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                  fontSize: 24.sp,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 26.0, right: 8),
              child: Text(
                textScaleFactor: 1.0,
                AppKeys.enterVerificationCode.tr(context),
                style: TextStyle(
                  color: AppColors.coolGray,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Urbanist',
                  fontSize: 15.sp,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 26.0, right: 26, top: 26, bottom: 20),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, color: AppColors.black),
                decoration: const InputDecoration(
                  counterText: "", // Hide counter
                  border: UnderlineInputBorder(),
                  hintText: "Enter OTP",
                ),
                autofillHints: [], // Prevent autofill
                onChanged: (value) {
                  setState(() {
                    _otpCode = value;
                  });
                },
              ),
            ),
            if (showError)
              const Center(
                child: Text(
                  textScaleFactor: 1.0,
                  'Incorrect OTP, please try again.',
                  style:
                      TextStyle(color: AppColors.red, fontFamily: 'Urbanist'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(26.0),
              child: CustomTextButton(
                text: AppKeys.verify.tr(context),
                onPressed: _verifyOtp,
                textColor: AppColors.white,
              ),
            ),
            const SizedBox(height: 225),
            Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 26.0),
                    child: Text(
                      textScaleFactor: 1.0,
                      AppKeys.didntReceiveCode.tr(context),
                      style: TextStyle(
                        color: AppColors.darkBlueGray,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Urbanist',
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10, left: 8, right: 26),
                    child: InkWell(
                      onTap: isCountingDown ? null : () => submit(context),
                      child: Text(
                        isCountingDown
                            ? '$countdown seconds'
                            : AppKeys.resend.tr(context),
                        textScaleFactor: 1.0,
                        style: const TextStyle(
                          color: AppColors.darkBlueGray,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Urbanist',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
