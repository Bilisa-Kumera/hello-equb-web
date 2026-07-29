import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';

class EqubTileDetail {
  final IconData icon;
  final String label;
  final String value;
  /// Optional secondary value (e.g. Gregorian date). Shown on the right with
  /// space-between; may ellipsize. [value] is treated as the primary (Amharic).
  final String? secondaryValue;

  const EqubTileDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.secondaryValue,
  });
}

Widget buildEqubTileInfoRow({
  required IconData icon,
  required String label,
  required String value,
  String? secondaryValue,
}) {
  final secondary = secondaryValue?.trim();
  final hasSecondary = secondary != null && secondary.isNotEmpty;

  return Padding(
    padding: EdgeInsets.symmetric(vertical: 3.h),
    child: Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.primary),
        SizedBox(width: 6.w),
        if (hasSecondary) ...[
          Expanded(
            flex: 2,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMuted.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: AppTextStyles.labelSmall,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTextStyles.captionMuted.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Expanded(
            child: Row(
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMuted.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

Widget buildEqubTileStatusBadge(String status, BuildContext context) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: const Color(0xFFC9A227),
      borderRadius: BorderRadius.circular(6.r),
    ),
    child: Text(
      status.toLowerCase().tr(context),
      style: AppTextStyles.badge.copyWith(
        color: Colors.white,
        fontSize: 9.sp,
      ),
    ),
  );
}

Widget buildEqubAmountChip(String amountText) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6.r),
      border: Border.all(color: AppColors.primary.withOpacity(0.35)),
    ),
    child: Text(
      amountText,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class EqubTileCard extends StatelessWidget {
  final String title;
  final String? amountText;
  final String? badgeText;
  final List<EqubTileDetail> details;
  final Widget? topSection;
  final Widget? actionRow;
  final Widget? bottomSection;
  final bool isJoined;

  const EqubTileCard({
    super.key,
    required this.title,
    this.amountText,
    this.badgeText,
    required this.details,
    this.topSection,
    this.actionRow,
    this.bottomSection,
    this.isJoined = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: EdgeInsets.fromLTRB(
              14.w,
              14.h,
              14.w,
              14.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (topSection != null) ...[
                  topSection!,
                  SizedBox(height: 10.h),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: amountText != null && amountText!.isNotEmpty
                          ? Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: AppTextStyles.poppins60014,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                buildEqubAmountChip(amountText!),
                              ],
                            )
                          : Text(
                              title,
                              style: AppTextStyles.poppins60014,
                            ),
                    ),
                    if (badgeText != null && badgeText!.isNotEmpty) ...[
                      SizedBox(width: 6.w),
                      buildEqubTileStatusBadge(badgeText!, context),
                    ],
                  ],
                ),
                SizedBox(height: 8.h),
                ...details.map(
                  (d) => buildEqubTileInfoRow(
                    icon: d.icon,
                    label: d.label,
                    value: d.value,
                    secondaryValue: d.secondaryValue,
                  ),
                ),
                if (bottomSection != null) ...[
                  SizedBox(height: 10.h),
                  bottomSection!,
                ],
                if (actionRow != null) ...[
                  SizedBox(height: 12.h),
                  actionRow!,
                ],
              ],
            ),
          ),
          if (isJoined)
            Positioned(
              top: 12.h,
              right: -30.w,
              child: Transform.rotate(
                angle: 0.785398, // +45 degrees for top-right
                child: Container(
                  width: 100.w,
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                  color: AppColors.primary,
                  alignment: Alignment.center,
                  child: Text(
                    AppKeys.joinedBadge.tr(context),
                    style: AppTextStyles.badge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
