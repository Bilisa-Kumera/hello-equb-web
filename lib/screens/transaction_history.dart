// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/transaction_history_model.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:intl/intl.dart';

import '../utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  @override
  TransactionHistoryState createState() => TransactionHistoryState();
}

class Equb {
  final String name;
  final String round;
  final double amount;
  final String paid;

  Equb({
    required this.name,
    required this.round,
    required this.amount,
    required this.paid,
  });
}

class EkubList {
  final String ekubName;
  final String ekubId;

  EkubList({required this.ekubName, required this.ekubId});

  factory EkubList.fromJson(Map<String, dynamic> json) {
    return EkubList(
      ekubName: json['name'] ?? 'N/A',
      ekubId: json['id'] ?? 'N/A',
    );
  }
}

class TransactionHistoryState extends State<TransactionHistory> {
  PaymentsResponse? paymentsResponse;

  Future<PaymentsResponse?> getTransactionHistory(
      String paymentMethod, String equbId) async {
    final Dio dio = Dio();
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = await dio.get(
        '$getTransactionHistoryUrl?equb=$equbId&paymentMethod=$paymentMethod',
        options: Options(headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        }),
      );

      if (response.statusCode == 200) {
        paymentsResponse = PaymentsResponse.fromJson(response.data);
        paymentsResponse?.paymentsMade.sort(
          (a, b) => (b.createdAt).compareTo(a.createdAt),
        );

        paymentsResponse?.paymentsReceived.sort(
          (a, b) => (b.createdAt).compareTo(a.createdAt),
        );

        return paymentsResponse;
      } else {}
    } catch (e) {}

    return null;
  }

  @override
  void initState() {
    super.initState();
    _ekubListFuture = getEkubList();
  }

  List<EkubList>? ekubLists;
  Future<List<EkubList>>? _ekubListFuture;

  Future<List<EkubList>> getEkubList() async {
    final Dio dio = Dio();
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response =
          await dio.get('$ekubsUrl?/${await SecureStorageHelper.getUserId()}',
              options: Options(headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $accessToken",
              }));

      if (response.statusCode == 200 || response.statusCode == 201) {
        List<dynamic> equbs = response.data['data']['equbs'];
        List<EkubList> ekubList = equbs.map((equb) {
          return EkubList.fromJson(equb);
        }).toList();

        ekubLists = ekubList;
        return ekubList;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  String selectedPayment = '';
  String selectedEkubId = '';
  String totalAmount = '0';
  bool isCredit = false;

  Widget _equbChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: selected
              ? AppTextStyles.labelSmall.copyWith(color: AppColors.primary)
              : AppTextStyles.captionMuted.copyWith(
                  color: Colors.grey.shade700,
                ),
        ),
      ),
    );
  }

  Future<String> getTotalAmount() async {
    await Future.delayed(const Duration(seconds: 2));
    double amount = isCredit
        ? double.tryParse(
                paymentsResponse?.totalReceived.toString() ?? '0.0') ??
            0.0
        : double.tryParse(paymentsResponse?.totalPaid.toString() ?? '0.0') ??
            0.0;
    return numberFormat.format(amount);
  }

  Widget _rowItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.captionMuted.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
              AppKeys.transactionHistory.tr(context),
              style: AppTextStyles.poppins60014,
            ),
            Text(
              AppKeys.sortOut.tr(context),
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppKeys.totalPaid.tr(context),
                      style: AppTextStyles.captionMuted.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    FutureBuilder<String>(
                      future: getTotalAmount(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: AppTextStyles.captionMuted,
                          );
                        } else if (snapshot.hasData) {
                          return Text(
                            snapshot.data!,
                            style: AppTextStyles.poppins70016,
                          );
                        } else {
                          return Text(
                            'No data available',
                            style: AppTextStyles.captionMuted,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            isCredit = false;
                          });
                        },
                        icon: Icon(
                          Icons.arrow_upward,
                          size: 20,
                          color: isCredit ? Colors.grey.shade400 : AppColors.red,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            isCredit = true;
                          });
                        },
                        icon: Icon(
                          Icons.arrow_downward,
                          size: 20,
                          color: isCredit
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (String value) {
                      setState(() {
                        selectedPayment = value;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return ['bankTransfer', 'telebirr', 'cbe', 'awash']
                          .map((String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(
                            choice,
                            style: AppTextStyles.labelSmall,
                          ),
                        );
                      }).toList();
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(
                            selectedPayment.isNotEmpty
                                ? (selectedPayment.length > 7
                                    ? selectedPayment.substring(0, 7)
                                    : selectedPayment)
                                : AppKeys.payment.tr(context),
                            style: AppTextStyles.captionMuted.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              FutureBuilder<List<EkubList>>(
                future: _ekubListFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }

                  final ekubList = snapshot.data ?? [];
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading equb list',
                      style: AppTextStyles.captionMuted,
                    );
                  }
                  if (ekubList.isEmpty) {
                    return Text(
                      AppKeys.noEkubs.tr(context),
                      style: AppTextStyles.captionMuted,
                    );
                  }

                  return SizedBox(
                    height: 36.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _equbChip(
                          label: AppKeys.all.tr(context),
                          selected: selectedEkubId.isEmpty,
                          onTap: () {
                            setState(() {
                              selectedEkubId = '';
                            });
                          },
                        ),
                        ...ekubList.map((ekub) {
                          return Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: _equbChip(
                              label: ekub.ekubName,
                              selected: selectedEkubId == ekub.ekubId,
                              onTap: () {
                                setState(() {
                                  selectedEkubId = ekub.ekubId;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 8.h),
              FutureBuilder<PaymentsResponse?>(
                future: getTransactionHistory(selectedPayment, selectedEkubId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.all(38.w),
                        child: SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        AppKeys.errorTryAgain.tr(context),
                        style: AppTextStyles.captionMuted,
                      ),
                    );
                  } else if (!snapshot.hasData ||
                      snapshot.data?.paymentsMade.isEmpty == true) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(58.w),
                        child: Text(
                          'No transaction history found',
                          style: AppTextStyles.captionMuted,
                        ),
                      ),
                    );
                  } else {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: isCredit
                          ? snapshot.data?.paymentsReceived.length ?? 0
                          : snapshot.data?.paymentsMade.length ?? 0,
                      separatorBuilder: (_, __) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final equb = isCredit
                            ? snapshot.data?.paymentsReceived[index]
                            : snapshot.data?.paymentsMade[index];
                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _rowItem(
                                AppKeys.ekubName.tr(context),
                                equb?.equb.name ?? 'N/A',
                              ),
                              _rowItem(
                                AppKeys.amount.tr(context),
                                numberFormat.format(
                                  double.parse(
                                      equb?.amount.toStringAsFixed(2) ?? '0'),
                                ),
                              ),
                              _rowItem(
                                AppKeys.paymentMethod.tr(context),
                                equb?.paymentMethod ?? 'N/A',
                              ),
                              _rowItem(
                                AppKeys.date.tr(context),
                                DateFormat('MMMM d, yyyy').format(
                                    equb?.createdAt ?? DateTime.now()),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
