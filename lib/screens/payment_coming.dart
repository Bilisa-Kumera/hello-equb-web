import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_bottom_outlined,
              size: 100,
              color: AppColors.primary, // Icon color
            ),
            const SizedBox(height: 20),
            Text(
              textScaleFactor: 1.0,
              'Coming Soon',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.blueGrey,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                textScaleFactor: 1.0,
                'We are working to add this functionality, Stay tuned!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
