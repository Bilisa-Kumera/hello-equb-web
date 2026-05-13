// ignore_for_file: use_build_context_synchronously

import 'package:ekubee/utils/colors_constant.dart';
import 'package:ekubee/utils/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart'; // Add this for Dio usage
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/logic/check_network.dart';
import 'package:ekubee/models/ekub_category_model.dart';
import 'dart:convert';

import 'package:ekubee/models/financial_info.dart';
import 'package:ekubee/screens/my_equb_screen.dart';
import 'package:ekubee/screens/my_other_ekubs.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart'; // For JSON decoding

class WinningDialog extends StatefulWidget {
  final String ekubId;
  final String ekubAmount;
  final String netLotteryAmount;
  final String ekubName;
  final String equberUserId;
  final String serviceCharge;
  final List<BankAccount> bankAccounts;
  final BankAccount? selectedAccount;
  final Function(BankAccount?) onAccountSelected;

  WinningDialog({
    required this.ekubId,
    required this.ekubAmount,
    required this.netLotteryAmount,
    required this.ekubName,
    required this.equberUserId,
    required this.serviceCharge,
    required this.bankAccounts,
    this.selectedAccount,
    required this.onAccountSelected,
  });

  @override
  _WinningDialogState createState() => _WinningDialogState();
}

class _WinningDialogState extends State<WinningDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  final Dio dio = Dio();
  final DataController dataController = DataController();
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

  String selectedAccount = "";
  Future<String?> getSelectedAccount() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate a delay
    return selectedAccount;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 30,
                      gravity: 0.3,
                      colors: const [
                        AppColors.primary,
                        AppColors.blue,
                        AppColors.orange,
                        AppColors.pink,
                      ],
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/trophy.png',
                        fit: BoxFit.fitHeight,
                        width: double.infinity,
                        height: 100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '🎉 Congratulations! 🎉',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Winner of ${widget.ekubName}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '\n${numberFormat.format(double.tryParse(widget.ekubAmount))} ETB\n',
                            style: TextStyle(
                              fontSize: 25.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(
                            text:
                                '\nService Charge: ${widget.serviceCharge}%\n',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.normal,
                              color: AppColors.black,
                            ),
                          ),
                          TextSpan(
                            text:
                                '\nNet: ${(double.tryParse(widget.netLotteryAmount)?.toStringAsFixed(2))} ETB\n',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.normal,
                              color: AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.bankAccounts.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 10),
                        child: DropdownButton<BankAccount>(
                          hint: Text(AppKeys.selectBankAccount.tr(context)),
                          value: widget.selectedAccount,
                          isExpanded: true,
                          items: widget.bankAccounts.map((BankAccount account) {
                            return DropdownMenuItem<BankAccount>(
                              value: account,
                              child: Text(
                                  '${account.bank.name} - ${account.accountNumber}'),
                            );
                          }).toList(),
                          onChanged: (BankAccount? newAccount) {
                            setState(() {
                              selectedAccount =
                                  "${newAccount?.bank.name} - ${newAccount?.accountNumber}";
                            });
                          },
                        ),
                      ),
                    FutureBuilder<String?>(
                      future:
                          getSelectedAccount(), // Call the asynchronous function
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Show a spinner while waiting for data
                          return const SpinKitCircle(
                            color: AppColors.blue,
                            size: 50.0,
                          );
                        } else if (snapshot.hasError) {
                          // Handle any errors
                          return Text(AppKeys.errorTryAgain.tr(context));
                        } else if (snapshot.hasData) {
                          // Show selected account if available
                          String? account = snapshot.data;
                          return account != null
                              ? Text(
                                  '${AppKeys.selectedBank.tr(context)} $account',
                                  style: TextStyle(fontSize: 14.sp),
                                )
                              : Text(AppKeys.noData.tr(context));
                        } else {
                          // Handle the case where no data is returned
                          return Text(AppKeys.noData.tr(context));
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        String? selctedAcc = await getSelectedAccount();

                        if (selctedAcc == '' || selctedAcc == null) {
                          return;
                        }
                        String bearerToken =
                            await SecureStorageHelper.getAccessToken() ?? '';
                        try {
                          final response = await dio.post(
                            claimEqubUrl + widget.equberUserId,
                            data: {"selectedBankAccount": selctedAcc},
                            options: Options(
                              headers: {
                                "Authorization": "Bearer $bearerToken",
                              },
                            ),
                          );

                          if (response.statusCode == 200) {
                            Navigator.of(context).pop();
                            CustomSnackBar.show(
                                context,
                                'Successfully sent to admin',
                                AppColors.primary);
                            final ekubCategorys = await loadEkubCategories();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ActiveEqubsScreen(),
                              ),
                            );
                          } else {
                            CustomSnackBar.show(
                                context, 'Submission failed', AppColors.red);
                          }
                        } catch (e) {
                          if (e is DioException && e.response != null) {
                            if (e.response!.statusCode == 400) {
                              Map<String, dynamic> responseData =
                                  json.decode(e.response.toString());
                              String errorMessage = responseData['message'];

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title:
                                      Text(AppKeys.errorTryAgain.tr(context)),
                                  content: Text(errorMessage),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text(AppKeys.ok.tr(context)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: AppColors.primary,
                        shadowColor: AppColors.primary,
                        elevation: 8,
                        textStyle: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(
                        AppKeys.claim.tr(context),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
