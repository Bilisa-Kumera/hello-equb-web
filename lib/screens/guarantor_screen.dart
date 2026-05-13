
import 'dart:io';

import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/main.dart';
import 'package:ekubee/models/ekub_category_model.dart';
import 'package:ekubee/screens/my_ekub_detail_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/custom_progress_screen.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/custom_text_field.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:dio/dio.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mime/mime.dart';

import '../utils/secure_storage.dart';

class GuarantorScreen extends StatefulWidget {
  final String ekubId;
  final String ekuberUserId;
  final String? ekubName;
  final int? ekubAmount, ekubersNumber, ekubCycle;
  final String? nextRoundDate;
  final String? nextRoundTime;
  final bool? ekubRequest;
  final String? nextRoundLotteryType;
  final String serviceCharge;

  const GuarantorScreen(
      {super.key,
      required this.ekubId,
      required this.ekuberUserId,
      this.ekubAmount,
      this.ekubName,
      this.ekubersNumber,
      this.ekubCycle,
      this.nextRoundDate,
      this.nextRoundTime,
      this.ekubRequest,
      this.nextRoundLotteryType,
      required this.serviceCharge});

  @override
  State<GuarantorScreen> createState() => _GuarantorScreenState();
}

class Guarantor {
  final String id;
  final String name;

  Guarantor({required this.id, required this.name});

  factory Guarantor.fromJson(Map<String, dynamic> json) {
    return Guarantor(
      id: json['id'],
      name: json['fullName'],
    );
  }
}

