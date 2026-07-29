import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';

import 'style_constants.dart';

class CustomSnackBar {
  static void show(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(
        textScaleFactor: 1.0,
        message,
        style: AppTextStyles.onPrimary,
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
