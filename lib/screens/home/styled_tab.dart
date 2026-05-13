import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_localizations.dart';
import '../../utils/colors_constant.dart';
import '../../utils/lang_constants.dart';

class StyledTab extends StatelessWidget {
  final String text;
  final bool isSelected;

  const StyledTab({
    Key? key,
    required this.text,
    required this.isSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28.h,
      width: 93.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white
            : const Color.fromARGB(255, 219, 225, 217),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          textScaleFactor: 1.0,
          text == "Daily"
              ? AppKeys.daily.tr(context)
              : text == "Weekly"
                  ? AppKeys.weekly.tr(context)
                  : AppKeys.monthly.tr(context),
          style: TextStyle(
            color: const Color.fromARGB(255, 10, 69, 1),
            fontWeight: FontWeight.w500,
            fontFamily: 'Urbanist',
            fontSize: 15.sp,
          ),
        ),
      ),
    );
  }
}
