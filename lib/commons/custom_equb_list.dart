import 'package:dots_indicator/dots_indicator.dart';
import 'package:ekubee/provider/equb_category_provider.dart';
import 'package:ekubee/provider/equb_type_provider.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/equb_model.dart';
import 'package:provider/provider.dart';

class CustomEqubList extends StatelessWidget {
  final List<EqubModel> equbs;
  final List<EqubType> equbTypes;
  final void Function(EqubModel equb) onJoin;
  final int currentEqubTypeIndex;
  final int currentCategoryIndex;
  final void Function(int newIndex, int max) onCategoryIndexChanged;
  final void Function(int index) onPageChanged;

  const CustomEqubList({
    super.key,
    required this.equbs,
    required this.onJoin,
    required this.currentEqubTypeIndex,
    required this.onPageChanged,
    required this.equbTypes,
    required this.currentCategoryIndex,
    required this.onCategoryIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EqubCategoryProvider>(
      builder: (context, equbCategoryProvider, _) {
        final equbCategories = equbCategoryProvider.equbCategories;
        if (equbCategories?.isEmpty ?? true) {
          return const Center(child: Text('No categories available'));
        }

        return Container(
          margin: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(12.r),
              ),
              border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.15))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 14.h,
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Text(
                    textScaleFactor: 1.0,
                    AppKeys.seeAll.tr(context),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightNeutralGray,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28.w,
                    height: 28.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color.fromARGB(80, 202, 202, 202),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          onCategoryIndexChanged(currentCategoryIndex - 1,
                              equbCategories?.length ?? 0);
                        },
                        icon: Icon(
                          Icons.keyboard_double_arrow_left_outlined,
                          size: currentCategoryIndex != 0 ? 24.sp : 20.sp,
                          color: currentCategoryIndex != 0
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Text(
                    equbCategories?[currentCategoryIndex].name ?? 'N/A',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 20.w),
                  Container(
                    width: 28.w,
                    height: 28.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color.fromARGB(80, 202, 202, 202),
                        width: 0.8,
                      ),
                    ),
                    child: Center(
                      child: IconButton(
                        onPressed: () {
                          onCategoryIndexChanged(currentCategoryIndex + 1,
                              equbCategories?.length ?? 0);
                        },
                        icon: Icon(
                          Icons.keyboard_double_arrow_right_outlined,
                          size: (equbCategories != null &&
                                  currentCategoryIndex <
                                      (equbCategories.length - 1))
                              ? 24.sp
                              : 20.sp,
                          color: (equbCategories != null &&
                                  currentCategoryIndex <
                                      (equbCategories.length - 1))
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 4.h,
              ),
              DotsIndicator(
                dotsCount: equbCategories?.length ?? 0,
                position: currentCategoryIndex.toDouble(),
                decorator: DotsDecorator(
                  activeColor: AppColors.primary,
                  size: Size(6.w, 6.w),
                  activeSize: Size(10.w, 6.w),
                  spacing: EdgeInsets.symmetric(horizontal: 2.w),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: equbs.length,
                itemBuilder: (context, index) {
                  
                  final equb = equbs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        // boxShadow: [
                        //   // BoxShadow(
                        //   //   color: Colors.black.withOpacity(0.08),
                        //   //   blurRadius: 8,
                        //   //   offset: const Offset(0, 2),
                        //   // ),
                        // ],
                      ),
                      child: Row(
                        children: [
                          // Left blue bar
                          Container(
                            width: 28.w,
                            height: 126.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                          ),
                          // Image
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/car.png',
                                width: 80.w,
                                height: 100.h,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // const Icon(Icons.group_outlined,
                                      //     size: 14),
                                      // SizedBox(width: 4.w),
                                      // Text(
                                      //   equb.numberOfEqubers.toString(),
                                      //   style: TextStyle(
                                      //       fontSize: 12.sp,
                                      //       fontWeight: FontWeight.w500),
                                      // ),
                                      SizedBox(width: 18.w),
                                      const Icon(Icons.loop_rounded, size: 14),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "${equb.currentRound} Cycle",
                                        style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ((equb.numberOfEqubers ?? 0) *
                                            (equb.equbAmount ?? 0))
                                        .toString()
                                        .replaceAllMapped(
                                            RegExp(
                                                r"(\d{1,3})(?=(\d{3})+(?!\d))"),
                                            (m) => "${m[1]},"),
                                    style: TextStyle(
                                        fontSize: 28.sp,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(height: 2.h),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (equb.name?.isNotEmpty ?? false)
                                        Text(
                                          (equb.name?.length ?? 0) > 10
                                              ? '${equb.name?.substring(0, 10)}...'
                                              : (equb.name ?? ''),
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(9),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            const Icon(Icons.chevron_right,
                                                color: Colors.black, size: 20),
                                            SizedBox(
                                              width: 4.w,
                                            ),
                                            GestureDetector(
                                              onTap: () => onJoin(equb),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    AppKeys.join.tr(context),
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xff178dc1),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 16.sp,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4.w),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(),
                          // Right blue bar
                          Container(
                            width: 28.w,
                            height: 126.h,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 24.h,
              )
            ],
          ),
        );
      },
    );
  }
}
