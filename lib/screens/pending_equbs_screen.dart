import 'package:dio/dio.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/ekub_category_model.dart';
import 'package:ekubee/models/pending_payments.dart';
import 'package:ekubee/screens/home_screen.dart';
import 'package:ekubee/screens/my_other_ekubs.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:ekubee/utils/token_helper.dart';

import '../utils/dialog_screen.dart';
import '../utils/secure_storage.dart';

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
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(13)),
                border: Border.all(color: AppColors.lightBlueGray, width: 1),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActiveEqubsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppColors.black),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            textScaleFactor: 1.0,
            AppKeys.pendingEkubs.tr(context),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (!isLoading)
              IconButton(
                icon: const Icon(Icons.refresh),
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
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
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
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Card(
        color: AppColors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                label: AppKeys.ekubName.tr(context),
                value: item?.equb?.name ?? 'N/A',
                valueStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                label: AppKeys.totalAmount.tr(context),
                value: numberFormat.format(item?.amount ?? 0.0),
                valueStyle: const TextStyle(
                  color: AppColors.vibrantGreen,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                label: AppKeys.ekubRound.tr(context),
                value: item?.round.toString() ?? 'N/A',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                label: AppKeys.paymentStatus.tr(context),
                value: AppKeys.pending.tr(context),
                valueStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: 16),
              item?.picture != null
                  ? _buildWaitingApprovalIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: CustomTextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return MyDialog(
                                ekubAmount: numberFormat.format(item?.amount),
                                ekubId: item?.id ?? '',
                                joinOption: '100',
                              );
                            },
                          );
                        },
                        text: AppKeys.uploadReceipt.tr(context),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            textScaleFactor: 1.0,
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
              color: AppColors.neutralGray,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            textScaleFactor: 1.0,
            value,
            style: valueStyle ??
                const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingApprovalIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_top,
            color: AppColors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            AppKeys.waitingForApproval.tr(context),
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.blue,
              size: 20,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Row(
                      children: [
                        const Icon(Icons.info, color: AppColors.blue),
                        const SizedBox(width: 8),
                        Text(AppKeys.paymentInfo.tr(context)),
                      ],
                    ),
                    content: Text(
                      AppKeys.youHaveAlreadySubmitted.tr(context),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text(
                          AppKeys.ok.tr(context),
                          style: const TextStyle(color: AppColors.primary),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
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
