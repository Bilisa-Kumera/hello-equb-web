// ignore_for_file: deprecated_member_use

import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/amharic_translations.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/terms_conditions_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/lang_constants.dart';

import '../utils/custom_appbar.dart';
import 'package:helloequb/utils/style_constants.dart';

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(color: AppColors.white60),
                    color: Colors.transparent,
                  ),
                  height: 106,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.only(top: 7.0, bottom: 8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          textScaleFactor: 1.0,
                          widget.ekubName,
                          style: AppTextStyles.poppins60012
                              .copyWith(color: AppColors.white),
                        ),
                        SizedBox(
                          width: 160.w,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              textScaleFactor: 1.0,
                              numberFormat.format(
                                (int.tryParse(widget.ekubAmount.toString()) ??
                                        0) *
                                    (int.tryParse(widget.numberOfEkubers
                                            .toString()) ??
                                        0),
                              ),
                              style: AppTextStyles.poppins70028
                                  .copyWith(color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
                style: AppTextStyles.dialogTitle,
              ),
              SizedBox(
                height: 13.h,
              ),
              Text(
                textScaleFactor: 1.0,
                AppKeys.description.tr(context),
                style: AppTextStyles.poppins60014.copyWith(color: const Color(0xFF5B5C5C)),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                textScaleFactor: 1.0,
                widget.ekubDescription.isEmpty ? 'N/A' : widget.ekubDescription,
                style: AppTextStyles.poppins50011.copyWith(color: Color(0xFF5B5C5C)),
              ),
              const SizedBox(
                height: 13,
              ),
              Text(
                textScaleFactor: 1.0,
                AppKeys.totalShare.tr(context),
                style: AppTextStyles.poppins60014.copyWith(color: Color(0xFF5B5C5C)),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                textScaleFactor: 1.0,
                '${widget.items.length}',
                style: AppTextStyles.poppins50011.copyWith(color: Color(0xFF5B5C5C)),
              ),
              const SizedBox(
                height: 13,
              ),
              Text(
                textScaleFactor: 1.0,
                AppKeys.expectedAmount.tr(context),
                style: AppTextStyles.poppins60014.copyWith(color: Color(0xFF5B5C5C)),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                  textScaleFactor: 1.0,
                  numberFormat.format(double.parse(
                      widget.expectedAmount.toString()..replaceAll(',', ''))),
                  style: AppTextStyles.poppins50011.copyWith(color: Color(0xFF5B5C5C))),
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
                          style: AppTextStyles.poppins70016.copyWith(color: AppColors.neutralGray),
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
                                    style: AppTextStyles.poppins60012.copyWith(color: AppColors.neutralGray),
                                  ),
                                  Text(
                                    textScaleFactor: 1.0,
                                    '${AppKeys.expectedAmount.tr(context)} ${widget.type.toUpperCase() == 'weekly' ? AppKeys.weekly.tr(context) : widget.type.toUpperCase() == 'daily' ? AppKeys.daily.tr(context) : widget.type.toUpperCase() == 'monthly' ? AppKeys.monthly.tr(context) : widget.type}',
                                    style: AppTextStyles.poppins60012.copyWith(color: AppColors.neutralGray),
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
                                          style: AppTextStyles.poppins40011.copyWith(color: AppColors.neutralGray),
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
                                          style: AppTextStyles.poppins40011.copyWith(color: AppColors.neutralGray),
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
