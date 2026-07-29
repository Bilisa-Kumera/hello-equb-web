import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/style_constants.dart';

class SuperAppEntryPage extends StatelessWidget {
  const SuperAppEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 420.w),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/splash.png',
                    width: 130.w,
                    height: 130.w,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 84.sp,
                      color: AppColors.deepForestGreen,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    'Hello Equb',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.poppins70024
                        .copyWith(color: AppColors.deepForestGreen),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Choose how you want to continue.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 28.h),
                  _EntryButton(
                    label: 'Continue with Telebirr',
                    icon: Icons.account_balance_wallet_rounded,
                    onPressed: () => context.go('/telebirr'),
                  ),
                  SizedBox(height: 12.h),
                  _EntryButton(
                    label: 'Continue with CBEBirr Plus',
                    icon: Icons.account_balance_rounded,
                    onPressed: () => context.go('/cbebirr-plus'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryButton extends StatelessWidget {
  const _EntryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20.sp),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.buttonMedium,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepForestGreen,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}
