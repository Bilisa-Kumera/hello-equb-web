// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/screens/LoginScreenWithPin.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/custom_progress_screen.dart';
import 'package:ekubee/utils/custom_text_field.dart';
import 'package:dio/dio.dart';
import 'package:ekubee/utils/getx_storage_custom.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import '../utils/secure_storage.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class CreateNewPasswordScreen extends StatelessWidget {
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final String firstName, lastName, middleName, phoneNumber, email;
  final DataController dataController = DataController();
  final String? referalCode;
  final XFile? profilePicture;
  final Uint8List? profilePictureBytes;
  CreateNewPasswordScreen(
      {super.key,
      required this.firstName,
      required this.lastName,
      required this.middleName,
      required this.phoneNumber,
      required this.email,
      this.profilePicture,
      this.profilePictureBytes,
      this.referalCode});

  final Dio _dio = Dio();
  bool waiting = false;
  String errorMessage = "";

  Future<void> registerUser(BuildContext context) async {
    if (passwordController.text == confirmPasswordController.text) {
      dataController.storeData('middleName', middleName);
      dataController.storeData('firstName', firstName);
      dataController.storeData('lastName', lastName);
      dataController.storeData('phoneNumber', phoneNumber);
      dataController.storeData('email', email);

      try {
        // Retrieve the bearer token from the stored data
        String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

        // Check if image is selected
        if (profilePicture != null) {
          final fileName = profilePicture!.name.isNotEmpty
              ? profilePicture!.name
              : profilePicture!.path;
          final fileExtension = fileName.split('.').last.toLowerCase();
          final mimeType = lookupMimeType(fileName) ??
              'application/octet-stream';
          final bytes = profilePictureBytes ??
              await profilePicture!.readAsBytes();

          // Create multipart data for the image
          MultipartFile imageFile = MultipartFile.fromBytes(
            bytes,
            filename: '1.$fileExtension',
            contentType: MediaType.parse(mimeType),
          );

          // Send the OTP request along with the image
          FormData formData = FormData.fromMap({
            "middleName": middleName,
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber,
            "email": email,
            "password": passwordController.text,
            "picture": imageFile,
            "ref": referalCode
          });

          Response response = await _dio.post(
            registerUserUrls,
            data: formData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearerToken',
                'Content-Type': 'multipart/form-data',
              },
            ),
          );

          if (response.statusCode == 400) {
            Map<String, dynamic> responseData =
                json.decode(response.toString());
            errorMessage = responseData['message'];
          }

          if (response.statusCode == 200) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginScreenWithPin(
                        phoneNumber: '',
                      )),
              (route) => false,
            );

            // Successfully received OTP
            waiting = false;
          } else {}
        } else {
          FormData formData = FormData.fromMap({
            "middleName": middleName,
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber,
            "email": email,
            "password": passwordController.text,
          });

          Response response = await _dio.post(
            registerUserUrls,
            data: formData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearerToken',
                'Content-Type': 'multipart/form-data',
              },
            ),
          );

          if (response.statusCode == 400) {
            Map<String, dynamic> responseData =
                json.decode(response.toString());
            errorMessage = responseData['message'];
          }

          if (response.statusCode == 200) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginScreenWithPin(
                        phoneNumber: '',
                      )),
              (route) => false,
            );
            // Successfully received OTP
            waiting = false;
          } else {}
        }
      } catch (e) {
        if (e is DioError && e.response != null) {
          if (e.response!.statusCode == 400) {
            Map<String, dynamic> responseData =
                json.decode(e.response.toString());
            String errorMessage = responseData['message'] ?? '';

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
                title: const Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.red, size: 28), // Add error icon
                    SizedBox(width: 8), // Space between icon and text
                    Text(
                      'Error',
                      style: TextStyle(
                        color: AppColors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      textScaleFactor: 1.0,
                    ),
                  ],
                ),
                content: Text(
                  errorMessage,
                  textScaleFactor: 1.0,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.grey, // Subtle text color
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                      backgroundColor:
                          AppColors.redAccent, // Button background color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      textScaleFactor: 1.0,
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          }
        } else {}
      }
    } else {
      waiting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 18.0, top: 40),
              child: InkWell(onTap: ()=>Navigator.pop(context), child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(13)),
                    border:
                        Border.all(color: AppColors.lightBlueGray, width: 1)),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.arrow_back_ios, color: AppColors.black),
                  ), // Set icon color to black
                ),
              ),),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 26.0, right: 8),
              child: SizedBox(
                child: Text(
                  textScaleFactor: 1.0,
                  AppKeys.createNewPin.tr(context),
                  style: TextStyle(
                      color: AppColors.darkBlueGray,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Urbanist',
                      fontSize: 24.sp),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 20, left: 26.0, right: 8),
              child: SizedBox(
                child: Text(
                  textScaleFactor: 1.0,
                  AppKeys.yourNewPinMustBe.tr(context),
                  style: TextStyle(
                      color: AppColors.coolGray,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Urbanist',
                      fontSize: 14.sp),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26.0, right: 26, top: 36),
              child: PasswordTextField(
                hintText: AppKeys.newPin.tr(context),
                controller: passwordController,
                borderRadius: BorderRadius.circular(8),
                height: 56,
                width: double.infinity,
                borderWidth: 0.6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 26.0, right: 26, top: 16, bottom: 20),
              child: PasswordTextField(
                hintText: AppKeys.confirmPin.tr(context),
                controller: confirmPasswordController,
                borderRadius: BorderRadius.circular(8),
                height: 56,
                width: double.infinity,
                borderWidth: 0.6,
              ),
            ),
            errorMessage != ""
                ? Text(
                    textScaleFactor: 1.0,
                    errorMessage,
                    style: const TextStyle(color: AppColors.red),
                  )
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.all(26.0),
              child: CustomTextButton(
                text: AppKeys.done.tr(context),
                onPressed: () {
                  if (passwordController.text.isNotEmpty &&
                      confirmPasswordController.text.isNotEmpty) {
                    waiting = true;

                    waiting
                        ? showDialog(
                            context: context,
                            builder: (context) => const WaitingProgressPage())
                        : null;
                    registerUser(context);
                  }
                },
                textColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
