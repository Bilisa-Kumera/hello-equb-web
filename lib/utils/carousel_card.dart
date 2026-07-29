// ignore_for_file: deprecated_member_use

import 'package:carousel_slider/carousel_slider.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'style_constants.dart';

// ignore: must_be_immutable
class CarouselCard extends StatelessWidget {
  int? currentIndex;
  int? length;
  final bool buttonShow;
  String? ekubersNumber, ekubName, amount, cycle;
  final double? total;

  CarouselCard(
      {super.key,
      required this.buttonShow,
      this.ekubersNumber,
      this.ekubName,
      this.amount,
      this.cycle,
      this.length,
      this.currentIndex,
      this.total});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: length ?? 1,
      itemBuilder: (context, index, realIdx) {
        return Padding(
          padding: const EdgeInsets.only(right: 5.0, left: 5),
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            margin: EdgeInsets.zero,
            child: Container(
              decoration:  BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: AppColors.white60),
                color: Colors.transparent,
              ),
              height: 106,
              width: 305,
              padding: const EdgeInsets.only(top: 7.0, bottom: 8),
              child: Stack(
                children: [
                  // Left: Person icon and number
                  // Positioned(
                  //   left: 0,
                  //   top: 0,
                  //   bottom: 50,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(left: 8.0),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         const Icon(
                  //           Icons.people_alt_outlined,
                  //           size: 18,
                  //           color: AppColors.white,
                  //         ),
                  //         Padding(
                  //           padding: const EdgeInsets.only(left: 5.0),
                  //           child: Text(
                  //             textScaleFactor: 1.0,
                  //             ekubersNumber ?? '',
                  //             style: AppTextStyles.caption
                  //                 .copyWith(color: AppColors.white),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // Right: Cycle icon and number
                  // Positioned(
                  //   right: 0,
                  //   top: 0,
                  //   bottom: 50,
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(right: 8.0),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         const Icon(
                  //           Icons.loop_rounded,
                  //           size: 18,
                  //           color: AppColors.white,
                  //         ),
                  //         Text(
                  //           textScaleFactor: 1.0,
                  //           cycle ?? '0',
                  //           style: AppTextStyles.caption
                  //               .copyWith(color: AppColors.white),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // Center: Column of three words
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            textScaleFactor: 1.0,
                            ekubName ?? '',
                            style: AppTextStyles.poppins60012
                                .copyWith(color: AppColors.white)),
                        SizedBox(
                          width: 120.w,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              textScaleFactor: 1.0,
                              numberFormat.format(total),
                              style: AppTextStyles.poppins70028
                                  .copyWith(color: AppColors.white),
                            ),
                          ),
                        ),
                        buttonShow
                            ? SizedBox(
                                height: 22,
                                child: TextButton(
                                  onPressed: () {},
                                  style: const ButtonStyle(
                                      backgroundColor: WidgetStatePropertyAll(
                                          AppColors.white)),
                                  child: Text(
                                      textScaleFactor: 1.0,
                                      'Join Equb',
                                      style: AppTextStyles.buttonMedium
                                          .copyWith(
                                              color: AppColors.vibrantGreen)),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  // Bottom left image
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Padding(
                  //       padding: const EdgeInsets.only(top: 8.0, right: 20),
                  //       child: Image.asset(
                  //         'assets/birr.png',
                  //         height: 92,
                  //         width: 92,
                  //         fit: BoxFit.cover,
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: const EdgeInsets.only(top: 5.0, left: 78),
                  //       child: Image.asset(
                  //         'assets/birr2.png',
                  //         height: 92,
                  //         width: 92,
                  //         fit: BoxFit.cover,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // Bottom right image
                  // Positioned(
                  //   bottom: 0,
                  //   right: 0,
                  //   top: 20,
                  // ),
                ],
              ),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 96,
        viewportFraction: 1.0,
        enlargeCenterPage: false,
      ),
    );
  }
}
