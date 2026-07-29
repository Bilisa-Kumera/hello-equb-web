import 'package:helloequb/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';

class ReferralCard extends StatelessWidget {
  final String referralCode;
  final String title;
  final Color primaryColor;
  final String shareText;

  const ReferralCard({
    super.key,
    required this.referralCode,
    required this.title,
    required this.primaryColor,
    required this.shareText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: primaryColor,
      ),
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.poppins60014.copyWith(color: Colors.white),
          ),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.poppins60014.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(AppKeys.referralCodeCopied.tr(context)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.copy_rounded, color: Colors.white, size: 18.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Share.share(
                  "$shareText$referralCode Download the app here: https://play.google.com/store/apps/details?id=com.hello.equb",
                );
              },
              icon: Icon(Icons.share_rounded, size: 16.sp),
              label: Text(
                AppKeys.shareAndInvite.tr(context),
                style: AppTextStyles.button.copyWith(color: primaryColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
