import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/colors_constant.dart';

import 'style_constants.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavBarItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              left: _calculatePillPosition(context),
              top: 5.h,
              child: Container(
                width:
                    (MediaQuery.of(context).size.width - 60.w) / items.length -
                        10.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color:
                              isSelected ? AppColors.primary : AppColors.black,
                          size: 24.sp,
                        ),
                        if (!isSelected) SizedBox(height: 2.h),
                        if (!isSelected)
                          Text(
                            item.label,
                            style: AppTextStyles.navLabel
                                .copyWith(color: AppColors.black),
                          ),
                        if (isSelected)
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Container(
                              width: 4.w,
                              height: 4.w,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePillPosition(BuildContext context) {
    final totalWidth = MediaQuery.of(context).size.width - 60.w;
    final itemWidth = totalWidth / items.length;
    return (currentIndex * itemWidth) + 5.w;
  }
}

class FloatingNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
