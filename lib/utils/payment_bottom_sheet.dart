import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/lang_constants.dart';

class LotteryDetailBottomSheet extends StatelessWidget {
  final String lottery;
  final int round;

  const LotteryDetailBottomSheet(
      {super.key, required this.lottery, required this.round});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            textScaleFactor: 1.0,
            lottery,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          Text(
              textScaleFactor: 1.0,
              "${AppKeys.lastPaidRound.tr(context)}:   $round"),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
