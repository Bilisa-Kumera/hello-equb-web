// ignore_for_file: deprecated_member_use

import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/core/amharic_translations.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/screens/join_ekub_detail.dart';
import 'package:ekubee/screens/terms_conditions_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/lang_constants.dart';

import '../utils/custom_appbar.dart';

class JoinEkubConfirmation extends StatefulWidget {
  final String ekubId,
      ekubAmount,
      ekubRound,
      ekubName,
      numberOfEkubers,
      startDate,
      type,
      equbType,
      joinedAmount,
      groupLimit,
      termAndCondition,
      termAndConditionInAmharic,
      ekubDescription;

  String? otherAmount;
  String? financeAmount;
  final double expectedAmount;
  final List<ListItem> items;
  JoinEkubConfirmation(
      {super.key,
      this.financeAmount,
      this.otherAmount,
      required this.ekubAmount,
      required this.ekubId,
      required this.ekubName,
      required this.ekubRound,
      required this.expectedAmount,
      required this.numberOfEkubers,
      required this.startDate,
      required this.type,
      required this.equbType,
      required this.groupLimit,
      required this.joinedAmount,
      required this.termAndCondition,
      required this.termAndConditionInAmharic,
      required this.items,
      required this.ekubDescription});

  @override
  State<JoinEkubConfirmation> createState() => _JoinEkubConfirmationState();
}

class _JoinEkubConfirmationState extends State<JoinEkubConfirmation> {
  @override
  void initState() {
    // equivalentEtb = double.parse(widget.ekubAmount);
    super.initState();
    // equivalentController =
    //     TextEditingController(text: equivalentEtb.toStringAsFixed(2));
  }

  TextEditingController equivalentController = TextEditingController();
  int numbers = 0;

  List<ListItem> items = [];

