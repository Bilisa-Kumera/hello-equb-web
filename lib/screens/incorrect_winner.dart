import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

import '../utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';

class WinnerCard extends StatelessWidget {
  final String winnerName;
  final int numberOfWinners;
  final String round;
  final String lotteryNumber;
  final String winnerId;

  WinnerCard({
    super.key,
    required this.winnerName,
    required this.numberOfWinners,
    required this.round,
    required this.lotteryNumber,
    required this.winnerId,
  });

  final DataController dataController = DataController();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 12.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        margin: const EdgeInsets.all(20.0),
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                textScaleFactor: 1.0,
                'NB: Only one person will be the winner for this Equb round.',
                style: AppTextStyles.poppins50016.copyWith(color: AppColors.coralRed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),
              Text(
                textScaleFactor: 1.0,
                'Equb Name: $round',
                style: AppTextStyles.poppins70020.copyWith(color: AppColors.grey800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15.0),

              // Show winner info only if the current user is the winner
               SecureStorageHelper.getUserId() == winnerId
                  ? Container(
                      padding: const EdgeInsets.all(12.0),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.1),
                            blurRadius: 10.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            textScaleFactor: 1.0,
                            "Congratulations! The winner is:",
                            style: AppTextStyles.poppins70016.copyWith(color: AppColors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            textScaleFactor: 1.0,
                            winnerName,
                            style: AppTextStyles.poppins70028.copyWith(color: AppColors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(height: 20.0),

              // Winner's Lottery Number
              Container(
                padding: const EdgeInsets.all(12.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.blue600,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.1),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      textScaleFactor: 1.0,
                      "Winner's Lottery Number:",
                      style: AppTextStyles.poppins50016.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      textScaleFactor: 1.0,
                      lotteryNumber,
                      style: AppTextStyles.poppins70024.copyWith(color: AppColors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Number of Winners

              const SizedBox(height: 20.0),

              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white,
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 30.0),
                ),
                child: Text(
                  textScaleFactor: 1.0,
                  'Close',
                  style: AppTextStyles.poppins70018,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
