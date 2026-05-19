// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/utils/financial_dialog.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/financial_info.dart';
import 'package:helloequb/screens/guarantor_screen.dart';
import 'package:helloequb/screens/profile_screen.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/custom_progress_screen.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/app_localizations.dart';

import '../utils/secure_storage.dart';

class FinancialInformation extends StatefulWidget {
  final String? ekubName, ekubId;
  final int? ekubAmount, ekubersNumber, ekubCycle;
  final String? nextRoundDate;
  final String? nextRoundTime;
  final bool? ekubRequest;
  final String? nextRoundLotteryType;
  final String? ekubersUserId;
  final String serviceCharge;
  const FinancialInformation(
      {super.key,
      this.ekubAmount,
      this.ekubId,
      this.ekubName,
      this.ekubersNumber,
      this.ekubCycle,
      this.nextRoundDate,
      this.nextRoundTime,
      this.ekubRequest,
      this.nextRoundLotteryType,
      this.ekubersUserId,
      required this.serviceCharge});

  @override
  State<FinancialInformation> createState() => _FinancialInformationState();
}

class _FinancialInformationState extends State<FinancialInformation> {
  int? selectedBankIndex;
  final TextEditingController accountNumberController = TextEditingController();
  final TextEditingController accountHolderNameController = TextEditingController();

  List<String> banks = [];
  List bankIds = [];
  List bankNames = [];
  
  @override
  void initState() {
    super.initState();
    getListOfFinancialInfo();
    getBanks();
    _loadAccountInfo();
  }

  var accountInfo;
  ResponseData? responseData;
  final DataController dataController = DataController();
  final ApiService apiService = ApiService();
  final Dio _dio = Dio();
  bool isLoading = true;

  Future<void> getListOfFinancialInfo() async {
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    final data = await apiService.readAll(addFinancialUrl, bearerToken: accessToken);
    
    if (data != null && data['data']['bankAccounts'].length != 0) {
      final responseData = ResponseData.fromJson(data);
      
      if (mounted) {
        setState(() {
          Set<String> addedAccounts = Set();
          bankNames.clear();
          accountInfo = responseData.bankAccounts;

          for (var account in responseData.bankAccounts) {
            if (!addedAccounts.contains(account.accountName)) {
              bankNames.add(account.bank.name);
              addedAccounts.add(account.accountName);
            }
          }
        });
      }
    } else {
      if (mounted) {
        setState(() {
          accountInfo = [];
          bankNames.clear();
        });
      }
    }
  }

  Future<void> getBanks() async {
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
    final data = await apiService.readAll(banksUrl, bearerToken: accessToken);
    
    if (data != null && mounted) {
      setState(() {
        banks.clear();
        bankIds.clear();
        for (int i = 0; i < data['data']['banks'].length; i++) {
          banks.add(data['data']['banks'][i]['name']);
          bankIds.add(data['data']['banks'][i]['id']);
        }
      });
    }
  }

