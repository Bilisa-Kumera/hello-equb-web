// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/screens/complete_profile_financial.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/custom_progress_screen.dart';
import 'package:ekubee/utils/custom_snack_bar.dart';
import 'package:ekubee/utils/custom_text_field.dart';
// import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../utils/secure_storage.dart';

// ignore: must_be_immutable
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen(
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

  final int? ekubAmount, ekubersNumber, ekubCycle;
  final String? ekubName, ekubId;
  final bool? ekubRequest;
  final String? ekubersUserId;
  final String? nextRoundDate;
  final String? nextRoundLotteryType;
  final String? nextRoundTime;
  final String serviceCharge;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final DataController dataController = DataController();
  TextEditingController emailController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  final List<String> genderOptions = ['Male', 'Female'];
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  String profileAvatarUrl = "";
  // bool? selectedValue;
  int selectedIndex =
      0; // or 'Male' or 'Female' depending on your default value

  String middleName = '',
      firstName = '',
      lastName = '',
      phoneNumber = '',
      email = '';
  TextEditingController middleNameController = TextEditingController();

  final Dio _dio = Dio();
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  Uint8List? _profileImageBytes;

  @override
  void initState() {
    super.initState();
    _preloadProfileData();
  }

  String _valueFromApiOrLocal(dynamic apiValue, String storageKey) {
    final String apiText = (apiValue ?? '').toString().trim();
    if (apiText.isNotEmpty && apiText.toLowerCase() != 'null') {
      return apiText;
    }
    return (dataController.retrieveData(storageKey) ?? '').toString();
  }

  int _genderIndexFromValue(String? gender) {
    if (gender == null || gender.isEmpty) return 0;
    final String normalized =
        gender[0].toUpperCase() + gender.substring(1).toLowerCase();
    final int index = genderOptions.indexOf(normalized);
    return index == -1 ? 0 : index;
  }

  Future<void> _preloadProfileData() async {
    String loadedFirstName = '';
    String loadedMiddleName = '';
    String loadedLastName = '';
    String loadedPhoneNumber = '';
    String loadedEmail = '';
    String loadedAvatarUrl = '';
    int loadedGenderIndex = 0;

    final String localGender =
        (dataController.retrieveData('gender') ?? 'male').toString();
    loadedGenderIndex = _genderIndexFromValue(localGender);
    final String localAvatar =
        (dataController.retrieveData('profileUrl') ?? '').toString();
    if (localAvatar.isNotEmpty) {
      loadedAvatarUrl = "${mediaUrl}images/avatar/$localAvatar";
    }

    final String accessToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = await _dio.get(
        getMyProfile,
        options: Options(
          headers: {
            if (accessToken.isNotEmpty) "Authorization": "Bearer $accessToken",
          },
        ),
      );
      final user = response.data['data']?['user'];

      loadedFirstName = _valueFromApiOrLocal(user?['firstName'], 'firstName');
      loadedMiddleName =
          _valueFromApiOrLocal(user?['middleName'], 'middleName');
      loadedLastName = _valueFromApiOrLocal(user?['lastName'], 'lastName');
      loadedPhoneNumber =
          _valueFromApiOrLocal(user?['phoneNumber'], 'phoneNumber');
      loadedEmail = _valueFromApiOrLocal(user?['email'], 'email');
      final String gender = _valueFromApiOrLocal(user?['gender'], 'gender');
      loadedGenderIndex = _genderIndexFromValue(gender);

      final String avatar = (user?['avatar'] ?? '').toString();
      if (avatar.isNotEmpty && avatar.toLowerCase() != 'null') {
        loadedAvatarUrl = "${mediaUrl}images/avatar/$avatar";
      }

    } catch (e) {
      loadedFirstName = (dataController.retrieveData('firstName') ?? '').toString();
      loadedMiddleName =
          (dataController.retrieveData('middleName') ?? '').toString();
      loadedLastName = (dataController.retrieveData('lastName') ?? '').toString();
      loadedPhoneNumber =
          (dataController.retrieveData('phoneNumber') ?? '').toString();
      loadedEmail = (dataController.retrieveData('email') ?? '').toString();
    }

    if (!mounted) return;

    setState(() {
      firstName = loadedFirstName;
      middleName = loadedMiddleName;
      lastName = loadedLastName;
      phoneNumber = loadedPhoneNumber;
      email = loadedEmail;
      selectedIndex = loadedGenderIndex;
      profileAvatarUrl = loadedAvatarUrl;

      firstNameController.text = loadedFirstName;
      middleNameController.text = loadedMiddleName;
      lastNameController.text = loadedLastName;
      phoneNumberController.text = loadedPhoneNumber;
      emailController.text = loadedEmail;
    });

  }

  Future<void> update(BuildContext context, String endpoint, String id,
      Map<String, dynamic> data,
      {String? bearerToken}) async {
    try {
      bool hasFile = false;
      Map<String, dynamic> formDataMap = {};

      data.forEach((key, value) {
        if (value is MultipartFile) {
          hasFile = true;
        }
        formDataMap[key] = value;
      });

      var requestData = hasFile ? FormData.fromMap(formDataMap) : data;
      final response = await _dio.patch(
        '$endpoint$id',
        data: requestData,
        options: Options(
          headers: {
            "Content-Type":
                hasFile ? "multipart/form-data" : "application/json",
            if (bearerToken != null) "Authorization": "Bearer $bearerToken",
          },
        ),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinancialInformation(
              serviceCharge: widget.serviceCharge,
              ekubId: widget.ekubId,
              ekubersUserId: widget.ekubersUserId,
              ekubAmount: widget.ekubAmount,
              ekubCycle: widget.ekubCycle,
              ekubName: widget.ekubName,
              ekubRequest: widget.ekubRequest,
              ekubersNumber: widget.ekubersNumber,
              nextRoundDate: widget.nextRoundDate,
              nextRoundLotteryType: widget.nextRoundLotteryType,
              nextRoundTime: widget.nextRoundTime,
            ),
          ),
        );

        dataController.storeData(
            'fullName', response.data['data']['user']['fullName']);
        dataController.storeData(
            'profileUrl', response.data['data']['user']['avatar']);
        dataController.storeData(
            'middleName', response.data['data']['user']['middleName']);
        dataController.storeData(
            'firstName', response.data['data']['user']['firstName']);
        dataController.storeData(
            'lastName', response.data['data']['user']['lastName']);
        dataController.storeData(
            'phoneNumber', response.data['data']['user']['phoneNumber']);
        dataController.storeData(
            'gender', response.data['data']['user']['gender']);
       

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinancialInformation(
              serviceCharge: widget.serviceCharge,
              ekubId: widget.ekubId,
              ekubersUserId: widget.ekubersUserId,
              ekubAmount: widget.ekubAmount,
              ekubCycle: widget.ekubCycle,
              ekubName: widget.ekubName,
              ekubRequest: widget.ekubRequest,
              ekubersNumber: widget.ekubersNumber,
              nextRoundDate: widget.nextRoundDate,
              nextRoundLotteryType: widget.nextRoundLotteryType,
              nextRoundTime: widget.nextRoundTime,
            ),
          ),
        );
      } else {}
    } catch (e) {
    }
  }

  // Function to pick an image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImage = pickedFile;
        _profileImageBytes = bytes;
      });
    }
  }

  // Method to display an image selection option
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(textScaleFactor: 1.0, AppKeys.gallery.tr(context)),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(textScaleFactor: 1.0, AppKeys.camera.tr(context)),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.name,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          textScaleFactor: 1.0,
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
            color: AppColors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        CustomTextField(
          hintText: hintText,
          controller: controller,
          borderRadius: BorderRadius.circular(14),
          height: 56,
          width: double.infinity,
          borderWidth: 0.8,
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.black87),
        ),
        title: Text(
          textScaleFactor: 1.0,
          AppKeys.personalInformation.tr(context),
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
                  '1/2',
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
                border: Border.all(color: AppColors.primary.withOpacity(0.12)),
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
                    child: const Icon(Icons.person_outline,
                        color: AppColors.primary),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          textScaleFactor: 1.0,
                          AppKeys.personalInformation.tr(context),
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
                          AppKeys.pleaseFillAllTheFields.tr(context),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.black54,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            Center(
              child: GestureDetector(
                onTap: _showImagePicker,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.lightBlueGray,
                      backgroundImage: _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                          : (profileAvatarUrl.isNotEmpty)
                              ? NetworkImage(profileAvatarUrl) as ImageProvider
                              : null,
                      child: (_profileImage == null && profileAvatarUrl.isEmpty)
                          ? const Icon(Icons.camera_alt,
                              size: 44, color: AppColors.grey)
                          : null,
                    ),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                      child: const Icon(Icons.edit,
                          size: 16, color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 18.h),
            Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField(
                    label: AppKeys.firstName.tr(context),
                    controller: firstNameController,
                    hintText: AppKeys.firstName.tr(context),
                  ),
                  SizedBox(height: 14.h),
                  _buildField(
                    label: AppKeys.middleName.tr(context),
                    controller: middleNameController,
                    hintText: AppKeys.middleName.tr(context),
                  ),
                  SizedBox(height: 14.h),
                  _buildField(
                    label: AppKeys.lastName.tr(context),
                    controller: lastNameController,
                    hintText: AppKeys.lastName.tr(context),
                  ),
                  SizedBox(height: 14.h),
                  _buildField(
                    label: AppKeys.phoneNumber.tr(context),
                    controller: phoneNumberController,
                    hintText: AppKeys.phoneNumber.tr(context),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 14.h),
                  _buildField(
                    label: AppKeys.email.tr(context),
                    controller: emailController,
                    hintText: AppKeys.email.tr(context),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    textScaleFactor: 1.0,
                    AppKeys.gender.tr(context),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: AppColors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  DropdownButtonFormField<int>(
                    value: selectedIndex,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.grey50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.darkOverlay.withOpacity(0.5),
                          width: 0.8,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.2,
                        ),
                      ),
                    ),
                    dropdownColor: AppColors.white,
                    items: List.generate(genderOptions.length, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          textScaleFactor: 1.0,
                          genderOptions[index].toLowerCase() == 'male'
                              ? AppKeys.male.tr(context)
                              : AppKeys.female.tr(context),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                    onChanged: (int? newIndex) {
                      setState(() {
                        selectedIndex = newIndex ?? 0;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 18.h),
            CustomTextButton(
              text: AppKeys.saveAndContinue.tr(context),
              onPressed: () async {
                if (firstNameController.text.isEmpty ||
                    lastNameController.text.isEmpty ||
                    middleNameController.text.isEmpty ||
                    phoneNumberController.text.isEmpty) {
                  CustomSnackBar.show(
                    context,
                    AppKeys.pleaseFillAllTheFields.tr(context),
                    AppColors.red,
                  );
                  return;
                }

                String userId = await SecureStorageHelper.getUserId() ?? '';
                String accessToken =
                    await SecureStorageHelper.getAccessToken() ?? '';

                Map<String, dynamic> requestBody = {
                  "firstName": firstNameController.text,
                  "middleName": middleNameController.text,
                  "lastName": lastNameController.text,
                  "phoneNumber": phoneNumberController.text,
                  "gender": genderOptions[selectedIndex].toLowerCase(),
                  if (emailController.text.isNotEmpty) "email": emailController.text,
                };

                if (_profileImage != null) {
                  final fileName = _profileImage!.name.isNotEmpty
                      ? _profileImage!.name
                      : _profileImage!.path;
                  final fileExtension = fileName.split('.').last.toLowerCase();
                  final mimeType = lookupMimeType(fileName) ??
                      'application/octet-stream';

                  final bytes = _profileImageBytes ??
                      await _profileImage!.readAsBytes();

                  requestBody["picture"] = MultipartFile.fromBytes(
                    bytes,
                    filename: 'profile_pic.$fileExtension',
                    contentType: MediaType.parse(mimeType),
                  );
                }

                showDialog(
                  context: context,
                  builder: (context) => const WaitingProgressPage(),
                );

                try {
                  await update(
                    context,
                    updatePersonnalUrl,
                    userId,
                    requestBody,
                    bearerToken: accessToken,
                  );
                  dataController.storeData(
                      'gender', genderOptions[selectedIndex].toLowerCase());
                } catch (e) {
                } finally {
                  Navigator.pop(context);
                }
              },
              textColor: AppColors.white,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
