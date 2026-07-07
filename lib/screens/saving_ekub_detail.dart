// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/saving_equbs.dart';
import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:helloequb/screens/payment_arrangement_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:intl/intl.dart';

import '../utils/secure_storage.dart';

class SavingEkubDetail extends StatefulWidget {
  final String savingEkubName, ekubId;
  final String ekubName;
  final int ekubAmount, ekubersNumber, ekubCycle;
  final String nextRoundDate;
  final String nextRoundTime;
  final bool ekubRequest;
  final String nextRoundLotteryType;
  final String serviceCharge;
  final String equbersId;

  const SavingEkubDetail(
      {super.key,
      required this.savingEkubName,
      required this.ekubAmount,
      required this.ekubId,
      required this.ekubName,
      required this.ekubersNumber,
      required this.ekubCycle,
      required this.nextRoundDate,
      required this.nextRoundTime,
      required this.ekubRequest,
      required this.equbersId,
      required this.nextRoundLotteryType,
      required this.serviceCharge});

  @override
  State<SavingEkubDetail> createState() => _SavingEkubDetailState();
}

class _SavingEkubDetailState extends State<SavingEkubDetail> {
  ApiResponses? equbResponse;
  bool isLoading = true;
  String? errorMessage;
  @override
  void initState() {
    super.initState();
    fetchEqubData();
  }

  final Dio dio = Dio();
  final DataController dataController = DataController();
  List<ListItems> listItemsss = [];

