import 'dart:typed_data';

import 'package:ekubee/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/main.dart';
import 'package:ekubee/screens/create_new_password_screen.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/custom_button.dart';
import 'package:ekubee/utils/custom_text_field.dart';
import 'package:ekubee/utils/lang_constants.dart';
import 'package:image_picker/image_picker.dart';

class SignUpScreen extends StatefulWidget {
  final String phoneNumber;
  const SignUpScreen({super.key, required this.phoneNumber});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController middleNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController referalController = TextEditingController();


  @override
  void initState() {
    super.initState();

    final isPhone = widget.phoneNumber.trim().startsWith('+251');
    if (phoneNumberController.text.isEmpty) {
      phoneNumberController.text = '+251';
    }
    if (isPhone) {
      phoneNumberController.text = widget.phoneNumber.trim();
      phoneNumberController.selection = TextSelection.fromPosition(
        TextPosition(offset: phoneNumberController.text.length),
      );
    } else if (widget.phoneNumber.contains('@') &&
        widget.phoneNumber.contains('.')) {
      emailController.text = widget.phoneNumber.trim();
      emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: emailController.text.length),
      );
    }
  }

  XFile? _profileImage;
  Uint8List? _profileImageBytes;

  final ImagePicker _picker = ImagePicker();

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
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(AppKeys.camera.tr(context)),
                onTap: () async {
                  await requestCameraAndGalleryPermissions();

                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppKeys.gallery.tr(context)),
                onTap: () async {
                  await requestCameraAndGalleryPermissions();

                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: _showImagePicker,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.lightBlueGray,
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt,
                          size: 50, color: AppColors.grey)
                      : null,
                ),
              ),
            ),
          
            Padding(
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 16),
              child: Text(
                AppKeys.firstName.tr(context),
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
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 6),
              child: Text(
                AppKeys.middleName.tr(context),
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
                controller: middleNameController,
                borderRadius: BorderRadius.circular(8),
                height: 56,
                width: double.infinity,
                borderWidth: 0.6,
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 16),
              child: Text(
                AppKeys.lastName.tr(context),
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
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 16),
              child: Text(
                '${AppKeys.email.tr(context)}(Opt)',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26.0, right: 26, top: 6),
              child: CustomTextField(
                hintText: 'example@gmail.com',
                controller: emailController,
                borderRadius: BorderRadius.circular(8),
                height: 56,
                width: double.infinity,
                borderWidth: 0.6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 16),
              child: Text(
                AppKeys.phoneNumber.tr(context),
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 26.0, right: 26, top: 6, bottom: 20),
              child: TextFormField(
                controller: phoneNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '+251...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(13), // +251 + 9 digits
                  FilteringTextInputFormatter.allow(RegExp(r'^\+?[0-9]*$')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  if (!value.startsWith('+251')) {
                    return 'Phone number must start with +251';
                  }
                  if (value.length != 13) {
                    return 'Phone number must be exactly 9 digits after +251';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 10),
              child: Text(
                'Referal code (Opt)',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26.0, right: 26, top: 6),
              child: CustomTextField(
                hintText: 'Referal code (optional)',
                controller: referalController,
                borderRadius: BorderRadius.circular(8),
                height: 56,
                width: double.infinity,
                borderWidth: 0.6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26.0, right: 26, top: 39),
              child: CustomTextButton(
                text: AppKeys.next.tr(context),
                onPressed: () {
                  if (firstNameController.text.isNotEmpty &&
                      lastNameController.text.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateNewPasswordScreen(
                          firstName: firstNameController.text,
                          profilePicture: _profileImage,
                          profilePictureBytes: _profileImageBytes,
                          lastName: lastNameController.text,
                          middleName: middleNameController.text,
                          email: emailController.text,
                          phoneNumber: phoneNumberController.text,
                          referalCode: referalController.text,
                        ),
                      ),
                    );
                  }
                },
                textColor: AppColors.white,
              ),
            ),
          
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
