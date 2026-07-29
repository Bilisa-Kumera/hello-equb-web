import 'dart:typed_data';

import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/main.dart';
import 'package:helloequb/screens/create_new_password_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/custom_text_field.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helloequb/utils/style_constants.dart';

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
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isPhoneTabActive = true;


  @override
  void initState() {
    super.initState();

    final isPhone = widget.phoneNumber.trim().startsWith('+251');
    _isPhoneTabActive = isPhone;
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

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    middleNameController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    referalController.dispose();
    _phoneFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
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

  void _switchContactTab(bool isPhoneTab) {
    if (_isPhoneTabActive == isPhoneTab) return;
    _phoneFocusNode.unfocus();
    _emailFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _isPhoneTabActive = isPhoneTab;
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      if (isPhoneTab) {
        _phoneFocusNode.requestFocus();
      } else {
        _emailFocusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final contactLabel = _isPhoneTabActive
        ? AppKeys.phoneNumber.tr(context)
        : '${AppKeys.email.tr(context)} (Opt)';
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
                style: AppTextStyles.poppins70016,
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
                style: AppTextStyles.poppins70016,
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
                style: AppTextStyles.poppins70016,
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
              padding: const EdgeInsets.only(left: 26.0, right: 26, top: 16),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.lightBlueGray,
                    width: 0.6,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildContactTab(
                        label: AppKeys.phoneNumber.tr(context),
                        isSelected: _isPhoneTabActive,
                        onTap: () => _switchContactTab(true),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _buildContactTab(
                        label: AppKeys.email.tr(context),
                        isSelected: !_isPhoneTabActive,
                        onTap: () => _switchContactTab(false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 16),
              child: Text(
                contactLabel,
                style: AppTextStyles.poppins70016,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 26.0, right: 26, top: 6, bottom: 20),
              child: _isPhoneTabActive
                  ? TextFormField(
                      controller: phoneNumberController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+251...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(13),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\+?[0-9]*$'),
                        ),
                      ],
                    )
                  : TextFormField(
                      controller: emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'example@gmail.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 28.0, right: 26, top: 10),
              child: Text(
                'Referal code (Opt)',
                style: AppTextStyles.poppins70016,
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

  Widget _buildContactTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.poppins60014.copyWith(
                color: isSelected ? AppColors.white : AppColors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
