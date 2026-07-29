// ignore_for_file: must_be_immutable, deprecated_member_use

import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/screens/payment_screen.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';

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
  List<double> stepAmounts = [];
  List<bool> hasError = [];
  bool _isContinuing = false;
  bool _showZeroTotalError = false;

  @override
  void initState() {
    super.initState();

    if (widget.selectedJoinOption == null && widget.lotteries != null) {
      widget.selectedJoinOption =
          List.generate(widget.lotteries!.length, (index) {
        return ListItem(
          title: widget.lotteries![index],
          subtitle: widget.lotteries![index],
        );
      });
    }

    final options = widget.selectedJoinOption ?? [];
    stepAmounts = options.map(_stepAmountForItem).toList();
    controllers = options.asMap().entries.map((entry) {
      final item = entry.value;
      final initialAmount = _initialAmountForItem(item);
      final controller =
          TextEditingController(text: _formatAmount(initialAmount));
      controller.addListener(_updateTotal);
      _syncItemAmount(entry.key, initialAmount);
      return controller;
    }).toList();

    hasError = List.generate(options.length, (_) => false);

    totalTobePaid = _calculateTotal();
  }

  double _parseAmount(String value) =>
      double.tryParse(value.replaceAll(',', '')) ?? 0;

  double _stepAmountForItem(ListItem item) {
    // Prefer subtitle — it holds the per-round amount from the API.
    // widget.ekubAmount is sometimes the total pot (amount × members).
    final fromSubtitle = _parseAmount(item.subtitle);
    if (fromSubtitle > 0) return fromSubtitle;

    return _parseAmount(widget.ekubAmount ?? '');
  }

  double _initialAmountForItem(ListItem item) {
    final fromSubtitle = _parseAmount(item.subtitle);
    if (fromSubtitle > 0) return fromSubtitle;

    return _parseAmount(widget.ekubAmount ?? '');
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toString();
  }

  void _syncItemAmount(int index, double amount) {
    final text = _formatAmount(amount);
    widget.selectedJoinOption![index].subtitle = text;
    if (widget.type == 'payment' &&
        widget.selectedJoinOptions != null &&
        index < widget.selectedJoinOptions!.length) {
      widget.selectedJoinOptions![index].subtitle = text;
    }
  }

  void _setAmount(int index, double amount) {
    controllers[index].text = _formatAmount(amount);
    hasError[index] = false;
    _showZeroTotalError = false;
    _syncItemAmount(index, amount);
    setState(() {
      totalTobePaid = _calculateTotal();
    });
  }

  void _incrementAmount(int index) {
    final step = stepAmounts[index];
    if (step <= 0) return;
    final current = _parseAmount(controllers[index].text);
    _setAmount(index, current + step);
  }

  void _decrementAmount(int index) {
    final step = stepAmounts[index];
    if (step <= 0) return;
    final current = _parseAmount(controllers[index].text);
    final next = current - step;
    if (next < 0) return;
    _setAmount(index, next);
  }

  double _calculateTotal() {
    double total = 0;
    for (var controller in controllers) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        total += double.tryParse(text.replaceAll(',', '')) ?? 0;
      }
    }
    return total;
  }

  void _updateTotal() {
    final nextTotal = _calculateTotal();
    if (nextTotal == totalTobePaid) return;
    setState(() => totalTobePaid = nextTotal);
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.removeListener(_updateTotal);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> validateAndContinue() async {
    if (_isContinuing) return;

    bool hasValidationError = false;
    for (int i = 0; i < controllers.length; i++) {
      final text = controllers[i].text.trim();
      if (text.isEmpty) {
        hasError[i] = true;
        hasValidationError = true;
      } else {
        hasError[i] = false;
      }
    }

    final total = _calculateTotal();
    if (total <= 0) {
      hasValidationError = true;
      _showZeroTotalError = true;
    } else {
      _showZeroTotalError = false;
    }

    if (hasValidationError) {
      setState(() {});
      return;
    }

    _isContinuing = true;

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          ekubName: widget.ekubName,
          ekubRound: widget.ekubRound,
          ekubId: widget.ekubId,
          ekubAmount: total.toString(),
          selectedJoinOptions: widget.selectedJoinOptions,
          joinOption: widget.selectedJoinOption?.isNotEmpty == true
              ? widget.selectedJoinOption!.first.title
              : ' ',
          selectedJoinOption: widget.selectedJoinOption,
          joinAmount: widget.selectedAmount,
          type: widget.type,
        ),
      ),
    );

    if (mounted) {
      setState(() => _isContinuing = false);
    }
  }

  String _sharePercentageLabel(ListItem item) {
    if (item.title == '1' || widget.type == 'payment') {
      return '100%';
    }
    final parts = item.title.split('/');
    if (parts.length != 2) return '100%';
    final numerator = double.tryParse(parts[0]) ?? 0;
    final denominator = double.tryParse(parts[1]) ?? 1;
    if (denominator == 0) return '100%';
    final percentage = (numerator / denominator) * 100;
    return '${percentage.toStringAsFixed(1)}%';
  }

  Widget _amountStepButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool filled = false,
  }) {
    if (filled) {
      return SizedBox(
        width: 44.w,
        height: 44.w,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.grey100,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null ? AppColors.lightNeutralGray : Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      width: 44.w,
      height: 44.w,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: onPressed == null
                ? AppColors.grey100
                : AppColors.primary.withOpacity(0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed == null ? AppColors.lightNeutralGray : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStakeCard({
    required BuildContext context,
    required int index,
    required ListItem item,
    required double currentAmount,
    required double step,
    required bool canDecrement,
    required bool isSkipped,
  }) {
    final isPayment = widget.type == 'payment';
    final stakeTitle = isPayment
        ? item.title
        : '${AppKeys.yourShare.tr(context)} ${index + 1}';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  isPayment
                      ? Icons.confirmation_number_outlined
                      : Icons.pie_chart_outline_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPayment
                          ? AppKeys.lotteryNumber.tr(context)
                          : AppKeys.yourShare.tr(context),
                      style: AppTextStyles.captionMuted.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stakeTitle,
                      style: AppTextStyles.poppins60014.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPayment && isSkipped)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '0 ETB',
                    style: AppTextStyles.captionMuted.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              else if (!isPayment)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    _sharePercentageLabel(item),
                    style: AppTextStyles.badge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: hasError[index]
                    ? Colors.red.shade300
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppKeys.amount.tr(context),
                    style: AppTextStyles.captionMuted.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Text(
                  '${numberFormat.format(currentAmount)} ETB',
                  style: AppTextStyles.poppins70014.copyWith(
                    color: isSkipped
                        ? AppColors.lightNeutralGray
                        : AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          if (hasError[index]) ...[
            SizedBox(height: 6.h),
            Text(
              AppKeys.amountIsRequired.tr(context),
              style: AppTextStyles.captionMuted.copyWith(
                color: Colors.red.shade400,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _amountStepButton(
                icon: Icons.remove_rounded,
                onPressed:
                    canDecrement ? () => _decrementAmount(index) : null,
              ),
              SizedBox(width: 16.w),
              Column(
                children: [
                  Text(
                    AppKeys.amount.tr(context),
                    style: AppTextStyles.captionMuted.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 10.sp,
                    ),
                  ),
                  Text(
                    numberFormat.format(step),
                    style: AppTextStyles.poppins60013.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16.w),
              _amountStepButton(
                icon: Icons.add_rounded,
                onPressed: () => _incrementAmount(index),
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.selectedJoinOption?.length ?? 0;
    final isPayment = widget.type == 'payment';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 18,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppKeys.payment.tr(context),
              style: AppTextStyles.poppins60014,
            ),
            Text(
              AppKeys.paymentArrangement.tr(context),
              style: AppTextStyles.captionMuted.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPayment && itemCount > 0) ...[
                Text(
                  AppKeys.lotteryNumbers.tr(context),
                  style: AppTextStyles.poppins60014.copyWith(
                    color: AppColors.richDeepGreen,
                  ),
                ),
                SizedBox(height: 12.h),
              ] else if (!isPayment) ...[
                Text(
                  AppKeys.yourShare.tr(context),
                  style: AppTextStyles.poppins60014.copyWith(
                    color: AppColors.richDeepGreen,
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final item = widget.selectedJoinOption![index];
                  final currentAmount = _parseAmount(controllers[index].text);
                  final step = stepAmounts[index];
                  final canDecrement = currentAmount > 0;
                  final isSkipped = currentAmount == 0;

                  return _buildStakeCard(
                    context: context,
                    index: index,
                    item: item,
                    currentAmount: currentAmount,
                    step: step,
                    canDecrement: canDecrement,
                    isSkipped: isSkipped,
                  );
                },
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppKeys.totalTobePaid.tr(context),
                          style: AppTextStyles.poppins60014,
                        ),
                        Text(
                          '${numberFormat.format(totalTobePaid)} ETB',
                          style: AppTextStyles.poppins70014.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_showZeroTotalError) ...[
                      SizedBox(height: 6.h),
                      Text(
                        AppKeys.selectAtLeastOnePaymentAmount.tr(context),
                        style: AppTextStyles.captionMuted.copyWith(
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: _isContinuing
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              },
                        child: Text(
                          AppKeys.cancel.tr(context),
                          style: AppTextStyles.poppins60014
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 48.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: _isContinuing ? null : validateAndContinue,
                        child: _isContinuing
                            ? SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                AppKeys.lblContinue.tr(context),
                                style: AppTextStyles.poppins60014
                                    .copyWith(color: AppColors.white),
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
