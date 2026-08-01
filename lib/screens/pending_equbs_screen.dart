import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:helloequb/models/pending_payments.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/main_nav_helper.dart';
import 'package:helloequb/utils/token_helper.dart';

import '../utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:helloequb/widgets/upload_receipt_sheet.dart';

class WaitingEkubs extends StatefulWidget {
  const WaitingEkubs({super.key});

  @override
  State<WaitingEkubs> createState() => _WaitingEkubsState();
}

class _WaitingEkubsState extends State<WaitingEkubs> {
  final DataController dataController = DataController();
  final Dio dio = Dio();

  List<Payment>? payments;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  Future<void> fetchWaitingEkubs({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

      final response = await dio.get(
        "$getMyPendingEqubs?_limit=50",
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ApiResponse apiResponse = ApiResponse.fromJson(response.data);

        if (mounted) {
          setState(() {
            payments = apiResponse.data?.payments;
            isLoading = false;
            hasError = false;
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } on DioError catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          if (error.response != null &&
              error.response!.data['msg'] == 'Token is not valid') {
            errorMessage = 'Session expired. Please login again.';
          } else {
            errorMessage = 'Failed to load pending equbs. Please try again.';
          }
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  Future<void> tokenUpdate() async {
    TokenHelper.checkTokenExpiration(
      context: context,
      dio: dio,
      refreshTokenUrl: refreshTokenUrl,
      refreshToken: (await SecureStorageHelper.getRefreshToken()) ?? '',
    );
  }

  @override
  void initState() {
    super.initState();
    fetchWaitingEkubs();
    tokenUpdate();
  }

  Future<List<EqubCategorys>?> loadEkubCategories() async {
    List<dynamic>? jsonList =
        dataController.retrieveData<List<dynamic>>('ekubCategories');

    if (jsonList != null) {
      return jsonList
          .map((json) => EqubCategorys.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()  async {
        await navigateToMainShell(context, initialIndex: 0);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => navigateToMainShell(context, initialIndex: 0),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black87,
              size: 18,
            ),
          ),
          title: Text(
            AppKeys.pendingEkubs.tr(context),
            style: AppTextStyles.poppins60014.copyWith(color: Colors.black87),
          ),
          actions: [
            if (!isLoading)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
                onPressed: () => fetchWaitingEkubs(),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && (payments == null || payments!.isEmpty)) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCircle(
              color: AppColors.primary,
              size: 50.0,
            ),
            SizedBox(height: 16),
            
          ],
        ),
      );
    }

    if (hasError && (payments == null || payments!.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins40016.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => fetchWaitingEkubs(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (payments != null && payments!.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchWaitingEkubs,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    textScaleFactor: 1.0,
                    AppKeys.noData.tr(context),
                    style: AppTextStyles.poppins50018.copyWith(color: Colors.grey[600]),
                  ),
                 
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => fetchWaitingEkubs(silent: true),
      displacement: 40,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: payments?.length ?? 0,
        itemBuilder: (context, index) {
          final item = payments?[index];
          return _buildPaymentCard(item);
        },
      ),
    );
  }

  Widget _buildPaymentCard(Payment? item) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Container(
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
                        item?.equb?.name ?? 'N/A',
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
            _buildDetailRow(
              label: AppKeys.totalAmount.tr(context),
              value: numberFormat.format(item?.amount ?? 0.0),
              valueStyle: AppTextStyles.sectionTitleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.vibrantGreen,
              ),
            ),
            SizedBox(height: 10.h),
            _buildDetailRow(
              label: AppKeys.ekubRound.tr(context),
              value: item?.round.toString() ?? 'N/A',
            ),
            SizedBox(height: 10.h),
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
            item?.picture != null
                ? _buildWaitingApprovalIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await UploadReceiptSheet.show(
                          context,
                          ekubAmount: numberFormat.format(item?.amount),
                          ekubId: item?.id ?? '',
                          joinOption: '100',
                        );
                        if (mounted) fetchWaitingEkubs(silent: true);
                      },
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
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.captionMuted),
        Text(
          value,
          style: valueStyle ??
              AppTextStyles.labelMedium.copyWith(color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildWaitingApprovalIndicator() {
    return Container(
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
            icon: const Icon(Icons.info_outline, color: AppColors.blue, size: 16),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(AppKeys.paymentInfo.tr(context)),
                    content: Text(AppKeys.youHaveAlreadySubmitted.tr(context)),
                    actions: [
                      TextButton(
                        child: Text(AppKeys.ok.tr(context)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
