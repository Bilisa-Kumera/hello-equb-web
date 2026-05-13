// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/transaction_history_model.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:intl/intl.dart';

import '../utils/secure_storage.dart';

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
    final DataController dataController = DataController();
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
    getTransactionHistory('', '');
    getEkubList(payment: 'd', ekubId: 'd');
  }

  final DataController dataController = DataController();
  List<EkubList>? ekubLists;
  Future<List<EkubList>> getEkubList(
      {required String payment, required String ekubId}) async {
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
        // Parse the response data and extract the equbs list
        List<dynamic> equbs = response.data['data']['equbs'];

        // Map the list of JSON objects to a list of EkubList objects
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
  String selectedEkubName = '';
  String totalAmount = '0';
  bool isCredit = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 20),
          child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios)),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textScaleFactor: 1.0,
                    AppKeys.transactionHistory.tr(context),
                    style: TextStyle(
                        color: AppColors.mediumDarkGray,
                        fontWeight: FontWeight.w700,
                        fontSize: 20.sp,
                        fontFamily: 'Poppins'),
                  ),
                  Text(
                    textScaleFactor: 1.0,
                    AppKeys.sortOut.tr(context),
                    style: TextStyle(
                        color: AppColors.mediumDarkGray,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                        fontSize: 14.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 23.0, right: 23, top: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4.0, right: 4, top: 8),
                child: Container(
                    width: double.maxFinite,
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        color: AppColors.vibrantGreen),
                    height: 85,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          textScaleFactor: 1.0,
                          AppKeys.totalPaid.tr(context),
                          style: TextStyle(
                              color: AppColors.white,
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600),
                        ),
                        FutureBuilder<String>(
                            future: getTotalAmount(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: SpinKitCircle(
                                  color: AppColors.white,
                                  size: 30.0,
                                ));
                              } else if (snapshot.hasError) {
                                return Center(
                                    child: Text(
                                        textScaleFactor: 1.0,
                                        'Error: ${snapshot.error}'));
                              } else if (snapshot.hasData) {
                                return Text(
                                  textScaleFactor: 1.0,
                                  snapshot.data!,
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontFamily: 'Poppins',
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              } else {
                                return const Center(
                                    child: Text(
                                        textScaleFactor: 1.0,
                                        'No data available'));
                              }
                            })
                      ],
                    )),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toggle Buttons for isCredit
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 3.0),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              isCredit = false; // Display paymentsMade
                            });
                          },
                          icon: Icon(
                            Icons.arrow_upward,
                            color: isCredit
                                ? AppColors.grey
                                : AppColors.red, // Highlight active
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 2.0),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              isCredit = true;
                            });
                          },
                          icon: Icon(
                            Icons.arrow_downward,
                            color:
                                isCredit ? AppColors.primary : AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
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
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(textScaleFactor: 1.0, choice),
                              ),
                            );
                          }).toList();
                        },
                        child: Row(
                          children: [
                            Text(
                              textScaleFactor: 1.0,
                              selectedPayment.isNotEmpty
                                  ? (selectedPayment.length > 7
                                      ? selectedPayment.substring(0, 7)
                                      : selectedPayment)
                                  : AppKeys.payment.tr(context),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Ekub List Dropdown
                      FutureBuilder<List<EkubList>>(
                        future: getEkubList(ekubId: '', payment: ''),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(18.0),
                              child: SpinKitCircle(
                                color: AppColors.primary,
                                size: 30.0,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return const Text(
                              textScaleFactor: 1.0,
                              'Error loading equb list',
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Text(
                              textScaleFactor: 1.0,
                              AppKeys.noEkubs.tr(context),
                            );
                          } else {
                            List<EkubList> ekubList = snapshot.data!;
                            return PopupMenuButton<String>(
                              onSelected: (String value) {
                                EkubList? selectedEkub = ekubList.firstWhere(
                                  (ekub) => ekub.ekubName == value,
                                  orElse: () =>
                                      EkubList(ekubName: 'N/A', ekubId: 'N/A'),
                                );

                                setState(() {
                                  selectedEkubId = selectedEkub.ekubId;
                                  selectedEkubName = selectedEkub.ekubName;

                                  // Fetch transaction history
                                  getTransactionHistory(
                                      selectedPayment, selectedEkubId);
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return ekubList.map((EkubList ekub) {
                                  return PopupMenuItem<String>(
                                    value: ekub.ekubName,
                                    child: Container(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        textScaleFactor: 1.0,
                                        ekub.ekubName,
                                      ),
                                    ),
                                  );
                                }).toList();
                              },
                              child: Row(
                                children: [
                                  Text(
                                    textScaleFactor: 1.0,
                                    selectedEkubName.isNotEmpty
                                        ? (selectedEkubName.length > 8
                                            ? selectedEkubName.substring(0, 8)
                                            : selectedEkubName)
                                        : AppKeys.ekubs.tr(context),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              FutureBuilder<PaymentsResponse?>(
                future: getTransactionHistory(selectedPayment, selectedEkubId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.all(38.0),
                        child: SpinKitCircle(
                          color: AppColors.primary,
                          size: 50.0,
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          textScaleFactor: 1.0,
                          AppKeys.errorTryAgain.tr(context)),
                    );
                  } else if (!snapshot.hasData ||
                      snapshot.data?.paymentsMade.isEmpty == true) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(58.0),
                        child: Text(
                            textScaleFactor: 1.0,
                            'No transaction history found'),
                      ),
                    );
                  } else {
                    return Center(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: isCredit
                            ? snapshot.data?.paymentsReceived.length
                            : snapshot.data?.paymentsMade.length,
                        itemBuilder: (context, index) {
                          final equb = isCredit
                              ? snapshot.data?.paymentsReceived[index]
                              : snapshot.data?.paymentsMade[index];
                          return ListTile(
                            title: Container(
                              decoration: BoxDecoration(
                                color: AppColors.indigoOverlay05,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(8)),
                                border: Border.all(
                                  color: isCredit
                                      ? AppColors.primary
                                      : AppColors
                                          .red, // Assume paymentsMade are not "lottery"
                                ),
                              ),
                              child: ListTile(
                                title: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 8, top: 0),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            AppKeys.ekubName.tr(context),
                                            style: TextStyle(
                                              color: AppColors.darkGrayBlue,
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ),
                                        Text(
                                          textScaleFactor: 1.0,
                                          equb?.equb.name ?? 'N/A',
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.darkGrayBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 6.0, top: 15),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            AppKeys.amount.tr(context),
                                            style: TextStyle(
                                              color: AppColors.darkGrayBlue,
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15.0),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            numberFormat.format(
                                              double.parse(equb?.amount
                                                      .toStringAsFixed(2) ??
                                                  '0'),
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.darkGrayBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 6.0, top: 15),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            AppKeys.paymentMethod.tr(context),
                                            style: TextStyle(
                                              color: AppColors.darkGrayBlue,
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15.0),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            equb?.paymentMethod ?? 'N/A',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.darkGrayBlue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                              right: 6.0, top: 15),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            AppKeys.date.tr(context),
                                            style: TextStyle(
                                              color: AppColors.darkGrayBlue,
                                              fontFamily: 'Poppins',
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 15.0),
                                          child: Text(
                                            textScaleFactor: 1.0,
                                            DateFormat('MMMM d, yyyy').format(
                                                equb?.createdAt ??
                                                    DateTime.now()),
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: AppColors.darkGrayBlue,
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
                        },
                      ),
                    );
                  }
                },
              ),
              const SizedBox(
                height: 30,
              )
              // Align(
              //   alignment: Alignment.bottomCenter,
              //   child: CustomTextButton(
              //     onPressed: () => Navigator.pop(context),
              //     text: 'Back',
              //   ),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
