import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/main.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/payment_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/secure_storage.dart';
import 'package:helloequb/utils/style_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mime/mime.dart';

class UploadReceiptSheet extends StatefulWidget {
  final String ekubId;
  final String ekubAmount;
  final String joinOption;
  final VoidCallback? onSuccess;

  const UploadReceiptSheet({
    super.key,
    required this.ekubAmount,
    required this.ekubId,
    required this.joinOption,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required String ekubAmount,
    required String ekubId,
    required String joinOption,
    VoidCallback? onSuccess,
  }) {
    final parentContext = context;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: UploadReceiptSheet(
          ekubAmount: ekubAmount,
          ekubId: ekubId,
          joinOption: joinOption,
          onSuccess: onSuccess ??
              () {
                CustomSnackBar.show(
                  parentContext,
                  AppKeys.waitingForApproval.tr(parentContext),
                  AppColors.primary,
                );
              },
        ),
      ),
    );
  }

  @override
  State<UploadReceiptSheet> createState() => _UploadReceiptSheetState();
}

class _UploadReceiptSheetState extends State<UploadReceiptSheet> {
  final TextEditingController _referenceController = TextEditingController();
  late TextEditingController _paidAmountController;

  XFile? _image;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;
  String? _errorMessage;
  String bankId = '';
  int percentage = 0;

  Future<List<CompanyBankAccount>>? _companyBanksFuture;

  int _getPercentage(String joinOption) {
    if (joinOption.contains('/')) {
      return int.parse(joinOption.split('/')[1]);
    }
    return 100;
  }

  @override
  void initState() {
    super.initState();
    percentage = _getPercentage(widget.joinOption);
    _companyBanksFuture = _getCompanyBanks();
    _paidAmountController = TextEditingController(text: widget.ekubAmount);
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<List<CompanyBankAccount>> _getCompanyBanks() async {
    final Dio dio = Dio();
    try {
      final response = await dio.get(companyBankUrl);
      if (response.statusCode == 200) {
        final parsed = CompanyBankAccountsResponse.fromJson(response.data);
        return parsed.data.companyBankAccounts;
      }
    } catch (_) {}
    return [];
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);
    final pickedBytes =
        pickedImage == null ? null : await pickedImage.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = pickedImage;
      _imageBytes = pickedBytes;
    });
    _clearError();
  }

  void _showImageSourceOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text(AppKeys.camera.tr(context)),
                onTap: () async {
                  await requestCameraAndGalleryPermissions();
                  if (context.mounted) Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_outlined, color: AppColors.primary),
                title: Text(AppKeys.gallery.tr(context)),
                onTap: () async {
                  await requestCameraAndGalleryPermissions();
                  if (context.mounted) Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  void _showSheetError(String message) {
    setState(() => _errorMessage = message);
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: Colors.red.shade700, size: 18),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.red.shade800,
                height: 1.3,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearError,
            child: Icon(Icons.close_rounded,
                color: Colors.red.shade400, size: 18),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {bool hasError = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.greyLabel,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: hasError ? AppColors.red : AppColors.primary,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red, width: 1.2),
      ),
    );
  }

  ButtonStyle get _submitButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size(double.infinity, 40.h),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );

  Future<void> _submit() async {
    _clearError();
    if (bankId.isEmpty) {
      _showSheetError(AppKeys.selectBankAccount.tr(context));
      return;
    }
    if (_image == null || _imageBytes == null) {
      _showSheetError(AppKeys.pleaseSelectImage.tr(context));
      return;
    }

    setState(() => _isSubmitting = true);

    final bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
    final fileName = _image!.name.isNotEmpty ? _image!.name : _image!.path;
    final fileExtension = fileName.split('.').last.toLowerCase();
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

    if (!(fileExtension == 'png' ||
        fileExtension == 'jpg' ||
        fileExtension == 'jpeg')) {
      _showSheetError('Only .png, .jpg, and .jpeg formats are allowed');
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final data = <String, dynamic>{
        'reference': _referenceController.text,
        'paidAmount': _paidAmountController.text,
        'paymentMethod': 'bankTransfer',
        'companyBankAccountId': bankId,
        if (percentage == 100) 'stake': 100 else 'dividedBy': percentage,
        'picture': MultipartFile.fromBytes(
          _imageBytes!,
          filename: _image!.name.isNotEmpty ? _image!.name : '1.$fileExtension',
          contentType: MediaType.parse(mimeType),
        ),
      };

      final response = await Dio().patch(
        paymentUrl + widget.ekubId,
        data: FormData.fromMap(data),
        options: Options(headers: {'Authorization': 'Bearer $bearerToken'}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      } else {
        _showSheetError(AppKeys.errorTryAgain.tr(context));
      }
    } on DioError catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401) {
        _showSheetError(AppKeys.tokenExpired.tr(context));
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => LoginScreenWithPin(phoneNumber: '')),
        );
      } else if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        final message = e.response?.data['message']?.toString();
        _showSheetError(
          message ?? AppKeys.errorTryAgain.tr(context),
        );
      } else {
        _showSheetError(AppKeys.errorTryAgain.tr(context));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Upload receipt error: $e');
      if (mounted) {
        _showSheetError(AppKeys.errorTryAgain.tr(context));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppKeys.uploadReceipt.tr(context),
                      style: AppTextStyles.sectionTitleLarge.copyWith(
                        fontSize: 18.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildErrorBanner(),
                    FutureBuilder<List<CompanyBankAccount>>(
                      future: _companyBanksFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.h),
                            child: Center(
                              child: LoadingAnimationWidget.threeRotatingDots(
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                          );
                        }
                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Text(
                            AppKeys.noData.tr(context),
                            style: AppTextStyles.greyBody,
                          );
                        }
                        return DropdownButtonFormField<String>(
                          decoration: _fieldDecoration(
                              AppKeys.selectBankAccount.tr(context)),
                          value: bankId.isEmpty ? null : bankId,
                          items: snapshot.data!.map((account) {
                            return DropdownMenuItem<String>(
                              value: account.id,
                              child: Text(
                                '${account.accountName} ${account.accountNumber}',
                                style: AppTextStyles.labelMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => bankId = value ?? '');
                            _clearError();
                          },
                        );
                      },
                    ),
                    SizedBox(height: 14.h),
                    TextField(
                      controller: _referenceController,
                      decoration:
                          _fieldDecoration(AppKeys.referenceNumber.tr(context)),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 14.h),
                    TextField(
                      enabled: false,
                      controller: _paidAmountController,
                      decoration:
                          _fieldDecoration(AppKeys.paidAmount.tr(context)),
                    ),
                    SizedBox(height: 18.h),
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Container(
                        height: 140.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _imageBytes != null
                                ? AppColors.primary.withOpacity(0.4)
                                : Colors.grey.shade300,
                            width: 1.2,
                          ),
                        ),
                        child: _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cloud_upload_outlined,
                                      size: 36.sp, color: AppColors.primary),
                                  SizedBox(height: 8.h),
                                  Text(
                                    AppKeys.uploadReceipt.tr(context),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    AppKeys.uploadPaymentReceipt.tr(context),
                                    style: AppTextStyles.captionMuted,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: _submitButtonStyle,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: SpinKitFadingCircle(
                                  color: Colors.white,
                                  size: 18,
                                ),
                              )
                            : Text(
                                AppKeys.submit.tr(context),
                                style: AppTextStyles.buttonLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
