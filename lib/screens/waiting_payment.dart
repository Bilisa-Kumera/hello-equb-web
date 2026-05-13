import 'dart:io';

import 'package:dio/dio.dart';
import 'package:ekubee/screens/payment_screen.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/main.dart';
import 'package:ekubee/models/ekub_category_model.dart';
import 'package:ekubee/screens/LoginScreenWithPin.dart';
import 'package:ekubee/screens/home_screen.dart';
import 'package:ekubee/screens/my_other_ekubs.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mime/mime.dart';

import '../utils/secure_storage.dart';

class MyDialog extends StatefulWidget {
  final String ekubId, ekubAmount, joinOption;
  const MyDialog(
      {super.key,
      required this.ekubAmount,
      required this.ekubId,
      required this.joinOption});

  @override
  _MyDialogState createState() => _MyDialogState();
}

class _MyDialogState extends State<MyDialog> {
  TextEditingController _paidAmountController = TextEditingController();
  TextEditingController referenceController = TextEditingController();

  XFile? _image;
  bool _isSubmitting = false; 
  int getPercentage(String joinOption) {
    if (joinOption.contains('/')) {
      return int.parse(joinOption.split('/')[1]);
    } else {
      return 100;
    }
  }

  int percentage = 0;
  Future<void> _pickImage(ImageSource source) async {
    percentage = getPercentage(widget.joinOption);
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage = await picker.pickImage(source: source);
    setState(() {
      _image = pickedImage;
    });
  }

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

  Future<void> _submit() async {
    if (bankId.isEmpty) {
      CustomSnackBar.show(
          context, AppKeys.selectBankAccount.tr(context), AppColors.red);
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                textScaleFactor: 1.0, AppKeys.pleaseSelectImage.tr(context))),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
    final fileExtension = _image!.path.split('.').last.toLowerCase();
    final mimeType = lookupMimeType(_image!.path) ?? 'application/octet-stream';

