import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final double borderWidth;
  final String hintText;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? initialValue;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.borderWidth,
    required this.hintText,
    required this.controller,
    this.onChanged,
    this.initialValue,
    this.keyboardType = TextInputType.name,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    if (initialValue != null) {
      controller.text = initialValue!;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.darkOverlay,
          width: borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TextField(
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
            hintStyle: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.coolGray,
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final double borderWidth;
  final TextEditingController controller;
  final String hintText;

  const PasswordTextField(
      {Key? key,
      required this.width,
      required this.height,
      required this.borderRadius,
      required this.borderWidth,
      required this.controller,
      required this.hintText})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PasswordTextFieldState createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.grey50 ,
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: AppColors.lightBlueGray,
          width: widget.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TextField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: InputBorder.none,
            hintStyle: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 15,
              color: AppColors.coolGray,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: AppColors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NineDigitInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text
        .replaceAll(RegExp(r'[^\d]'), ''); // Remove non-digit characters
    if (newText.length > 9) {
      // Truncate to 9 digits if more than 9 characters are entered
      return TextEditingValue(text: newText.substring(0, 9));
    }
    return newValue.copyWith(text: newText);
  }
}
