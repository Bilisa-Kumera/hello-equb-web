import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/waiting_payment.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/core/cbebirr_plus/cbebirr_plus_bridge.dart';
import 'package:helloequb/core/telebirr_service.dart';
import 'package:helloequb/utils/secure_storage.dart';

import 'package:helloequb/screens/join_ekub_detail.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'pending_equbs_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String? ekubId;
  final String? ekubName;
  final String? ekubRound;
  final String? ekubAmount;
  final String? type;
  final String? joinAmount;
  final List<ListItem>? selectedJoinOption;
  final List<ListItems>? selectedJoinOptions;
  final String? joinOption;

  const PaymentScreen({
    super.key,
    this.ekubId,
    this.ekubName,
    this.ekubRound,
    this.ekubAmount,
    this.type,
    this.joinAmount,
    this.selectedJoinOption,
    this.selectedJoinOptions,
    this.joinOption,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int? selectedIndex;
  String? selectedPaymentMethodId;
  bool _isProcessing = false;
  bool _isSubmitting = false;
  bool _isInsideCbeBirrPlus = false;
  bool isLoading = false;
  final phoneController = TextEditingController();

  late TextEditingController _amountController;
  late final CbeBirrPlusBridge _cbeBirrPlusBridge;
  final TelebirrService _telebirrService = TelebirrService();
  final DataController dataController = DataController();
  StreamSubscription? _paymentResultSub;

  String phoneNumber = '';
  String receiveCode = '';
  String _cbeBirrPlusDisplayToken = '';
  String telebirrAppId = '';
  String telebirrAppSecret = '';
  String telebirrShortCode = '';

  bool get _isPaymentType =>
      (widget.type ?? '').trim().toLowerCase() == 'payment';

  bool get _showCbeBirrPlusToken =>
      _isInsideCbeBirrPlus && selectedPaymentMethodId == 'cbe';

  String _resolveCbeBirrPlusLaunchToken() =>
      _cbeBirrPlusBridge.launchToken?.trim() ?? '';

  void _refreshCbeBirrPlusDisplayToken() {
    _cbeBirrPlusDisplayToken = _resolveCbeBirrPlusLaunchToken();
  }

  Future<void> _copyCbeBirrPlusToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppKeys.copiedToClipBoard.tr(context)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildCbeBirrPlusTokenCard() {
    final token = _cbeBirrPlusDisplayToken.trim();
    final hasToken = token.isNotEmpty;

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppKeys.cbeBirrPlusTokenLabel.tr(context),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 12.h),
            if (hasToken)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        token,
                        style: TextStyle(
                          fontSize: 13.sp,
                          height: 1.4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppKeys.copiedToClipBoard.tr(context),
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyCbeBirrPlusToken(token),
                    ),
                  ],
                ),
              )
            else
              Text(
                AppKeys.cbeBirrPlusTokenUnavailable.tr(context),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.red.shade700,
                  height: 1.35,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _visiblePaymentOptions {
    if (!_isInsideCbeBirrPlus) return paymentOptions;
    return paymentOptions
        .where((option) => option['id'] != 'telebirr')
        .toList(growable: false);
  }

  final List<Map<String, dynamic>> paymentOptions = [
    {
      'id': 'bankTransfer',
      'textKey': AppKeys.paymentMethodBankTransfer,
      'subtitleKey': AppKeys.paymentMethodBankTransferSubtitle,
      'icon': Icons.account_balance_wallet_outlined,
      'imagePath': '',
      'color': Colors.blue.shade50,
      'iconColor': Colors.blue.shade700,
    },
    {
      'id': 'telebirr',
      'textKey': AppKeys.paymentMethodTelebirr,
      'subtitleKey': AppKeys.paymentMethodTelebirrSubtitle,
      'icon': Icons.phone_android,
      'imagePath': 'assets/telebirr.png',
      'color': Colors.orange.shade50,
      'iconColor': Colors.orange.shade700,
    },
    {
      'id': 'cbe',
      'textKey': AppKeys.paymentMethodCbebirr,
      'subtitleKey': AppKeys.paymentMethodCbebirrSubtitle,
      'icon': Icons.phone_android,
      'imagePath': 'assets/cbe.png',
      'color': Colors.orange.shade50,
      'iconColor': Colors.orange.shade700,
    },
  ];

  @override
  void initState() {
    super.initState();
    _cbeBirrPlusBridge = createCbeBirrPlusBridge();
    _detectCbeBirrPlus();
    _amountController = TextEditingController(
      text:
          '${numberFormat.format(double.tryParse(widget.ekubAmount?.toString().replaceAll(',', '') ?? '0') ?? 0)} Birr',
    );
  }

  void _subscribeToTelebirrPaymentResults() {
    _paymentResultSub = TelebirrService.paymentResultStream.listen((result) {
      final code = result['code'];
      final errMsg = result['errMsg'];
      _showDialog(
        code == 0
            ? AppKeys.paymentSuccess.tr(context)
            : AppKeys.paymentFailed.tr(context),
        errMsg != null ? errMsg.toString() : AppKeys.unknownResult.tr(context),
      );
    });
  }

  Future<void> _detectCbeBirrPlus() async {
    final ok = await _cbeBirrPlusBridge.waitUntilAvailable(
      timeout: const Duration(seconds: 2),
      pollInterval: const Duration(milliseconds: 140),
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        _isInsideCbeBirrPlus = true;
        if (selectedPaymentMethodId == 'telebirr') {
          selectedPaymentMethodId = null;
          selectedIndex = null;
        } else if (selectedPaymentMethodId != null) {
          final visibleIndex = _visiblePaymentOptions.indexWhere(
            (option) => option['id'] == selectedPaymentMethodId,
          );
          selectedIndex = visibleIndex >= 0 ? visibleIndex : null;
        }
      });
      return;
    }

    _subscribeToTelebirrPaymentResults();
  }

  @override
  void dispose() {
    _paymentResultSub?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleBankTransfer() async {
    setState(() => _isSubmitting = true);

    if (!_isPaymentType) {
      await _submitJoinRequest(paymentMethod: 'bankTransfer');
    } else {
      await _submitLotteryPayment(paymentMethod: 'bankTransfer');
    }

    setState(() => _isSubmitting = false);
  }

  // --- Logic: Telebirr ---
  Future<void> _handleTelebirr() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPhonePaymentBottomSheet(
        paymentMethodId: 'telebirr',
        paymentMethodLabel: AppKeys.paymentMethodTelebirr.tr(context),
      ),
    );
  }

  Future<void> _handleCbe() async {
    if (_isInsideCbeBirrPlus) {
      await _handleCbeBirrPlusPayment();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPhonePaymentBottomSheet(
        paymentMethodId: 'cbe',
        paymentMethodLabel: AppKeys.paymentMethodCbebirr.tr(context),
      ),
    );
  }

  Future<void> _handleCbeBirrPlusPayment() async {
    setState(() => _isProcessing = true);

    try {
      _refreshCbeBirrPlusDisplayToken();
      final launchToken = _cbeBirrPlusDisplayToken.trim();

      if (launchToken.isEmpty) {
        if (mounted) {
          setState(() {});
          _showDialog(
            AppKeys.cannotContinue.tr(context),
            AppKeys.cbeBirrPlusTokenUnavailable.tr(context),
          );
        }
        return;
      }

      await _getReceiveCode(paymentMethod: 'cbe');

      final paymentToken =
          receiveCode.trim().isNotEmpty ? receiveCode.trim() : launchToken;

      if (mounted && paymentToken != _cbeBirrPlusDisplayToken) {
        setState(() => _cbeBirrPlusDisplayToken = paymentToken);
      }

      final sent = await _cbeBirrPlusBridge.sendPaymentToken(paymentToken);
      if (!mounted) return;

      if (!sent) {
        _showDialog(
          AppKeys.cannotContinue.tr(context),
          AppKeys.errorTryAgain.tr(context),
        );
        return;
      }

      CustomSnackBar.show(
        context,
        AppKeys.cbeUssdEnterPinMessage.tr(context),
        AppColors.primary,
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _processPhonePayment({
    required String phone,
    required String paymentMethod,
  }) async {
    Navigator.pop(context);

    setState(() => _isProcessing = true);

    try {
      if (paymentMethod == 'telebirr') {
        await _getReceiveCode(
          phoneNumber: phone,
          paymentMethod: paymentMethod,
        );

        if (receiveCode.isEmpty) {
          _showDialog(
            AppKeys.cannotContinue.tr(context),
            AppKeys.receiveCodeNotAvailable.tr(context),
          );
          setState(() => _isProcessing = false);
          return;
        }

        await _startTelebirrPayment();
      } else {
        if (!_isPaymentType) {
          await _submitJoinRequest(
            phoneNumber: phone,
            paymentMethod: paymentMethod,
          );
        } else {
          await _submitLotteryPayment(
            paymentMethod: paymentMethod,
            phoneNumber: phone,
          );
        }
      }
    } catch (e) {
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _getReceiveCode({
    String? phoneNumber,
    required String paymentMethod,
  }) async {
    final useCbeBirrPlusJoinEndpoint =
        !_isPaymentType && paymentMethod == 'cbe' && _isInsideCbeBirrPlus;
    final miniAppPhoneNumber = phoneNumber ??
        dataController.retrieveData<String>('phoneNumber')?.trim();
    final miniAppToken = _cbeBirrPlusBridge.launchToken?.trim();

    final data = <String, dynamic>{
      "paidAmount":
          double.tryParse((widget.ekubAmount ?? '0.0').replaceAll(',', '')) ??
              0,
      "paymentMethod": paymentMethod,
      if (phoneNumber != null) "phoneNumber": phoneNumber,
      if (useCbeBirrPlusJoinEndpoint &&
          miniAppPhoneNumber != null &&
          miniAppPhoneNumber.isNotEmpty)
        "phoneNumber": miniAppPhoneNumber,
      if (useCbeBirrPlusJoinEndpoint &&
          miniAppToken != null &&
          miniAppToken.isNotEmpty)
        "token": miniAppToken,
    };

    if (_isPaymentType) {
      final List<Map<String, dynamic>> lottery = [];
      for (var item in widget.selectedJoinOptions ?? []) {
        lottery.add({
          "id": item.userIds,
          "paidAmount": double.tryParse(item.subtitle.replaceAll(',', '')) ?? 0,
        });
      }
      data["lottery"] = lottery;
    } else {
      final List<Map<String, dynamic>> equbers = [];
      for (var item in widget.selectedJoinOption ?? []) {
        final double stake = _calculateStake(item.title);
        final double paid =
            double.tryParse(item.subtitle.replaceAll(',', '')) ?? 0;
        equbers.add({"stake": stake, "paidAmount": paid});
      }
      data["equbers"] = equbers;
    }

    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    final String url = (_isPaymentType
            ? makePaymentUrl
            : useCbeBirrPlusJoinEndpoint
                ? joinMiniAppEkubUrl
                : joinEkubUrl) +
        (widget.ekubId ?? '');

    debugPrint('Payment request url: $url');
    debugPrint('Payment request body: ${jsonEncode(data)}');

    try {
      final Dio dio = Dio();
      final response = await dio.post(
        url,
        data: data,
        options: Options(headers: {"Authorization": "Bearer $bearerToken"}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data['data'];

        final dynamic orderResult = responseData?['orderResult'];
        final String rawRequest =
            (orderResult?['raw_request'] ?? '').toString();

        String rawParam(String key) {
          if (rawRequest.isEmpty) return '';
          for (final part in rawRequest.split('&')) {
            final int eq = part.indexOf('=');
            if (eq <= 0) continue;
            final String k = part.substring(0, eq);
            if (k != key) continue;
            return part.substring(eq + 1);
          }
          return '';
        }

        final String appIdFromRaw = rawParam('appid');
        final String shortCodeFromRaw = rawParam('merch_code');
        final String cbePaymentToken = (responseData?['token'] ??
                responseData?['paymentToken'] ??
                responseData?['processedPaymentToken'] ??
                responseData?['processedPaymentInfoToken'] ??
                orderResult?['token'] ??
                orderResult?['paymentToken'] ??
                orderResult?['processedPaymentToken'] ??
                '')
            .toString();

        final newReceiveCode = (responseData?['receiveCode'] ??
                orderResult?['receiveCode'] ??
                cbePaymentToken)
            .toString();
        final newAppId = (appIdFromRaw.isNotEmpty
                ? appIdFromRaw
                : (responseData?['appId'] ?? orderResult?['appId'] ?? ''))
            .toString();
        final newAppSecret =
            (responseData?['appSecret'] ?? orderResult?['appSecret'] ?? '')
                .toString();
        final newShortCode = (shortCodeFromRaw.isNotEmpty
                ? shortCodeFromRaw
                : (responseData?['shortCode'] ??
                    orderResult?['shortCode'] ??
                    ''))
            .toString();

        setState(() {
          receiveCode = newReceiveCode;
          telebirrAppId = newAppId;
          telebirrAppSecret = newAppSecret;
          telebirrShortCode = newShortCode;
        });
      } else {}
    } on DioError catch (e) {
      _handleDioError(e);
    }
  }

  Future<void> _submitJoinRequest({
    String? phoneNumber,
    required String paymentMethod,
  }) async {
    try {
      await _getReceiveCode(
          phoneNumber: phoneNumber, paymentMethod: paymentMethod);

      if (paymentMethod == 'cbe') {
        CustomSnackBar.show(
          context,
          AppKeys.cbeUssdEnterPinMessage.tr(context),
          AppColors.primary,
        );
        return;
      }

      CustomSnackBar.show(
        context,
        AppKeys.pleaseUploadYourPayment.tr(context),
        AppColors.primary,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WaitingEkubs()),
      );
    } catch (e) {}
  }

  Future<void> _submitLotteryPayment({
    required String paymentMethod,
    String? phoneNumber,
  }) async {
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    List<Map<String, dynamic>> lottery = [];

    for (var item in widget.selectedJoinOptions ?? []) {
      lottery.add({
        "id": item.userIds,
        "paidAmount": double.tryParse(item.subtitle) ?? 0,
      });
    }

    final data = {
      "paidAmount": double.tryParse(widget.ekubAmount ?? '0.0') ?? 0,
      "paymentMethod": paymentMethod,
      "lottery": lottery,
      if (phoneNumber != null) "phoneNumber": phoneNumber,
    };

    final String url = makePaymentUrl + (widget.ekubId ?? '');

    debugPrint('Payment request url: $url');
    debugPrint('Payment request body: ${jsonEncode(data)}');

    try {
      final Dio dio = Dio();
      final response = await dio.post(
        url,
        data: data,
        options: Options(headers: {"Authorization": "Bearer $bearerToken"}),
      );
      if (response.statusCode == 200) {
        if (paymentMethod == 'cbe') {
          CustomSnackBar.show(
            context,
            AppKeys.cbeUssdEnterPinMessage.tr(context),
            AppColors.primary,
          );
          return;
        }

        CustomSnackBar.show(
          context,
          AppKeys.pleaseUploadYourPayment.tr(context),
          AppColors.primary,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingEkubsPayment(
              ekubId: widget.ekubId ?? '',
            ),
          ),
        );
      } else {
        setState(() => isLoading = false);
        CustomSnackBar.show(
            context, AppKeys.errorTryAgain.tr(context), AppColors.red);
      }
    } on DioError catch (e) {
      setState(() => isLoading = false);
      if (e.response?.statusCode == 401) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreenWithPin(phoneNumber: '')),
        );
      } else {
        CustomSnackBar.show(
            context, AppKeys.errorTryAgain.tr(context), AppColors.red);
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      CustomSnackBar.show(
          context, AppKeys.errorTryAgain.tr(context), AppColors.red);
    }
  }

  Future<void> _startTelebirrPayment() async {
    final String shortCode = telebirrShortCode;
    final String appId = telebirrAppId;
    final String appSecret = telebirrAppSecret;

    await _telebirrService.initiatePayment(
      appId: appId,
      shortCode: shortCode,
      appKey: appSecret,
      totalAmount: _amountController.text.replaceAll('Birr', '').trim(),
      receiveCode: receiveCode,
    );
  }

  double _calculateStake(String title) {
    if (title == '1') return 100;
    if (title == '1/2') return 50;
    if (title.contains('/')) {
      var parts = title.split('/');
      return 100 * (double.parse(parts[0]) / double.parse(parts[1]));
    }
    return 100;
  }

  void _handleDioError(DioError e) {
    if (e.response?.statusCode == 401) {
      CustomSnackBar.show(
          context, AppKeys.tokenExpired.tr(context), AppColors.red);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreenWithPin(phoneNumber: '')));
    } else {
      CustomSnackBar.show(
          context, AppKeys.errorTryAgain.tr(context), AppColors.red);
    }
  }

  void _showDialog(String title, String message) {
    final bool isSuccess = (title == AppKeys.paymentSuccess.tr(context)) ||
        title.toLowerCase().contains("success");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red, size: 28),
            SizedBox(width: 10.w),
            Text(title,
                style: TextStyle(
                    color: isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false),
            child: Text(AppKeys.ok.tr(context)),
          )
        ],
      ),
    );
  }

  Widget _buildPhonePaymentBottomSheet({
    required String paymentMethodId,
    required String paymentMethodLabel,
  }) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
                '${AppKeys.confirm.tr(context)} $paymentMethodLabel ${AppKeys.payment.tr(context)}',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text(AppKeys.enterBeneficiaryPhoneNumber.tr(context),
                style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
            SizedBox(height: 20.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: IntlPhoneField(
                controller: phoneController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: InputBorder.none,
                  hintText: '*** ** ** **',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                initialCountryCode: 'ET',
                disableLengthCheck: true,
                onChanged: (phone) => phoneNumber = phone.completeNumber,
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppKeys.totalAmount.tr(context),
                      style: TextStyle(
                          fontSize: 14.sp, color: Colors.grey.shade600)),
                  Text(
                    "${widget.ekubAmount ?? '0'} ${AppKeys.currencyBirr.tr(context)}",
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (phoneController.text.isNotEmpty) {
                    _processPhonePayment(
                      phone: phoneNumber,
                      paymentMethod: paymentMethodId,
                    );
                  }
                },
                child: Text(AppKeys.makePayment.tr(context),
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  CompanyBankAccountsResponse? companyBankAccountsResponse;

  Future<List<CompanyBankAccount>> getCompanyBanks() async {
    final Dio dio = Dio();

    try {
      final response = await dio.get(companyBankUrl);

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        companyBankAccountsResponse =
            CompanyBankAccountsResponse.fromJson(jsonResponse);
        return companyBankAccountsResponse!.data.companyBankAccounts;
      }
    } catch (e) {}
    return [];
  }

  void showBankAccountsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<CompanyBankAccount>>(
          future: getCompanyBanks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(child: Text(AppKeys.noData.tr(context))),
              );
            }

            final banks = snapshot.data!;

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// HEADER
                  Row(
                    children: [
                      const Icon(Icons.account_balance, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        AppKeys.companyBankAccounts.tr(context),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: banks.length,
                    itemBuilder: (context, index) {
                      final bank = banks[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            /// BANK INFO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bank.accountName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bank.accountNumber,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// COPY BUTTON
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: bank.accountNumber),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        AppKeys.copiedToClipBoard.tr(context)),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );

                                Navigator.pop(context);
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
        ),
        title: Text(
          AppKeys.payment.tr(context),
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.groups,
                                color: AppColors.primary, size: 20),
                          ),
                          SizedBox(width: 12.w),
                          Text(AppKeys.ekubDetail.tr(context),
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildDetailRow(
                          AppKeys.ekubName.tr(context),
                          widget.ekubName ?? AppKeys.notAvailable.tr(context),
                          Icons.group),
                      SizedBox(height: 12.h),
                      _buildDetailRow(AppKeys.ekubRound.tr(context),
                          widget.ekubRound ?? '1', Icons.repeat),
                      SizedBox(height: 12.h),
                      _buildAmountRow(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(AppKeys.pleaseChoosePaymentMethod.tr(context),
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
              SizedBox(height: 12.h),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _visiblePaymentOptions.length,
                itemBuilder: (context, index) {
                  final option = _visiblePaymentOptions[index];
                  final optionId = option['id'] as String;
                  final isSelected = selectedPaymentMethodId == optionId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                        selectedPaymentMethodId = optionId;
                        if (optionId == 'cbe' && _isInsideCbeBirrPlus) {
                          _refreshCbeBirrPlusDisplayToken();
                        }
                      });
                      if (optionId == 'bankTransfer') {
                        showBankAccountsBottomSheet(context);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (option['color'] as Color).withOpacity(0.3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? option['iconColor']
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: option['color'],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: option['imagePath'] != ''
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(option['imagePath'],
                                        fit: BoxFit.cover),
                                  )
                                : Icon(option['icon'],
                                    color: option['iconColor']),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (option['textKey'] as String).tr(context),
                                  style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  (option['subtitleKey'] as String).tr(context),
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? option['iconColor']
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              color: isSelected
                                  ? option['iconColor']
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_showCbeBirrPlusToken) ...[
                SizedBox(height: 16.h),
                _buildCbeBirrPlusTokenCard(),
              ],
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  onPressed: (_isSubmitting ||
                          _isProcessing ||
                          selectedPaymentMethodId == null ||
                          (_showCbeBirrPlusToken &&
                              _cbeBirrPlusDisplayToken.trim().isEmpty))
                      ? null
                      : () {
                          final selectedPaymentMethod =
                              selectedPaymentMethodId!;

                          if (selectedPaymentMethod == 'bankTransfer') {
                            _handleBankTransfer();
                          } else if (selectedPaymentMethod == 'telebirr') {
                            _handleTelebirr();
                          } else if (selectedPaymentMethod == 'cbe') {
                            _handleCbe();
                          }
                        },
                  child: _isSubmitting || _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          AppKeys.lblContinue.tr(context),
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        SizedBox(width: 8.w),
        Text(label,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAmountRow() {
    return Row(
      children: [
        const Icon(Icons.attach_money, size: 18, color: Colors.grey),
        SizedBox(width: 8.w),
        Text(AppKeys.ekubAmount.tr(context),
            style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${widget.ekubAmount ?? '0'} ${AppKeys.currencyEtb.tr(context)}",
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class CustomListItem extends StatelessWidget {
  final String text;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const CustomListItem({
    super.key,
    required this.text,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 18.0, right: 18, top: 4),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          padding: const EdgeInsets.fromLTRB(17.21, 3.19, 23.0, 5.81),
          width: double.infinity,
          height: 59.0,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.all(
              Radius.circular(8.0),
            ),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFF8F8F8),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.1),
                blurRadius: 20.0,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              imagePath != ''
                  ? Image.asset(
                      imagePath,
                      width: 110.0,
                      height: 70.0,
                      fit: BoxFit.contain,
                    )
                  : const SizedBox.shrink(),
              const Spacer(),
              Expanded(
                child: Text(
                  textScaleFactor: 1.0,
                  text,
                  style: const TextStyle(
                      fontSize: 15.0,
                      color: AppColors.coolMediumGray,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompanyBankAccountsResponse {
  final String status;
  final CompanyBankAccountsData data;

  CompanyBankAccountsResponse({
    required this.status,
    required this.data,
  });

  factory CompanyBankAccountsResponse.fromJson(Map<String, dynamic> json) {
    return CompanyBankAccountsResponse(
      status: json['status'],
      data: CompanyBankAccountsData.fromJson(json['data']),
    );
  }
}

class CompanyBankAccountsData {
  final List<CompanyBankAccount> companyBankAccounts;
  final Meta meta;

  CompanyBankAccountsData({
    required this.companyBankAccounts,
    required this.meta,
  });

  factory CompanyBankAccountsData.fromJson(Map<String, dynamic> json) {
    return CompanyBankAccountsData(
      companyBankAccounts: List<CompanyBankAccount>.from(
          json['companyBankAccounts']
              .map((x) => CompanyBankAccount.fromJson(x))),
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class CompanyBankAccount {
  final String id;
  final String accountNumber;
  final String accountName;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompanyBankAccount({
    required this.id,
    required this.accountNumber,
    required this.accountName,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyBankAccount.fromJson(Map<String, dynamic> json) {
    return CompanyBankAccount(
      id: json['id'],
      accountNumber: json['accountNumber'],
      accountName: json['accountName'],
      state: json['state'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Meta {
  final int page;
  final int limit;
  final int total;

  Meta({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
    );
  }
}

class InfoPopup extends StatefulWidget {
  String? ekubName;
  String? ekubId;
  double? ekubAmount;
  String? ekubRound;
  String? joinOption, joinAmount;
  double? percentage;
  final List<ListItem>? selectedJoinOption;
  final List<ListItems>? selectedJoinOptions;

  final String? round, type;
  InfoPopup(
      {super.key,
      this.ekubName,
      this.ekubId,
      this.ekubAmount,
      this.ekubRound,
      this.joinAmount,
      this.joinOption,
      this.selectedJoinOptions,
      this.percentage,
      required this.selectedJoinOption,
      this.round,
      this.type});

  @override
  State<InfoPopup> createState() => _InfoPopupState();
}

class _InfoPopupState extends State<InfoPopup> {
  List<Map<String, String>> data = [];

  @override
  void initState() {
    super.initState();
    getCompanyBanks();
  }

  bool _isSubmitting = false;
  final DataController dataController = DataController();

  Future<void> submit(List<ListItem> percentage, double paidAmount,
      String paymentMethod, String type) async {
    setState(() {
      _isSubmitting = true;
    });

    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    List<Map<String, dynamic>> equbers = [];

    for (var item in percentage) {
      double stake;
      if (item.title == '1') {
        stake = 100;
      } else if (item.title == '1/2') {
        stake = 50;
      } else {
        stake = calculateStake(item.title);
      }

      double paid = double.tryParse(item.subtitle) ?? 0;

      equbers.add({
        "stake": stake,
        "paidAmount": paid,
      });
    }

    Map<String, dynamic> data = {
      "paidAmount": paidAmount,
      "paymentMethod": paymentMethod,
      "equbers": equbers,
    };

    try {
      final Dio dio = Dio();

      final response = await dio.post(
        joinEkubUrl + widget.ekubId!,
        data: data,
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        if (paymentMethod == 'cbe') {
          CustomSnackBar.show(
            context,
            AppKeys.cbeUssdEnterPinMessage.tr(context),
            AppColors.primary,
          );
        } else {
          CustomSnackBar.show(
            context,
            AppKeys.pleaseUploadYourPayment.tr(context),
            AppColors.primary,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WaitingEkubs()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
        );
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(textScaleFactor: 1.0, AppKeys.tokenExpired.tr(context))),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreenWithPin(phoneNumber: '')),
        );
      } else if (e.response?.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0,
                  "${AppKeys.errorTitle.tr(context)} ${e.response?.data['message']}")),
        );
      } else if (e.response?.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0,
                  "${AppKeys.errorTitle.tr(context)} ${e.response?.data['message']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> submitPayment(List<ListItems> percentage, double paidAmount,
      String paymentMethod) async {
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    List<Map<String, dynamic>> lottery = [];

    for (var item in percentage) {
      String id = item.userIds;
      double paid = double.tryParse(item.subtitle) ?? 0;

      lottery.add({
        "id": id,
        "paidAmount": paid,
      });
    }

    Map<String, dynamic> data = {
      "paidAmount": paidAmount,
      "paymentMethod": paymentMethod,
      "lottery": lottery,
    };

    try {
      final Dio dio = Dio();

      final response = await dio.post(
        makePaymentUrl + widget.ekubId!,
        data: data,
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        if (paymentMethod == 'cbe') {
          CustomSnackBar.show(
            context,
            AppKeys.cbeUssdEnterPinMessage.tr(context),
            AppColors.primary,
          );
        } else {
          CustomSnackBar.show(
            context,
            AppKeys.pleaseUploadYourPayment.tr(context),
            AppColors.primary,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WaitingEkubsPayment(
                ekubId: widget.ekubId ?? '',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
        );
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(textScaleFactor: 1.0, AppKeys.tokenExpired.tr(context))),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => LoginScreenWithPin(phoneNumber: '')),
        );
      } else if (e.response?.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0,
                  "${AppKeys.errorTitle.tr(context)} ${e.response?.data['message']}")),
        );
      } else if (e.response?.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0,
                  "${AppKeys.errorTitle.tr(context)} ${e.response?.data['message']}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  double calculateStake(String title) {
    if (title.contains('/')) {
      var parts = title.split('/');
      return 100 * (double.parse(parts[0]) / double.parse(parts[1]));
    }
    return 100;
  }

  CompanyBankAccountsResponse? companyBankAccountsResponse;

  void getCompanyBanks() async {
    final Dio dio = Dio();

    try {
      final response = await dio.get(companyBankUrl);

      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        setState(() {
          companyBankAccountsResponse =
              CompanyBankAccountsResponse.fromJson(jsonResponse);
          data = companyBankAccountsResponse!.data.companyBankAccounts
              .map((account) => {
                    'title': account.accountName,
                    'subtitle': account.accountNumber,
                  })
              .toList();
        });
      }
    } catch (e) {}
  }

  final Map<int, bool> _copiedStatus = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    AppKeys.companyBankAccounts.tr(context),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: data.isEmpty
                    ? Center(
                        child: LoadingAnimationWidget.threeRotatingDots(
                          color: AppColors.vibrantGreen,
                          size: 30,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final isCopied = _copiedStatus[index] ?? false;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['subtitle']!,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isCopied ? Icons.check : Icons.copy,
                                        color: AppColors.primary,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(
                                              text: item['subtitle']!),
                                        );
                                        setState(() {
                                          _copiedStatus[index] = true;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check,
                                                    color: AppColors.primary),
                                                const SizedBox(width: 8),
                                                Text(AppKeys.copiedToClipBoard
                                                    .tr(context)),
                                              ],
                                            ),
                                            duration:
                                                const Duration(seconds: 2),
                                          ),
                                        );
                                        Future.delayed(
                                            const Duration(seconds: 2), () {
                                          setState(() {
                                            _copiedStatus[index] = false;
                                          });
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