    if (!(fileExtension == 'png' ||
        fileExtension == 'jpg' ||
        fileExtension == 'jpeg')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                textScaleFactor: 1.0,
                'Only .png, .jpg, and .jpeg formats are allowed')),
      );
      return;
    }

    try {
      final Dio dio = Dio();

      Map<String, dynamic> data = {
        'reference': referenceController.text,
        'paidAmount': _paidAmountController.text,
        'paymentMethod': 'bankTransfer',
        'companyBankAccountId': bankId,
      };

      if (percentage == 100) {
        data['stake'] = 100;
      } else {
        data['dividedBy'] = percentage;
      }

      data['picture'] = await MultipartFile.fromFile(
        _image!.path,
        filename: '1.jpg',
        contentType: MediaType.parse(mimeType),
      );

      FormData formData = FormData.fromMap(data);

      final response = await dio.patch(
        paymentUrl + widget.ekubId,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        CustomSnackBar.show(context, 'Payment successful. Wait for approval.',
            AppColors.primary);


        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ActiveEqubsScreen()));
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
        );
      }
    } on DioError catch (e) {
      if (e.response != null && e.response?.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(textScaleFactor: 1.0, AppKeys.tokenExpired.tr(context))),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LoginScreenWithPin(phoneNumber: '')));
      } else if (e.response != null && e.response?.statusCode == 400) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0,
                  'Error ${e.response?.data['message']}')),
        );
      } else if (e.response != null && e.response?.statusCode == 404) {
        if (kDebugMode) {}
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0,
                  'Error ${e.response?.data['message']}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  textScaleFactor: 1.0, AppKeys.errorTryAgain.tr(context))),
        );
      }
    
    } catch (e) {
      
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  CompanyBankAccountsResponse? companyBankAccountsResponse;
  Future<List<CompanyBankAccount>>? _companyBanksFuture;
  Future<List<CompanyBankAccount>> getCompanyBanks() async {
    final Dio dio = Dio();

    try {
      final response = await dio.get(companyBankUrl);

      if (response.statusCode == 200) {
        final jsonResponse = response.data; // Use response.data directly
        companyBankAccountsResponse =
            CompanyBankAccountsResponse.fromJson(jsonResponse);
        return companyBankAccountsResponse!.data.companyBankAccounts;
      }
    } catch (e) {}
    return [];
  }

  @override
  void initState() {
    super.initState();
    _companyBanksFuture = getCompanyBanks();
    _paidAmountController =
        TextEditingController(text: widget.ekubAmount ?? '0 Birr');
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text(AppKeys.camera.tr(context), textScaleFactor: 1.0),
              onTap: () async {
                await requestCameraAndGalleryPermissions();

                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: Text(AppKeys.gallery.tr(context), textScaleFactor: 1.0),
              onTap: () async {
                await requestCameraAndGalleryPermissions();

                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  String bankId = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      title: Container(
        color: AppColors.primary,
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          textScaleFactor: 1.0,
          'Enter Details',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<List<CompanyBankAccount>>(
              future: _companyBanksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: LoadingAnimationWidget.threeRotatingDots(
                      color: AppColors.vibrantGreen,
                      size: 30,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: AppKeys.selectBankAccount.tr(context),
                      border: const OutlineInputBorder(),
                    ),
                    value: null,
                    items: snapshot.data!.map((CompanyBankAccount account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(
                          '${account.accountName} ${account.accountNumber}',
                          textScaleFactor: 1.0,
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        bankId = newValue ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppKeys.selectBankAccount.tr(context);
                      }
                      return null;
                    },
                  );
                } else {
                  return Text(AppKeys.noData.tr(context));
                }
              },
            ),
            TextField(
              controller: referenceController,
              decoration:  InputDecoration(
                labelText: AppKeys.referenceNumber.tr(context),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            TextField(
              enabled: false,
              controller: _paidAmountController,
              decoration:  InputDecoration(
                labelText: AppKeys.paidAmount.tr(context),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                height: 100,
                width: 160.sw,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.grey200, AppColors.grey300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.grey400),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.black26,
                      blurRadius: 4.0,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                          height: 100,
                          width: 100,
                        ),
                      )
                    :  Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo,
                              color: AppColors.grey,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppKeys.uploadReceipt.tr(context),
                              textScaleFactor: 1.0,
                              style: const TextStyle(
                                  color: AppColors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:  Text(
            textScaleFactor: 1.0,
            AppKeys.cancel.tr(context),
            style: const TextStyle(color: AppColors.red),
          ),
        ),
        TextButton(
          onPressed: _isSubmitting
              ? null
              : _submit, // Disable button during submission
          child: _isSubmitting
              ? const Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.primary,
                    size: 20.0,
                  ),
                )
              :  Text(
                  textScaleFactor: 1.0,
                  AppKeys.submit.tr(context),
                  style: const TextStyle(color: AppColors.primary),
                ),
        ),
      ],
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.black, size: 18),
              ),
            ),
          ),
          title: Text(
            AppKeys.pendingPayments.tr(context),
            style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.black),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: pendingEqubs.isNotEmpty
              ? ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: pendingEqubs.length,
                  itemBuilder: (context, index) {
                    final item = pendingEqubs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 18),
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Ekub Name
                            _infoRow(
                              icon: Icons.group,
                              label: AppKeys.ekubName.tr(context),
                              value: item.equbName ?? '',
                              valueStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black),
                            ),

                            const SizedBox(height: 12),

                            /// Total Amount
                            _infoRow(
                              icon: Icons.attach_money_rounded,
                              label: AppKeys.totalAmount.tr(context),
                              value: numberFormat.format(item.amount),
                              valueStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.vibrantGreen),
                            ),

                            const SizedBox(height: 16),

                            /// Lottery + Amounts Grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 3.8,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: item.payments.length * 2,
                              itemBuilder: (context, index) {
                                final payment = item.payments[index ~/ 2];
                                return (index.isEven)
                                    ? _infoRow(
                                        icon: Icons.confirmation_num,
                                        label: AppKeys.lottery.tr(context),
                                        value: payment.lotteryNumber ?? '',
                                      )
                                    : _infoRow(
                                        icon: Icons.payments,
                                        label: AppKeys.amount.tr(context),
                                        value:
                                            numberFormat.format(payment.amount),
                                      );
                              },
                            ),

                            const SizedBox(height: 16),

                            /// Status
                            Row(
                              children: [
                                Text(
                                  AppKeys.paymentStatus.tr(context),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.neutralGray,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(AppKeys.pending.tr(context)),
                                  labelStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                  backgroundColor: AppColors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            /// Confirm or Waiting
                            item.picture == null
                                ? SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        elevation: 2,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return MyDialog(
                                              ekubAmount: numberFormat
                                                  .format(item.amount),
                                              ekubId: item.id ?? '',
                                              joinOption: '100',
                                            );
                                          },
                                        );
                                      },
                                      child: Text(
                                        AppKeys.uploadReceipt.tr(context),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          AppKeys.waitingForApproval
                                              .tr(context),
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.blue),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.info_outline,
                                              color: AppColors.blue),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16)),
                                                title: Text(AppKeys.paymentInfo
                                                    .tr(context)),
                                                content: Text(AppKeys
                                                    .youHaveAlreadySubmitted
                                                    .tr(context)),
                                                actions: [
                                                  TextButton(
                                                    child: Text(
                                                        AppKeys.ok.tr(context)),
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                  )
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : progress
                  ? Center(
                      child: LoadingAnimationWidget.threeRotatingDots(
                        color: AppColors.vibrantGreen,
                        size: 30,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined,
                              size: 64, color: AppColors.neutralGray),
                          const SizedBox(height: 12),
                          Text(AppKeys.noData.tr(context),
                              style: const TextStyle(
                                  fontSize: 16, color: AppColors.neutralGray)),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  /// reusable row builder for info
  Widget _infoRow({
    required String label,
    required String value,
    IconData? icon,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.neutralGray),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.neutralGray),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black),
          ),
        ),
      ],
    );
  }
}