  @override
  Widget build(BuildContext context) {
    String key = amET[widget.type.toLowerCase()] ?? '';

    return Scaffold(
      appBar: CurvedAppBar(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.centerLeft,
                    colors: [
                      AppColors.forestGreenDark,
                      AppColors.richDeepGreen,
                    ],
                  ),
                ),
                height: 96,
                width: double.infinity,
                padding: const EdgeInsets.only(top: 7.0, bottom: 8),
                child: Stack(
                  children: [
                    // 👥 People Count (Left)
                    // Positioned(
                    //   left: 0,
                    //   top: 0,
                    //   bottom: 50,
                    //   child: Padding(
                    //     padding: const EdgeInsets.only(left: 8.0),
                    //     child: Row(
                    //       children: [
                    //         const Icon(
                    //           Icons.people_alt_outlined,
                    //           size: 18,
                    //           color: AppColors.white,
                    //         ),
                    //         const SizedBox(width: 5),
                    //         Text(
                    //           widget.joinedAmount.toString(),
                    //           style: TextStyle(
                    //             fontFamily: 'Poppins',
                    //             fontWeight: FontWeight.w400,
                    //             fontSize: 12.sp,
                    //             color: AppColors.white,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),

                    // 🔁 Cycle Count (Right)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 50,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.loop_rounded,
                              size: 18,
                              color: AppColors.white,
                            ),
                            Text(
                              widget.numberOfEkubers.toString(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                                fontSize: 12.sp,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 🔠 Name + Amount (Center)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.ekubName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(
                            width: 120.w,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                numberFormat.format(
                                  int.tryParse(widget.ekubAmount.toString())! *
                                      int.tryParse(
                                          widget.numberOfEkubers.toString())!,
                                ),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 33.h,
              ),
              Text(
                AppKeys.ekubConfirmation.tr(context),
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 13.h,
              ),
              Text(
                textScaleFactor: 1.0,
                AppKeys.description.tr(context),
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5B5C5C),
                    fontSize: 14.sp),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                textScaleFactor: 1.0,
                widget.ekubDescription.isEmpty ? 'N/A' : widget.ekubDescription,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5B5C5C),
                    fontSize: 11),
              ),
              const SizedBox(
                height: 13,
              ),
              Text(
                textScaleFactor: 1.0,
                AppKeys.totalShare.tr(context),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B5C5C),
                    fontSize: 14),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                textScaleFactor: 1.0,
                '${widget.items.length}',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5B5C5C),
                    fontSize: 11),
              ),
              const SizedBox(
                height: 13,
              ),
              Text(
                textScaleFactor: 1.0,
                AppKeys.expectedAmount.tr(context),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5B5C5C),
                    fontSize: 14),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                  textScaleFactor: 1.0,
                  numberFormat.format(double.parse(
                      widget.expectedAmount.toString()..replaceAll(',', ''))),
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5B5C5C),
                      fontSize: 11)),
              const SizedBox(
                height: 8,
              ),
              const SizedBox(
                height: 13,
              ),
              Container(
                decoration: const BoxDecoration(
                    color: AppColors.lightGrayBackground,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: ListTile(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          textScaleFactor: 1.0,
                          AppKeys.listOfShares.tr(context),
                          style: TextStyle(
                              color: AppColors.neutralGray,
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      widget.financeAmount != null
                          ? const Text('')
                          : Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    textScaleFactor: 1.0,
                                    AppKeys.listOfShares.tr(context),
                                    style: TextStyle(
                                        color: AppColors.neutralGray,
                                        fontFamily: 'Poppins',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    textScaleFactor: 1.0,
                                    '${AppKeys.expectedAmount.tr(context)} ${widget.type.toUpperCase() == 'weekly' ? AppKeys.weekly.tr(context) : widget.type.toUpperCase() == 'daily' ? AppKeys.daily.tr(context) : widget.type.toUpperCase() == 'monthly' ? AppKeys.monthly.tr(context) : widget.type}',
                                    style: TextStyle(
                                        color: AppColors.neutralGray,
                                        fontFamily: 'Poppins',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                      widget.financeAmount == null
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.items.length,
                              itemBuilder: (context, index) {
                                String percentageString = '100%';
                                if (widget.items[index].title != '1') {
                                  List<String> parts =
                                      widget.items[index].title.split('/');
                                  double numerator = double.parse(parts[0]);
                                  double denominator = double.parse(parts[1]);

                                  double percentage =
                                      (numerator / denominator) * 100;

                                  percentageString =
                                      "${percentage.toStringAsFixed(2)}%";
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 18.0),
                                        child: Text(
                                          textScaleFactor: 1.0,
                                          '${widget.items[index].title}($percentageString)',
                                          style: const TextStyle(
                                              color: AppColors.neutralGray,
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          textScaleFactor: 1.0,
                                          numberFormat.format(double.parse(
                                              widget.items[index].subtitle
                                                  .replaceAll(',', ''))),
                                          style: const TextStyle(
                                              color: AppColors.neutralGray,
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink()
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 53,
              ),
              CustomTextButton(
                  text: AppKeys.join.tr(context),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TermsConditionsScreen(
                            termAndCondition: widget.termAndCondition,
                            termAndConditionInAmharic: widget.termAndConditionInAmharic,
                            ekubId: widget.ekubId,
                            ekubAmount: widget.ekubAmount,
                            ekubName: widget.ekubName,
                            ekubRound: widget.ekubRound,
                            selectedJoinOption: widget.items,
                            selectedAmount: equivalentController.text,
                            expectedAmount: widget.expectedAmount),
                      ),
                    );
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => PaymentArragement(
                    //         ekubName: widget.ekubName,
                    //         ekubRound: widget.ekubRound,
                    //         ekubId: widget.ekubId,
                    //         ekubAmount: widget.ekubAmount,
                    //         joinOption: widget.items.isNotEmpty
                    //             ? widget.items.first.title
                    //             : ' ',
                    //         joinAmount: equivalentController.text,
                    //         selectedJoinOption: widget.items,
                    //         expectedAmount: widget.expectedAmount),
                    //   ),
                    // );
                  })
            ],
          ),
        ),
      ),
    );
  }
}
