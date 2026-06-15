// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/ekub_category_model.dart';
import 'package:helloequb/models/financial_info.dart';
import 'package:helloequb/screens/my_other_ekubs.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/secure_storage.dart';

class WinningDialog extends StatefulWidget {
  const WinningDialog({
    super.key,
    required this.ekubId,
    required this.ekubAmount,
    required this.netLotteryAmount,
    required this.ekubName,
    required this.equberUserId,
    required this.serviceCharge,
    required this.bankAccounts,
    this.selectedAccount,
    required this.onAccountSelected,
    this.currentSpin = 1,
    this.totalSpins = 1,
    this.onNextWinner,
  });

  final String ekubId;
  final String ekubAmount;
  final String netLotteryAmount;
  final String ekubName;
  final String equberUserId;
  final String serviceCharge;
  final List<BankAccount> bankAccounts;
  final BankAccount? selectedAccount;
  final Function(BankAccount?) onAccountSelected;
  final int currentSpin;
  final int totalSpins;
  final VoidCallback? onNextWinner;

  @override
  State<WinningDialog> createState() => _WinningDialogState();
}

class _WinningDialogState extends State<WinningDialog> {
  late final ConfettiController _confettiController;
  final Dio dio = Dio();
  final DataController dataController = DataController();

  String selectedAccount = "";

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
    if (widget.selectedAccount != null) {
      selectedAccount =
          "${widget.selectedAccount!.bank.name} - ${widget.selectedAccount!.accountNumber}";
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<List<EqubCategorys>?> loadEkubCategories() async {
    final jsonList =
        dataController.retrieveData<List<dynamic>>('ekubCategories');

    if (jsonList != null) {
      return jsonList
          .map((json) => EqubCategorys.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return null;
  }

  Future<String?> getSelectedAccount() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return selectedAccount;
  }

  Future<void> _submitClaim() async {
    final selectedAcc = await getSelectedAccount();

    if (selectedAcc == null || selectedAcc.isEmpty) {
      return;
    }

    final bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
    try {
      final response = await dio.post(
        claimEqubUrl + widget.equberUserId,
        data: {"selectedBankAccount": selectedAcc},
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
          AppColors.primary,
        );
        await loadEkubCategories();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ActiveEqubsScreen(),
          ),
        );
      } else {
        CustomSnackBar.show(context, 'Submission failed', AppColors.red);
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        if (e.response!.statusCode == 400) {
          final responseData = json.decode(e.response.toString());
          final errorMessage = responseData['message'];

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(AppKeys.errorTryAgain.tr(context)),
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
  }

  @override
  Widget build(BuildContext context) {
    final hasNextWinner = widget.onNextWinner != null;
    final grossAmount = double.tryParse(widget.ekubAmount) ?? 0;
    final netAmount =
        (double.tryParse(widget.netLotteryAmount) ?? 0).toStringAsFixed(2);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 390,
            margin: const EdgeInsets.only(top: 34),
            padding: const EdgeInsets.fromLTRB(22, 58, 22, 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: SingleChildScrollView(
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Spin ${widget.currentSpin} / ${widget.totalSpins}',
                      textScaleFactor: 1.0,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Congratulations!',
                    textAlign: TextAlign.center,
                    textScaleFactor: 1.0,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Winner of ${widget.ekubName}',
                    textAlign: TextAlign.center,
                    textScaleFactor: 1.0,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black.withOpacity(0.72),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9F8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${numberFormat.format(grossAmount)} ETB',
                          textAlign: TextAlign.center,
                          textScaleFactor: 1.0,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AmountRow(
                          label: 'Service charge',
                          value: '${widget.serviceCharge}%',
                        ),
                        const SizedBox(height: 8),
                        _AmountRow(label: 'Net', value: '$netAmount ETB'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (widget.bankAccounts.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE6ECE9)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BankAccount>(
                          hint: Text(AppKeys.selectBankAccount.tr(context)),
                          value: widget.selectedAccount,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(14),
                          items: widget.bankAccounts.map((account) {
                            return DropdownMenuItem<BankAccount>(
                              value: account,
                              child: Text(
                                '${account.bank.name} - ${account.accountNumber}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (newAccount) {
                            setState(() {
                              selectedAccount =
                                  "${newAccount?.bank.name} - ${newAccount?.accountNumber}";
                            });
                            widget.onAccountSelected(newAccount);
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FutureBuilder<String?>(
                    future: getSelectedAccount(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SpinKitCircle(
                          color: AppColors.blue,
                          size: 30.0,
                        );
                      }
                      if (snapshot.hasError) {
                        return Text(AppKeys.errorTryAgain.tr(context));
                      }
                      final account = snapshot.data;
                      return account != null && account.isNotEmpty
                          ? Text(
                              '${AppKeys.selectedBank.tr(context)} $account',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13.sp),
                            )
                          : Text(AppKeys.noData.tr(context));
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitClaim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(AppKeys.claim.tr(context)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onNextWinner?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(hasNextWinner ? 'Next' : 'Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 86,
            height: 86,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset('assets/trophy.png', fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          textScaleFactor: 1.0,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black.withOpacity(0.58),
          ),
        ),
        Text(
          value,
          textScaleFactor: 1.0,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
