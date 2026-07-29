import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';

import 'style_constants.dart';

class CustomTextButton extends StatelessWidget {
  final String text;
  final void Function() onPressed;
  final Color buttonColor;
  final Color textColor;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    // this.buttonColor = const AppColors.vibrantGreen,
    this.buttonColor = AppColors.darkMutedGreen,
    this.textColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      width: double.maxFinite,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: buttonColor,
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          textScaleFactor: 1.0,
          text,
          style: AppTextStyles.poppins60015.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class CustomLogoutButton extends StatelessWidget {
  final String text;
  final void Function() onPressed;
  final Color buttonColor;
  final Color textColor;

  const CustomLogoutButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.buttonColor = AppColors.crimsonRed ,
    this.textColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 49,
      width: double.maxFinite,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: buttonColor,
          elevation: 5,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          textScaleFactor: 1.0,
          text,
          style: AppTextStyles.poppins60015.copyWith(color: textColor),
        ),
      ),
    );
  }
}
