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
import 'package:ekubee/screens/my_other_ekubs.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mime/mime.dart';

import 'secure_storage.dart';

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
      CustomSnackBar.show(context, "Please select an image", AppColors.red);
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
            MaterialPageRoute(builder: (context) => ActiveEqubsScreen()));
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(textScaleFactor: 1.0, 'Unexpected error occured')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  List<Map<String, String>> data = []; // Initialize as an empty list

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
        TextEditingController(text: widget.ekubAmount..replaceAll(',', ''));
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
        child: Text(
          textScaleFactor: 1.0,
          AppKeys.enterDetails.tr(context),
          style: const TextStyle(color: AppColors.white),
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
            const SizedBox(height: 16.0),
            TextField(
              controller: referenceController,
              decoration: InputDecoration(
                labelText: AppKeys.referenceNumber.tr(context),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            TextField(
              enabled: false,
              controller: _paidAmountController,
              decoration: InputDecoration(
                labelText: AppKeys.paidAmount.tr(context),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                height: 100,
                width: 160.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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
                    : Center(
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
                              AppKeys.uploadPaymentReceipt.tr(context),
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
          child: Text(
            textScaleFactor: 1.0,
            AppKeys.cancel.tr(context),
            style: const TextStyle(color: AppColors.red),
          ),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.primary,
                    size: 20.0,
                  ),
                )
              : Text(
                  textScaleFactor: 1.0,
                  AppKeys.submit.tr(context),
                  style: const TextStyle(color: AppColors.primary),
                ),
        ),
      ],
    );
  }
}
