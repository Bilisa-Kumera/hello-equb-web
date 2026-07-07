// ignore_for_file: must_be_immutable, deprecated_member_use

import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/screens/payment_screen.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/lang_constants.dart';

class PaymentArragement extends StatefulWidget {
  final String? ekubId;
  final String? ekubAmount;
  final String? ekubName;
  final String? ekubRound;
  final List<String>? lotteries;
  final List<int>? paidForEachLotteries;
  List<ListItem>? selectedJoinOption;
  List<ListItems>? selectedJoinOptions;

  final String? selectedAmount;
  String? joinOption, joinAmount;
  final double? expectedAmount;
  final String? round, type;

  PaymentArragement(
      {super.key,
      this.paidForEachLotteries,
      this.lotteries,
      this.ekubName,
      this.ekubId,
      this.ekubAmount,
      this.ekubRound,
      this.selectedAmount,
      this.selectedJoinOption,
      this.selectedJoinOptions,
      this.joinAmount,
      this.joinOption,
      this.expectedAmount,
      this.round,
      this.type});

  @override
  State<PaymentArragement> createState() => _PaymentArragementState();
}

class _PaymentArragementState extends State<PaymentArragement> {
  double totalTobePaid = 0;
  List<TextEditingController> controllers = [];
  List<FocusNode> focusNodes = [];
  List<bool> editedList = [];
  List<bool> hasError = []; // List to track error states
  @override
  void initState() {
    super.initState();
    if (widget.selectedJoinOption != null) {
      controllers.clear();
      focusNodes.clear();
      editedList.clear();
      hasError.clear();

      for (int i = 0; i < widget.selectedJoinOption!.length; i++) {
        controllers.add(TextEditingController());
        focusNodes.add(FocusNode());
        editedList.add(false);
        hasError.add(false);
      }
    }
    totalTobePaid = widget.expectedAmount ?? 0;

    if (widget.selectedJoinOption == null && widget.lotteries != null) {
      widget.selectedJoinOption =
          List.generate(widget.lotteries!.length, (index) {
        return ListItem(
          title: widget.lotteries![index],
          subtitle: widget.lotteries![index],
        );
      });
    }

    controllers = widget.selectedJoinOption?.map((item) {
          final controller = TextEditingController(text: item.subtitle);
          controller.addListener(_updateTotal);
          return controller;
        }).toList() ??
        [];
  }

  void _updateTotal() {
    double total = 0;
    for (var controller in controllers) {
      final text = controller.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text) ?? 0;
        total += value;
      }
    }
    // setState(() {
    totalTobePaid = total;
    // });
  }

  Future<double> getTotal() async {
    await Future.delayed(const Duration(seconds: 2));
    double total = 0;
    for (var controller in controllers) {
      final text = controller.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text.replaceAll(',', '')) ?? 0;
        total += value;
      }
    }
    return total;
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void toggleFocus(int index) {
    setState(() {
      editedList[index] = !editedList[index];

      if (editedList[index]) {
        focusNodes[index].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    });
  }

  Future<void> validateAndContinue() async {
    bool hasEmptyFields = false;
    for (int i = 0; i < controllers.length; i++) {
      if (controllers[i].text.isEmpty) {
        hasError[i] = true;
        hasEmptyFields = true;
      } else {
        hasError[i] = false;
      }
    }

    if (hasEmptyFields) {
      setState(() {});
    } else {
     
      double total = await getTotal();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
              ekubName: widget.ekubName,
              ekubRound: widget.ekubRound,
              ekubId: widget.ekubId,
              // percentage: total,
              ekubAmount: total.toString(),
              selectedJoinOptions: widget.selectedJoinOptions,
              joinOption: widget.selectedJoinOption?.isNotEmpty == true
                  ? widget.selectedJoinOption!.first.title
                  : ' ',
              selectedJoinOption: widget.selectedJoinOption,
              joinAmount: widget.selectedAmount,
              // round: widget.round,
              type: widget.type),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
        ),
        title: Text(
          textScaleFactor: 1.0,
          AppKeys.payment.tr(context),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textScaleFactor: 1.0,
                AppKeys.paymentArrangement.tr(context),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              SizedBox(height: 16.h),

              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.selectedJoinOption?.length ?? 0,
                itemBuilder: (context, index) {
                  final item = widget.selectedJoinOption![index];
                  final controller = controllers[index];
                  controller.text = item.subtitle.replaceAll(',', '');

                  String percentageString = '100%';
                  if (item.title != '1' && widget.type != 'payment') {
                    List<String> parts = item.title.split('/');
                    double numerator = double.parse(parts[0]);
                    double denominator = double.parse(parts[1]);
                    totalTobePaid = (numerator / denominator) * 100;
                    percentageString = "${totalTobePaid.toStringAsFixed(1)}%";
                  }

                  return Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                textScaleFactor: 1.0,
                                widget.type != 'payment'
                                    ? '${index + 1}'
                                    : item.title,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.neutralGray,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_document,
                                size: 18, color: AppColors.neutralGray),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Text(
                              textScaleFactor: 1.0,
                              '${AppKeys.amount.tr(context)}:',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightNeutralGray,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: SizedBox(
                                height: 36.h,
                                child: TextField(
                                  enableInteractiveSelection: false,
                                  enabled: true,
                                  focusNode: focusNodes[index],
                                  controller: controller,
                                  decoration: InputDecoration(
                                    hintText: item.subtitle,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10.w, vertical: 0),
                                    errorText: hasError[index]
                                        ? 'Amount is required'
                                        : null,
                                    filled: true,
                                    fillColor: AppColors.grey100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.neutralGray,
                                  ),
                                  keyboardType: TextInputType.number,
                                  cursorColor: AppColors.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      widget.selectedJoinOption![index]
                                          .subtitle = value;
                                      widget.type != 'payment'
                                          ? widget.selectedJoinOption![index]
                                              .subtitle = value
                                          : widget.selectedJoinOptions![index]
                                              .subtitle = value;
                                      getTotal();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              /// Total Amount
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      textScaleFactor: 1.0,
                      AppKeys.totalTobePaid.tr(context),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    FutureBuilder<double>(
                      future: getTotal(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SpinKitCircle(
                            color: AppColors.primary,
                            size: 24.0,
                          );
                        } else if (snapshot.hasError) {
                          return const Text(
                            textScaleFactor: 1.0,
                            'Error',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.red),
                          );
                        } else {
                          return Text(
                            textScaleFactor: 1.0,
                            numberFormat.format(snapshot.data!),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                              fontFamily: 'Poppins',
                              color: AppColors.black,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                        child: Text(
                          AppKeys.cancel.tr(context),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          validateAndContinue();
                        },
                        child: Text(
                          AppKeys.lblContinue.tr(context),
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
