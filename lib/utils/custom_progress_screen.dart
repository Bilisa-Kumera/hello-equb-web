import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class WaitingProgressPage extends StatelessWidget {
  const WaitingProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.black.withOpacity(0.2), // Semi-transparent black background

      body: Center(
        child: LoadingAnimationWidget.threeRotatingDots(
          color: AppColors.vibrantGreen,
          size: 30,
        ),
      ),
    );
  }
}