class _GuarantorScreenState extends State<GuarantorScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController middleNameController = TextEditingController();

  final DataController dataController = DataController();
  final Dio _dio = Dio();
  
  List<Guarantor>? _guarantors;
  bool _isLoadingGuarantors = true;
  String? _guarantorsError;
  
  String? selectedGuarantor;
  String selectedGuarantorId = '';
  bool optional = false;

  @override
  void initState() {
    super.initState();
    _loadGuarantors();
  }

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

  Future<void> _loadGuarantors() async {
    try {
      String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
      final response = await _dio.get(getGuaranteeToBeUrl,
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}));

      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        List<Guarantor> guarantors =
            data.map((item) => Guarantor.fromJson(item)).toList();
        
        String? userId = await SecureStorageHelper.getUserId();
        if (userId != null) {
          guarantors.removeWhere((guarantee) => guarantee.id == userId);
        }

        if (mounted) {
          setState(() {
            _guarantors = guarantors;
            _isLoadingGuarantors = false;
          });
        }
      } else {
        throw Exception('Failed to load guarantors');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _guarantorsError = e.toString();
          _isLoadingGuarantors = false;
        });
      }
    }
  }

  Future<void> postSelected(
    BuildContext context,
    String endpoint,
    String id,
    Map<String, dynamic> data, {
    String? bearerToken,
  }) async {
    try {
      final Dio _dio = Dio();

      final response = await _dio.post(
        endpoint,
        data: data,
      );

      if (response.statusCode == 200) {
        CustomSnackBar.show(context, 'Sent successfully', AppColors.primary);
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });


        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyEkubDetailScreen(
              ekubType: 'Finance',
              ekubAmount: widget.ekubAmount ?? 0,
              ekubCycle: widget.ekubCycle ?? 0,
              ekubId: widget.ekubId,
              ekubName: widget.ekubName ?? '',
              ekubRequest: widget.ekubRequest ?? false,
              ekubersNumber: widget.ekubersNumber ?? 0,
              nextRoundDate: widget.nextRoundDate ?? '',
              nextRoundLotteryType: widget.nextRoundLotteryType ?? '',
              nextRoundTime: widget.nextRoundTime ?? '',
              serviceCharge: widget.serviceCharge ?? '',
            ),
          ),
        );
      } else {
        _handleError(
          context,
          'Error adding data. Try again!',
          AppColors.red,
        );
        Navigator.pop(context);
      }
    } on DioException catch (error) {
      if (error.response != null) {
        if (error.response!.statusCode == 400) {
          _handleError(
            context,
            'Error: ${error.response!.data['message']}',
            AppColors.red,
          );
        } else {
          _handleError(
            context,
            'Error: ${error.response!.data['message']}',
            AppColors.red,
          );
        }
      } else {
        _handleError(
          context,
          'Unexpected error occurred. Please try again.',
          AppColors.red,
        );
      }
    } catch (error) {
      _handleError(
        context,
        'Unexpected error occurred. Please try again.',
        AppColors.red,
      );
    }
  }

  void _handleError(BuildContext context, String message, Color color) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    CustomSnackBar.show(context, message, color);
  }

  Future<void> post(BuildContext context, String endpoint, String id,
      Map<String, dynamic> data,
      {String? bearerToken, File? image}) async {
    try {
      final Dio _dio = Dio();
      final fileExtension = image!.path.split('.').last.toLowerCase();
      final mimeType =
          lookupMimeType(image.path) ?? 'application/octet-stream';

      if (!(fileExtension == 'png' ||
          fileExtension == 'jpg' ||
          fileExtension == 'jpeg')) {
        CustomSnackBar.show(
            context,
            'Only .png, .jpg, and .jpeg formats are allowed',
            AppColors.primary);
        return;
      }
      
      data['picture'] = await MultipartFile.fromFile(
        image.path,
        filename: '1.jpg',
        contentType: MediaType.parse(mimeType),
      );
      
      FormData formData = FormData.fromMap({
        ...data,
      });
      
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );

      if (response.statusCode == 200) {
        CustomSnackBar.show(context, 'Sent successfully', AppColors.primary);

        Navigator.pop(context);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MyEkubDetailScreen(
                      ekubType: 'Finance',
                      ekubAmount: widget.ekubAmount ?? 0,
                      ekubCycle: widget.ekubCycle ?? 0,
                      ekubId: widget.ekubId,
                      ekubName: widget.ekubName ?? '',
                      ekubRequest: widget.ekubRequest ?? false,
                      ekubersNumber: widget.ekubersNumber ?? 0,
                      nextRoundDate: widget.nextRoundDate ?? '',
                      nextRoundLotteryType: widget.nextRoundLotteryType ?? '',
                      nextRoundTime: widget.nextRoundTime ?? '',
                      serviceCharge: widget.serviceCharge,
                    )));
      } else {
        Navigator.pop(context);
        CustomSnackBar.show(
            context, 'Error adding data. Try again!', AppColors.red);
      }
    } on DioException catch (error) {
      Navigator.pop(context);

      if (error.response != null) {
        if (error.response!.statusCode == 400) {
          CustomSnackBar.show(context,
              'Error ${error.response!.data['message']}', AppColors.red);
        } else {
          CustomSnackBar.show(context,
              'Error ${error.response!.data['message']}', AppColors.red);
        }
      }
    } catch (error) {
      Navigator.pop(context);
    }
  }

  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: Text(textScaleFactor: 1.0, AppKeys.camera.tr(context)),
                onTap: () async {
                  await requestCameraAndGalleryPermissions();
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(textScaleFactor: 1.0, AppKeys.gallery.tr(context)),
                onTap: () async {
                  await requestCameraAndGalleryPermissions();
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String phoneNumber = '';
  bool clickable = true;

  Widget _buildGuarantorDropdown() {
    if (_isLoadingGuarantors) {
      return const Center(
        child: SpinKitFadingCircle(
          color: AppColors.primary,
          size: 50.0,
        ),
      );
    }

    if (_guarantorsError != null) {
      return Text(
        textScaleFactor: 1.0,
        AppKeys.errorTryAgain.tr(context),
      );
    }

    if (_guarantors == null || _guarantors!.isEmpty) {
      return Text(
        textScaleFactor: 1.0,
        AppKeys.noData.tr(context),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 28.0, right: 26, top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey300,
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: DropdownButton<String>(
          value: selectedGuarantor,
          hint: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              AppKeys.chooseGuarantor.tr(context),
              style: TextStyle(
                  fontSize: 16.sp, color: AppColors.grey),
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down,
              color: AppColors.teal),
          isExpanded: true,
          items: _guarantors!.map((Guarantor guarantor) {
            return DropdownMenuItem<String>(
              value: guarantor.id,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  guarantor.name,
                  style: TextStyle(
                      fontSize: 16, color: AppColors.black),
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedGuarantor = newValue;
            });
          },
          style: TextStyle(
            color: AppColors.black,
            fontSize: 16,
          ),
          dropdownColor: AppColors.white,
          underline: const SizedBox(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8),
          child: CustomTextButton(
              text: AppKeys.submit.tr(context),
              buttonColor: clickable ? AppColors.deepGreen : AppColors.grey,
              onPressed: clickable
                  ? () async {
                      String formattedPhone =
                          phoneNumberController.text.startsWith('+251')
                              ? phoneNumberController.text.substring(4)
                              : phoneNumberController.text;
                      if (optional) {
                        if (firstNameController.text.isNotEmpty &&
                            lastNameController.text.isNotEmpty &&
                            phoneNumber != '') {
                          showDialog(
                            context: context,
                            builder: (csubmitontext) =>
                                const WaitingProgressPage(),
                          );

                          String accessToken =
                              await SecureStorageHelper.getAccessToken() ?? '';

                          await post(
                            context,
                            '$addGuarantorInfoUrl${widget.ekuberUserId}',
                            await SecureStorageHelper.getUserId() ?? '',
                            {
                              "firstName": firstNameController.text,
                              "lastName": lastNameController.text,
                              "phoneNumber": '+251$formattedPhone',
                            },
                            bearerToken: accessToken,
                            image: _image,
                          );

                          setState(() {
                            clickable = false;
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      } else {
                        showDialog(
                          context: context,
                          builder: (csubmitontext) =>
                              const WaitingProgressPage(),
                        );
                        final DataController dataController = DataController();

                        await postSelected(
                          context,
                          "$getGuaranteeRequestUrl${widget.ekuberUserId}",
                          await SecureStorageHelper.getUserId() ?? '',
                          {
                            "fullName": dataController
                                .retrieveData<String>('fullName')
                                .toString(),
                            "userId": selectedGuarantor.toString(),
                            "firstUserId":
                                await SecureStorageHelper.getUserId() ?? '',
                            "equbName": widget.ekubName.toString(),
                            "equbAmount": widget.ekubAmount.toString()
                          },
                        );
                        Navigator.pop(context);
                      }
                    }
                  : () {}),
        ),
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8),
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(13)),
                  border: Border.all(color: AppColors.lightBlueGray, width: 1)),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.black)),
                ),
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                textScaleFactor: 1.0,
                AppKeys.guarantorInformation.tr(context),
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                textScaleFactor: 1.0,
                '',
                style: TextStyle(color: AppColors.primary, fontSize: 18.sp),
              )
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!optional) ...[
                _buildGuarantorDropdown(),
              ],
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      optional = !optional;
                    });
                  },
                  child: Text(
                    textScaleFactor: 1.0,
                    optional
                        ? AppKeys.pickFromEkubers.tr(context)
                        : AppKeys.didntGetYourGuarantee.tr(context),
                    style: TextStyle(color: AppColors.primary, fontSize: 14.sp),
                  ),
                ),
              ),
              if (optional) ...[
                Padding(
                  padding:
                      const EdgeInsets.only(left: 28.0, right: 26, top: 16),
                  child: Text(
                    textScaleFactor: 1.0,
                    AppKeys.guarantorFirstName.tr(context),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 26.0, right: 26, top: 6),
                  child: CustomTextField(
                    hintText: 'Abebe',
                    controller: firstNameController,
                    borderRadius: BorderRadius.circular(8),
                    height: 56,
                    width: double.infinity,
                    borderWidth: 0.6,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 28.0, right: 26, top: 16),
                  child: Text(
                    textScaleFactor: 1.0,
                    AppKeys.guarantorLastName.tr(context),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 26.0, right: 26, top: 6),
                  child: CustomTextField(
                    hintText: 'Kebede',
                    controller: lastNameController,
                    borderRadius: BorderRadius.circular(8),
                    height: 56,
                    width: double.infinity,
                    borderWidth: 0.6,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 28.0, right: 26, top: 16),
                  child: Text(
                    textScaleFactor: 1.0,
                    AppKeys.guarantorPhoneNumber.tr(context),
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp),
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: IntlPhoneField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.grayOverlay,
                      hintText: AppKeys.phoneNumber.tr(context),
                      hintStyle: TextStyle(
                        fontSize: 15.sp,
                        color: AppColors.coolGray,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    initialCountryCode: 'ET',
                    controller: phoneNumberController,
                    onChanged: (phone) {
                      setState(() {
                        phoneNumber = phoneNumberController.text;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        textScaleFactor: 1.0,
                        AppKeys.uploadGuaranteeIdCardImage.tr(context),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _showImageSourceActionSheet(context),
                        child: _image != null
                            ? Image.file(
                                _image!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: double.infinity,
                                height: 200,
                                color: AppColors.grey200,
                                child: const Icon(
                                  Icons.image,
                                  color: AppColors.grey,
                                  size: 100,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ));
  }
}