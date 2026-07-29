import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/lang_constants.dart';

import 'style_constants.dart';

class LotteryDetailBottomSheet extends StatelessWidget {
  final String lottery;
  final int round;

  const LotteryDetailBottomSheet({
    super.key,
    required this.lottery,
    required this.round,
  });

  static Future<void> show(
    BuildContext context, {
    required String lottery,
    required int round,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LotteryDetailBottomSheet(
        lottery: lottery,
        round: round,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppKeys.lotteryNumber.tr(context),
                      style: AppTextStyles.sectionTitleLarge.copyWith(
                        fontSize: 18.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade600,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.18),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      lottery,
                      style: AppTextStyles.poppins70028.copyWith(
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      AppKeys.lottery.tr(context),
                      style: AppTextStyles.poppins50013.copyWith(
                        color: Colors.grey.shade600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              _DetailRow(
                icon: Icons.receipt_long_outlined,
                label: AppKeys.lastPaidRound.tr(context),
                value: '$round',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.poppins40014.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.poppins60016.copyWith(
              color: const Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}
