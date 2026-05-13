// ignore_for_file: deprecated_member_use

import 'package:ekubee/screens/join_ekub_detail.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/screens/payment_arrangement_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/lang_constants.dart';

class TermsConditionsScreen extends StatefulWidget {
  final String? ekubId;
  final String? ekubAmount;
  final String? ekubName;
  final String? ekubRound;
  final String termAndCondition;
  final String termAndConditionInAmharic;
  final List<ListItem> selectedJoinOption;
  final String selectedAmount;
  final List<ListItem>? items;
  final double expectedAmount;

  const TermsConditionsScreen({
    super.key,
    required this.ekubId,
    required this.ekubAmount,
    required this.ekubName,
    required this.ekubRound,
    required this.selectedJoinOption,
    required this.selectedAmount,
    required this.termAndCondition,
    required this.termAndConditionInAmharic,
    this.items,
    required this.expectedAmount,
  });

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.white,
            size: 20,
          ),
        ),
        title: Text(
          textScaleFactor: 1.0,
          AppKeys.termsAndConditions.tr(context),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  textScaleFactor: 1.0,
                  PrefUtils.sharedPreferences?.getString('language_code') ==
                          'en'
                      ? widget.termAndCondition
                      : widget.termAndConditionInAmharic,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey700,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ),
          if (widget.ekubName?.isNotEmpty == true)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            activeColor: AppColors.vibrantGreen,
                            onChanged: (val) {
                              setState(() {
                                isChecked = val ?? false;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              textScaleFactor: 1.0,
                              AppKeys.acceptTerms.tr(context),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    CustomTextButton(
                      text: AppKeys.lblContinue.tr(context),
                      onPressed: () {
                        if (isChecked) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PaymentArragement(
                                ekubName: widget.ekubName,
                                ekubRound: widget.ekubRound,
                                ekubId: widget.ekubId,
                                ekubAmount: widget.ekubAmount,
                                joinOption: widget.selectedJoinOption.isNotEmpty
                                    ? widget.selectedJoinOption.first.title
                                    : ' ',
                                joinAmount: widget.selectedAmount,
                                selectedJoinOption: widget.selectedJoinOption,
                                expectedAmount: widget.expectedAmount,
                              ),
                            ),
                          );
                        }
                      },
                      buttonColor:
                          isChecked ? AppColors.primary : AppColors.grey400,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

}