  Future<void> post(String endpoint, String id, Map<String, dynamic> data,
      {String? bearerToken}) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          CustomSnackBar.show(
              context, AppKeys.addedSuccessfully.tr(context), AppColors.primary);
          // Refresh data instead of navigating
          await getListOfFinancialInfo();
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
              context, AppKeys.errorTryAgain.tr(context), AppColors.red);
        }
      }
    } on DioException catch (error) {
      if (mounted) {
        if (error.response != null) {
          CustomSnackBar.show(
              context, AppKeys.errorTryAgain.tr(context), AppColors.red);
        } else {
          CustomSnackBar.show(
              context, AppKeys.enableInternet.tr(context), AppColors.red);
        }
      }
    } catch (error) {
      if (mounted) {
        CustomSnackBar.show(
            context, AppKeys.errorTryAgain.tr(context), AppColors.red);
      }
    }
  }

  void _showAddBankDialog() {
    // Reset controllers when opening dialog
    selectedBankIndex = null;
    accountHolderNameController.clear();
    accountNumberController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Text(
              textScaleFactor: 1.0,
              AppKeys.addFinancial.tr(context),
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold),
            ),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  textScaleFactor: 1.0,
                  AppKeys.selectBank.tr(context),
                  style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return DropdownButtonFormField<int>(
                      value: selectedBankIndex,
                      dropdownColor: AppColors.white,
                      decoration: InputDecoration(
                        hintText: AppKeys.selectBank.tr(context),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        filled: true,
                        fillColor: AppColors.grey50,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColors.darkOverlay.withOpacity(0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      items: List.generate(banks.length, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                              textScaleFactor: 1.0,
                              banks[index],
                              style: TextStyle(color: AppColors.black)),
                        );
                      }),
                      onChanged: (int? newValue) {
                        setDialogState(() {
                          selectedBankIndex = newValue;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  textScaleFactor: 1.0,
                  AppKeys.addAccountHolderName.tr(context),
                  style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountHolderNameController,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    filled: true,
                    fillColor: AppColors.grey50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.darkOverlay.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.black),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z\s]*$')),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  textScaleFactor: 1.0,
                  AppKeys.enterAccountNumber.tr(context),
                  style: TextStyle(
                      color: AppColors.black,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountNumberController,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    filled: true,
                    fillColor: AppColors.grey50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: AppColors.darkOverlay.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: const TextStyle(color: AppColors.black),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: TextButton(
                    onPressed: () async {
                      if (selectedBankIndex != null) {
                        // Show progress dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const WaitingProgressPage(),
                        );

                        String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
                        String userId = await SecureStorageHelper.getUserId() ?? '';

                        await post(
                            '$addFinancialUrl$userId',
                            userId,
                            {
                              "bankId": bankIds[selectedBankIndex!],
                              "accountName": accountHolderNameController.text,
                              "accountNumber": accountNumberController.text
                            },
                            bearerToken: accessToken);
                        
                        // Close progress dialog
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                        
                        // Close add dialog and refresh data
                        if (mounted && Navigator.canPop(dialogContext)) {
                          Navigator.of(dialogContext).pop();
                        }
                      } else {
                        CustomSnackBar.show(
                          context,
                          AppKeys.selectBank.tr(context),
                          AppColors.red,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      textScaleFactor: 1.0,
                      AppKeys.submit.tr(context),
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadAccountInfo() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateFinance(String id, String bankId, String accountName,
      String accountNumber) async {
    String accessToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = await _dio.patch(
        updateFinancialUrl + id,
        data: {
          "accountNumber": accountNumber,
          "bankId": bankId,
          "accountName": accountName
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            if (accessToken.isNotEmpty) "Authorization": "Bearer $accessToken",
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (mounted) {
          CustomSnackBar.show(
              context, AppKeys.addedSuccessfully.tr(context), AppColors.primary);
          // Refresh data instead of navigating
          await getListOfFinancialInfo();
        }
      } else {
        if (mounted) {
          CustomSnackBar.show(
              context, AppKeys.errorTryAgain.tr(context), AppColors.red);
        }
      }
    } on DioException catch (error) {
      if (mounted) {
        CustomSnackBar.show(
            context, AppKeys.errorTryAgain.tr(context), AppColors.red);
      }
    } catch (error) {
      if (mounted) {
        CustomSnackBar.show(
            context, AppKeys.errorTryAgain.tr(context), AppColors.red);
      }
    }
  }

  @override
  void dispose() {
    accountNumberController.dispose();
    accountHolderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBankDialog,
        label: Row(
          children: [
            const Icon(Icons.add, size: 23),
            SizedBox(width: 8.w),
            Text(
              textScaleFactor: 1.0,
              AppKeys.add.tr(context),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black87),
        ),
        title: Text(
          textScaleFactor: 1.0,
          AppKeys.financialInformation.tr(context),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  textScaleFactor: 1.0,
                  '2/2',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.14),
                      AppColors.primary.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.account_balance_outlined,
                          color: AppColors.primary),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            textScaleFactor: 1.0,
                            AppKeys.listOfBanks.tr(context),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black87,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            textScaleFactor: 1.0,
                            AppKeys.enterDetails.tr(context),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    (widget.ekubId?.isNotEmpty ?? false) &&
                            (widget.ekubersUserId?.isNotEmpty ?? false)
                        ? TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GuarantorScreen(
                                    ekubAmount: widget.ekubAmount,
                                    ekuberUserId: widget.ekubersUserId ?? '',
                                    ekubCycle: widget.ekubCycle,
                                    ekubId: widget.ekubId ?? '',
                                    ekubName: widget.ekubName,
                                    ekubRequest: widget.ekubRequest,
                                    ekubersNumber: widget.ekubersNumber,
                                    nextRoundDate: widget.nextRoundDate,
                                    nextRoundLotteryType:
                                        widget.nextRoundLotteryType,
                                    nextRoundTime: widget.nextRoundTime,
                                    serviceCharge: widget.serviceCharge,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              textScaleFactor: 1.0,
                              AppKeys.addGuarantee.tr(context),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              if (accountInfo != null && accountInfo.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: accountInfo.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          )
                        ],
                        border: Border.all(
                          color: AppColors.darkOverlay.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.credit_card,
                                color: AppColors.primary),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  textScaleFactor: 1.0,
                                  (accountInfo[index].accountName ?? '')
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.black87,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  textScaleFactor: 1.0,
                                  '${accountInfo[index].bank.name}  •  ${accountInfo[index].accountNumber}',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: AppColors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) {
                                  return FinancialDialog(
                                    title: AppKeys.editFinancial.tr(context),
                                    isUpdate: true,
                                    selectedBank:
                                        accountInfo[index].bank.name ?? '',
                                    accountHolderName:
                                        accountInfo[index].accountName ?? '',
                                    accountNumber:
                                        accountInfo[index].accountNumber ?? '',
                                    banks: banks,
                                    onSubmit: (String bankId,
                                        String accountName,
                                        String accountNumber) async {
                                      Navigator.pop(dialogContext);
                                      await updateFinance(
                                        accountInfo[index].id,
                                        bankId,
                                        accountName,
                                        accountNumber,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                          ),
                        ],
                      ),
                    );
                  },
                )
              else if (isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: SpinKitFadingCircle(
                      color: AppColors.primary,
                      size: 44.sp,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 42),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.account_balance_wallet_outlined,
                              color: AppColors.primary, size: 30),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          textScaleFactor: 1.0,
                          AppKeys.noData.tr(context),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          textScaleFactor: 1.0,
                          AppKeys.add.tr(context),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16.h),
              if (!((widget.ekubId?.isNotEmpty ?? false) &&
                  (widget.ekubersUserId?.isNotEmpty ?? false)))
                CustomTextButton(
                  text: AppKeys.saveAndSubmit.tr(context),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ),
                ),
              SizedBox(height: 90.h),
            ],
          ),
        ),
      ),
    );
  }
}
