import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.white, // Background color
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon(Icons.tiktok), // TikTok logo or any other loading animation
              const SizedBox(height: 20),
              SpinKitFadingCube(
                color: AppColors.primary,
                size: 20.0,
                controller: AnimationController(
                    vsync: this, duration: const Duration(milliseconds: 2200)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