  Future<void> fetchEqubData() async {
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    setState(() {
      isLoading = true;
    });

    try {
      final response = await dio.get(
        getSavingEqubDetailUrl + widget.ekubId,
        data: {"equberId": widget.equbersId},
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          equbResponse = ApiResponses.fromJson(response.data);
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage =
              'Error: Unexpected response status code ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch data: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double calculatePercentagePaid(int totalPaid, int goal) {
    if (goal == 0) return 0.0; // Prevent division by zero
    return (totalPaid / goal) * 100;
  }

  String displayPercentage(int totalPaid, int goal) {
    final percentage = calculatePercentagePaid(totalPaid, goal);
    return '${percentage.toStringAsFixed(0)} %'; // Convert to integer and add % symbol
  }

  List<ListItem> listItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green800,
      appBar: AppBar(
        backgroundColor: AppColors.green800,
        elevation: 0,
        leading: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: InkWell(
                onTap: () => Navigator.pop(context),
                child:
                    const Icon(Icons.arrow_back_ios, color: AppColors.white)),
          ),
        ),
        title: Text(
          textScaleFactor: 1.0,
          widget.savingEkubName,
          style: TextStyle(
            color: AppColors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: SpinKitFadingCircle(
                color: AppColors.white,
                size: 50.0,
              ),
            )
          : errorMessage != null
              ? Center(child: Text(textScaleFactor: 1.0, errorMessage!))
              : equbResponse != null
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.green700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      textScaleFactor: 1.0,
                                      AppKeys.totalSavings.tr(context),
                                      style: TextStyle(
                                        color: AppColors.white60,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    Text(
                                      textScaleFactor: 1.0,
                                      equbResponse?.data?.payments?.equb
                                                  ?.goal ==
                                              0.0
                                          ? numberFormat.format(int.parse(widget
                                                  .ekubAmount
                                                  .toString()) *
                                              int.parse(widget.ekubersNumber
                                                  .toString()))
                                          : "Goal: ${numberFormat.format(equbResponse?.data?.payments?.equb?.goal)}",
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  textScaleFactor: 1.0,
                                  numberFormat
                                      .format(equbResponse
                                          ?.data?.payments?.equb?.totalPaid)
                                      .toString(),
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 36.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(8)),
                                        value: calculatePercentagePaid(
                                                equbResponse?.data?.payments?.equb
                                                        ?.totalPaid ??
                                                    0,
                                                equbResponse?.data?.payments
                                                            ?.equb?.goal !=
                                                        0.0
                                                    ? equbResponse
                                                            ?.data
                                                            ?.payments
                                                            ?.equb
                                                            ?.goal ??
                                                        0
                                                    : int.parse(widget
                                                            .ekubAmount
                                                            .toString()) *
                                                        int.parse(widget
                                                            .ekubersNumber
                                                            .toString())) /
                                            100,
                                        backgroundColor: AppColors.green400,
                                        color: AppColors.white,
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      textScaleFactor: 1.0,
                                      displayPercentage(
                                          equbResponse?.data?.payments?.equb
                                                  ?.totalPaid ??
                                              0,
                                          equbResponse?.data?.payments?.equb
                                                      ?.goal !=
                                                  0.0
                                              ? equbResponse?.data?.payments
                                                      ?.equb?.goal ??
                                                  0
                                              : int.parse(widget.ekubAmount
                                                      .toString()) *
                                                  int.parse(widget.ekubersNumber
                                                      .toString())),
                                      style: const TextStyle(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  textScaleFactor: 1.0,
                                  AppKeys.paymentHistory.tr(context),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.green900,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: equbResponse
                                        ?.data?.payments?.lotteries?.length,
                                    itemBuilder: (context, index) {
                                      return _buildTransactionItem(
                                          equbResponse!
                                                  .data
                                                  ?.payments
                                                  ?.lotteries?[index]
                                                  .lotteryNumber
                                                  .toString() ??
                                              '',
                                          "+${numberFormat.format(equbResponse!.data?.payments?.lotteries?[index].totalPaid)} ETB",
                                          DateFormat('dd-m-yyy').format(
                                              equbResponse!
                                                      .data
                                                      ?.payments
                                                      ?.lotteries?[index]
                                                      .lastPaidOn ??
                                                  DateTime.now()),
                                          AppColors.green);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Add Savings Button
                        Container(
                          padding: const EdgeInsets.all(20),
                          color: AppColors.white,
                          child: TextButton(
                            onPressed: () {
                              double expectedAmount = 0;
                              listItems.clear();
                              listItemsss.clear();

                              for (var item
                                  in equbResponse?.data?.payments?.lotteries ??
                                      []) {
                                expectedAmount = expectedAmount +
                                    double.parse(equbResponse
                                            ?.data?.payments?.equb?.equbAmount
                                            .toString() ??
                                        '');
                                listItemsss.add(
                                  ListItems(
                                    userIds: item.equberUserId,
                                    title: item.lotteryNumber ??
                                        '', // Ensure title is set to lottery number
                                    subtitle: equbResponse
                                            ?.data?.payments?.equb?.equbAmount
                                            .toString() ??
                                        '', // Convert equbAmount to a string for subtitle
                                  ),
                                );
                                listItems.add(
                                  ListItem(
                                    title: item.lotteryNumber ??
                                        '', // Ensure title is set to lottery number
                                    subtitle: equbResponse
                                            ?.data?.payments?.equb?.equbAmount
                                            .toString() ??
                                        '', // Convert equbAmount to a string for subtitle
                                  ),
                                );
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentArragement(
                                      ekubName: widget.ekubName,
                                      ekubRound: "0",
                                      ekubId: widget.ekubId,
                                      ekubAmount: "100",
                                      joinOption: ' ',
                                      joinAmount: "100",
                                      type: "payment",
                                      selectedJoinOption: listItems,
                                      selectedJoinOptions: listItemsss,
                                      expectedAmount: expectedAmount),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.green900,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Center(
                              child: Text(
                                textScaleFactor: 1.0,
                                AppKeys.addNewSaving.tr(context),
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Text(
                      textScaleFactor: 1.0,
                      AppKeys.noEkubs.tr(context),
                    )),
    );
  }

  Widget _buildTransactionItem(
      String title, String amount, String date, Color amountColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          textScaleFactor: 1.0,
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          textScaleFactor: 1.0,
          date,
          style: const TextStyle(color: AppColors.grey600),
        ),
        trailing: Text(
          textScaleFactor: 1.0,
          amount,
          style: TextStyle(
            color: amountColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
