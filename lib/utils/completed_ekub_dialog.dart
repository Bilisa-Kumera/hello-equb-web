import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';

import 'style_constants.dart';

class ModernDialog {
  static void showEqubCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  AppColors.mediumGrayCool,
                  AppColors.mediumDarkGray,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.celebration,
                  color: AppColors.white,
                  size: 50,
                ),
                const SizedBox(height: 15),
                Text(
                  "Equb Completed",
                  style: AppTextStyles.dialogTitle
                      .copyWith(color: AppColors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Please try to join another running Equbs.",
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.white60),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "N/A",
                      style: AppTextStyles.buttonLarge
                          .copyWith(color: AppColors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
