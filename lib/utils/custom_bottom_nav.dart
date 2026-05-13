import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:ekubee/utils/colors_constant.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.all(0),
      child: Container(
        height: 80.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.freshGreen,
              AppColors.darkVibrantGreen // Darker green (top)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: const BorderRadius.only(topLeft:  Radius.circular(10.0), topRight: Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.15),
              spreadRadius: 5,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(30.0)),
          child: BottomNavigationBar(
            items: [
               BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.home,
                    color: currentIndex == 0
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.5),
                    size: currentIndex == 0 ? 30.0 : 24.0,
                  ),
                ),
                label: AppKeys.home.tr(context),
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chair_outlined,
                    color: currentIndex == 1
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.5),
                    size: currentIndex == 1 ? 30.0 : 24.0,
                  ),
                ),
                label: AppKeys.myEkub.tr(context),
              ),
             
               BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.payment,
                    color: currentIndex == 2
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.5),
                    size: currentIndex == 2 ? 30.0 : 24.0,
                  ),
                ),
                label: AppKeys.payment.tr(context),
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.person_2_outlined,
                    color: currentIndex == 3
                        ? AppColors.white
                        : AppColors.white.withOpacity(0.5),
                    size: currentIndex == 3 ? 30.0 : 24.0,
                  ),
                ),
                label: AppKeys.account.tr(context),
              ),
            ],
            selectedItemColor: AppColors.white,
            unselectedItemColor: AppColors.white.withOpacity(0.5),
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w400,
            ),
            currentIndex: currentIndex,
            onTap: onTap,
            backgroundColor: AppColors.transparent,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
