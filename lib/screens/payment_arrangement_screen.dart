// ignore_for_file: must_be_immutable, deprecated_member_use

import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/screens/payment_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:helloequb/core/telebirr/telebirr_mini_app_detector.dart';

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
  /// Total equb cycles (members); used on join to allow multi-round payments.
  final String? numberOfEqubers;

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
      this.type,
      this.numberOfEqubers});

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
    stepAmounts = options
        .asMap()
        .entries
        .map((entry) => _stepAmountForItem(entry.key, entry.value))
        .toList();

    // Join flow: build ListItems so + can go multi-round and Payment Info shows.
    if ((widget.selectedJoinOptions == null ||
            widget.selectedJoinOptions!.isEmpty) &&
        options.isNotEmpty &&
        widget.type != 'payment') {
      final totalRounds = int.tryParse(widget.numberOfEqubers ?? '') ?? 0;
      widget.selectedJoinOptions = options.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final step = i < stepAmounts.length ? stepAmounts[i] : 0.0;
        final maxPay =
            totalRounds > 0 && step > 0 ? step * totalRounds : double.infinity;
        return ListItems(
          title: '${i + 1}',
          subtitle: _formatAmount(step),
          userIds: '',
          roundAmount: step,
          maxPayableAmount: maxPay,
          stake: _stakeFromShareTitle(item.title),
          paidRound: 0,
          defaultAmount: step,
        );
      }).toList();
    }

    controllers = options.asMap().entries.map((entry) {
      final controller = TextEditingController();
      controller.addListener(_updateTotal);
      return controller;
    }).toList();

    hasError = List.generate(options.length, (_) => false);
    _resetAmountsToDefault(notify: false);

    final detector = createTelebirrMiniAppDetector();
    if (detector.isTelebirrMiniApp()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        validateAndContinue();
      });
    }
  }

  double _parseAmount(String value) =>
      double.tryParse(value.replaceAll(',', '')) ?? 0;

  double _stepAmountForItem(int index, ListItem item) {
    if (widget.selectedJoinOptions != null &&
        index < widget.selectedJoinOptions!.length) {
      final roundAmount = widget.selectedJoinOptions![index].roundAmount;
      if (roundAmount > 0) return roundAmount;
    }

    // Join: derive step from equb × share — never from mutated subtitle.
    if (widget.type != 'payment') {
      final ekub = _parseAmount(widget.ekubAmount ?? '');
      if (ekub > 0) {
        return ekub * (_stakeFromShareTitle(item.title) / 100.0);
      }
    }

    final fromSubtitle = _parseAmount(item.subtitle);
    if (fromSubtitle > 0) return fromSubtitle;

    return _parseAmount(widget.ekubAmount ?? '');
  }

  double _defaultAmountForItem(int index) {
    if (_isFullyPaid(index)) return 0;

    if (widget.selectedJoinOptions != null &&
        index < widget.selectedJoinOptions!.length) {
      final d = widget.selectedJoinOptions![index].defaultAmount;
      if (d > 0) return d;
      final round = widget.selectedJoinOptions![index].roundAmount;
      if (round > 0) return round;
    }

    if (index < stepAmounts.length && stepAmounts[index] > 0) {
      return stepAmounts[index];
    }

    final options = widget.selectedJoinOption;
    if (options != null && index < options.length) {
      final fromSubtitle = _parseAmount(options[index].subtitle);
      if (fromSubtitle > 0) return fromSubtitle;
    }
    return _parseAmount(widget.ekubAmount ?? '');
  }

  void _resetAmountsToDefault({bool notify = true}) {
    final options = widget.selectedJoinOption ?? [];
    for (int i = 0; i < options.length && i < controllers.length; i++) {
      final amount = _defaultAmountForItem(i);
      final text = _formatAmount(amount);
      if (controllers[i].text != text) {
        controllers[i].text = text;
      }
      _syncItemAmount(i, amount);
      if (i < hasError.length) hasError[i] = false;
    }
    _showZeroTotalError = false;
    totalTobePaid = _calculateTotal();
    if (notify && mounted) setState(() {});
  }

  bool _isFullyPaid(int index) {
    return widget.type == 'payment' &&
        widget.selectedJoinOptions != null &&
        index < widget.selectedJoinOptions!.length &&
        widget.selectedJoinOptions![index].isFullyPaid;
  }

  double _stakeFromShareTitle(String title) {
    if (title == '1') return 100;
    if (title == '1/2') return 50;
    if (title == '1/4') return 25;
    if (title.contains('/')) {
      final parts = title.split('/');
      if (parts.length == 2) {
        final n = double.tryParse(parts[0]) ?? 0;
        final d = double.tryParse(parts[1]) ?? 1;
        if (d != 0) return 100 * (n / d);
      }
    }
    return 100;
  }

  double _maxPayableForItem(int index) {
    // Joined payments + join multi-round: use ListItems cap when present.
    if (widget.selectedJoinOptions != null &&
        index < widget.selectedJoinOptions!.length) {
      final max = widget.selectedJoinOptions![index].maxPayableAmount;
      if (max.isFinite && max > 0) return max;
      if (!max.isFinite) return max;
    }

    // Join fallback: one share step × total equb rounds.
    if (index < stepAmounts.length && stepAmounts[index] > 0) {
      final totalRounds = int.tryParse(widget.numberOfEqubers ?? '') ?? 0;
      if (totalRounds > 0) return stepAmounts[index] * totalRounds;
      return double.infinity;
    }
    final options = widget.selectedJoinOption;
    if (options != null && index < options.length) {
      final fromSubtitle = _parseAmount(options[index].subtitle);
      if (fromSubtitle > 0) {
        final totalRounds = int.tryParse(widget.numberOfEqubers ?? '') ?? 0;
        if (totalRounds > 0) return fromSubtitle * totalRounds;
        return double.infinity;
      }
    }
    final fromEkub = _parseAmount(widget.ekubAmount ?? '');
    return fromEkub > 0 ? fromEkub : 0;
  }

  bool _canIncrement(int index) {
    if (_isFullyPaid(index)) return false;
    final step = stepAmounts[index];
    if (step <= 0) return false;
    final current = _parseAmount(controllers[index].text);
    final maxPayable = _maxPayableForItem(index);
    return current < maxPayable - 0.01;
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
    if (widget.selectedJoinOptions != null &&
        index < widget.selectedJoinOptions!.length) {
      widget.selectedJoinOptions![index].subtitle = text;
    }
  }

  void _setAmount(int index, double amount) {
    final maxPayable = _maxPayableForItem(index);
    final clamped = amount.clamp(0.0, maxPayable.isFinite ? maxPayable : amount);
    controllers[index].text = _formatAmount(clamped);
    hasError[index] = false;
    _showZeroTotalError = false;
    _syncItemAmount(index, clamped);
    setState(() {
      totalTobePaid = _calculateTotal();
    });
  }

  void _incrementAmount(int index) {
    if (_isFullyPaid(index)) return;
    final step = stepAmounts[index];
    if (step <= 0) return;
    final current = _parseAmount(controllers[index].text);
    final maxPayable = _maxPayableForItem(index);
    if (current >= maxPayable - 0.01) return;
    final next = (current + step).clamp(0.0, maxPayable);
    if (next <= current) return;
    _setAmount(index, next);
  }

  void _decrementAmount(int index) {
    if (_isFullyPaid(index)) return;
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
      if (_isFullyPaid(i)) {
        hasError[i] = false;
        continue;
      }
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

    // Removing the blocking check for hasExceededError based on user request.

    if (hasValidationError) {
      setState(() {});
      return;
    }

    // --- Issue 5: Show descriptive dialog when amount exceeds expected ---
    if (widget.expectedAmount != null && total > widget.expectedAmount!) {
      final detector = createTelebirrMiniAppDetector();
      if (!detector.isTelebirrMiniApp()) {
        final excess = total - widget.expectedAmount!;
        final shouldContinue = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
              Icon(Icons.info_outline,
                  color: Colors.blue.shade700, size: 28),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  AppKeys.amountExceedsExpected.tr(context),
                  style: AppTextStyles.poppins60014.copyWith(
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppKeys.payingMoreThanExpected
                    .tr(context)
                    .replaceAll('{expected}',
                        numberFormat.format(widget.expectedAmount))
                    .replaceAll('{paying}',
                        numberFormat.format(total)),
                style: AppTextStyles.captionMuted.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                      color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppKeys.excessAmount.tr(context),
                      style: AppTextStyles.poppins60013.copyWith(
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      '${numberFormat.format(excess)} ETB',
                      style: AppTextStyles.poppins70014.copyWith(
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                AppKeys.doYouWantToContinue.tr(context),
                style: AppTextStyles.poppins60013,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                AppKeys.cancel.tr(context),
                style: AppTextStyles.poppins60013.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                AppKeys.lblContinue.tr(context),
                style: AppTextStyles.poppins60013.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return;
      }
      }
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
      _isContinuing = false;
      // Returning from payment method page: restore one-round defaults.
      _resetAmountsToDefault();
    }
  }

  String _sharePercentageLabel(ListItem item) {
    if (item.title == '1') return AppKeys.full.tr(context);
    if (item.title == '1/2') return AppKeys.half.tr(context);
    if (item.title == '1/4') return AppKeys.quarter.tr(context);
    final parts = item.title.split('/');
    if (parts.length != 2) return AppKeys.full.tr(context);
    final numerator = double.tryParse(parts[0]) ?? 0;
    final denominator = double.tryParse(parts[1]) ?? 1;
    if (denominator == 0) return AppKeys.full.tr(context);
    final percentage = (numerator / denominator) * 100;
    return shareLabelFromStake(percentage, context);
  }

  String _paymentShareLabel(int index) {
    if (widget.selectedJoinOptions != null &&
        index < widget.selectedJoinOptions!.length) {
      return shareLabelFromStake(
          widget.selectedJoinOptions![index].stake, context);
    }
    return AppKeys.full.tr(context);
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
    required bool canIncrement,
    required bool isSkipped,
    required bool isLockedAtZero,
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
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  isPayment
                      ? _paymentShareLabel(index)
                      : _sharePercentageLabel(item),
                  style: AppTextStyles.poppins60011.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (isPayment && isLockedAtZero) ...[
                SizedBox(width: 8.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.earthySuccessGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    AppKeys.paid.tr(context),
                    style: AppTextStyles.captionMuted.copyWith(
                      color: AppColors.earthySuccessGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else if (isPayment && isSkipped) ...[
                SizedBox(width: 8.w),
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
                ),
              ],
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
          if (!isLockedAtZero) ...[
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
                  onPressed:
                      canIncrement ? () => _incrementAmount(index) : null,
                  filled: true,
                ),
              ],
            ),
          ],
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
          onPressed: () => Navigator.of(context).maybePop(),
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
                  final isLockedAtZero = _isFullyPaid(index);
                  final canDecrement = !isLockedAtZero && currentAmount > 0;
                  final canIncrement = _canIncrement(index);
                  final isSkipped = !isLockedAtZero && currentAmount == 0;

                  return _buildStakeCard(
                    context: context,
                    index: index,
                    item: item,
                    currentAmount: currentAmount,
                    step: step,
                    canDecrement: canDecrement,
                    canIncrement: canIncrement,
                    isSkipped: isSkipped,
                    isLockedAtZero: isLockedAtZero,
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
                    if (widget.expectedAmount != null) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppKeys.expectedTotal.tr(context),
                            style: AppTextStyles.captionMuted,
                          ),
                          Text(
                            '${numberFormat.format(widget.expectedAmount)} ETB',
                            style: AppTextStyles.captionMuted,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppKeys.remainingAmount.tr(context),
                            style: AppTextStyles.captionMuted,
                          ),
                          Text(
                            '${numberFormat.format((widget.expectedAmount! - totalTobePaid).clamp(0, double.infinity))} ETB',
                            style: AppTextStyles.captionMuted.copyWith(
                              color: totalTobePaid > widget.expectedAmount! ? Colors.red : null,
                            ),
                          ),
                        ],
                      ),
                      if (totalTobePaid > widget.expectedAmount!) ...[
                        SizedBox(height: 6.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade800),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  '${AppKeys.extraRoundsPayment.tr(context)}: ${numberFormat.format(totalTobePaid - widget.expectedAmount!)} ETB',
                                  style: AppTextStyles.captionMuted.copyWith(
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (totalTobePaid > 0 && totalTobePaid < widget.expectedAmount!) ...[
                        SizedBox(height: 6.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  AppKeys.payingLessThanExpected.tr(context),
                                  style: AppTextStyles.captionMuted.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
                            : () => Navigator.of(context).maybePop(),
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
