import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:helloequb/widgets/upload_receipt_sheet.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../utils/secure_storage.dart';

class LotteryPayment {
  final double amount;
  final String? lotteryNumber; // Make lotteryNumber nullable

  LotteryPayment({
    required this.amount,
    this.lotteryNumber, // Nullable
  });

  factory LotteryPayment.fromJson(Map<String, dynamic> json) {
    return LotteryPayment(
      amount: (json['amount'] as num).toDouble(),
      lotteryNumber: json['lotteryNumber'] as String?, // Handle nullable value
    );
  }
}

class Payment {
  final double amount;
  final String equbName;
  final String? picture;
  final String id;
  final List<LotteryPayment> payments;

  Payment({
    required this.amount,
    required this.equbName,
    required this.payments,
    this.picture,
    required this.id,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    var paymentsList = json['payments'] as List;
    List<LotteryPayment> payments =
        paymentsList.map((i) => LotteryPayment.fromJson(i)).toList();

    return Payment(
      amount: (json['amount'] as num).toDouble(),
      equbName: json['equbName'] as String,
      payments: payments,
      picture: json['picture'],
      id: json['id'] as String,
    );
  }
}

class PaymentsData {
  final List<Payment> payments;

  PaymentsData({
    required this.payments,
  });

  factory PaymentsData.fromJson(Map<String, dynamic> json) {
    var paymentsList = json['payments'] as List;
    List<Payment> payments =
        paymentsList.map((i) => Payment.fromJson(i)).toList();

    return PaymentsData(
      payments: payments,
    );
  }
}

class ApiResponse {
  final String status;
  final PaymentsData data;

  ApiResponse({
    required this.status,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] as String,
      data: PaymentsData.fromJson(json['data']),
    );
  }
}

class WaitingEkubsPayment extends StatefulWidget {
  final String ekubId;
  const WaitingEkubsPayment({super.key, required this.ekubId});

  @override
  State<WaitingEkubsPayment> createState() => _WaitingEkubsState();
}

class _WaitingEkubsState extends State<WaitingEkubsPayment> {
  final DataController dataController = DataController();

  List<Payment> pendingEqubs = [];
  Future<void> fetchWaitingEkubs() async {
    final Dio dio = Dio();
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = await dio.get(
        '${pendingPaymentUrl + widget.ekubId}?approved=false',
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.data);

        setState(() {
          // Assign the parsed payments to the pendingEqubs list
          pendingEqubs = apiResponse.data.payments;
        });
      }
    } on DioError catch (error) {
      if (error.response != null &&
          error.response!.data['msg'] == 'Token is not valid') {
        // Handle token invalid error
      }
    } catch (error, stackError) {}
  }

  bool progress = true;
  void stopProgressAfterDelay() {
    Future.delayed(const Duration(seconds: 7), () {
      setState(() {
        progress = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    fetchWaitingEkubs();
    stopProgressAfterDelay();
  }

  Future<void> _onRefresh() async {
    setState(() {
      progress = true;
    });
    await fetchWaitingEkubs();
    stopProgressAfterDelay();
  }

  Future<void> _openUploadSheet(Payment item) async {
    await UploadReceiptSheet.show(
      context,
      ekubAmount: numberFormat.format(item.amount),
      ekubId: item.id,
      joinOption: '100',
    );
    if (mounted) fetchWaitingEkubs();
  }

  void _showSubmittedInfo() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppKeys.paymentInfo.tr(context)),
        content: Text(AppKeys.youHaveAlreadySubmitted.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppKeys.ok.tr(context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 18,
          ),
        ),
        title: Text(
          AppKeys.pendingPayments.tr(context),
          style: AppTextStyles.poppins60014.copyWith(color: Colors.black87),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: pendingEqubs.isNotEmpty
            ? ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: pendingEqubs.length,
                itemBuilder: (context, index) {
                  final item = pendingEqubs[index];
                  return _buildPaymentCard(item);
                },
              )
            : progress
                ? ListView(
                    children: [
                      SizedBox(height: 120.h),
                      Center(
                        child: LoadingAnimationWidget.threeRotatingDots(
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  )
                : ListView(
                    children: [
                      SizedBox(height: 120.h),
                      Icon(Icons.inbox_outlined,
                          size: 48.sp, color: Colors.grey.shade400),
                      SizedBox(height: 12.h),
                      Center(
                        child: Text(
                          AppKeys.noData.tr(context),
                          style: AppTextStyles.captionMuted,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: AppColors.primary, size: 20),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppKeys.ekubName.tr(context),
                      style: AppTextStyles.captionMuted,
                    ),
                    Text(
                      item.equbName,
                      style: AppTextStyles.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          _detailTile(
            label: AppKeys.totalAmount.tr(context),
            value: numberFormat.format(item.amount),
            valueColor: AppColors.vibrantGreen,
            emphasized: true,
          ),
          if (item.payments.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.payments.expand((payment) {
                return [
                  _lotteryChip(
                    '${AppKeys.lottery.tr(context)} ${payment.lotteryNumber ?? '-'}',
                  ),
                  _lotteryChip(
                    '${AppKeys.amount.tr(context)} ${numberFormat.format(payment.amount)}',
                  ),
                ];
              }).toList(),
            ),
          ],
          SizedBox(height: 14.h),
          Row(
            children: [
              Text(
                AppKeys.paymentStatus.tr(context),
                style: AppTextStyles.captionMuted,
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  AppKeys.pending.tr(context),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (item.picture == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openUploadSheet(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: Size(double.infinity, 40.h),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppKeys.uploadReceipt.tr(context),
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.blue, size: 16),
                  SizedBox(width: 6.w),
                  Text(
                    AppKeys.waitingForApproval.tr(context),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.info_outline,
                        color: AppColors.blue, size: 16),
                    onPressed: _showSubmittedInfo,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required String label,
    required String value,
    Color? valueColor,
    bool emphasized = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.captionMuted),
        Text(
          value,
          style: (emphasized
                  ? AppTextStyles.sectionTitleLarge
                  : AppTextStyles.labelMedium)
              .copyWith(
            color: valueColor ?? Colors.black87,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _lotteryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text, style: AppTextStyles.labelSmall),
    );
  }
}
