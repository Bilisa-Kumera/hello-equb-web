import 'package:flutter/material.dart';

class OtpBox extends StatefulWidget {
  final TextEditingController controller;

  const OtpBox({Key? key, required this.controller}) : super(key: key);

  @override
  _OtpBoxState createState() => _OtpBoxState();
}

class _OtpBoxState extends State<OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      if (widget.controller.text.length == 1) {
        // Move focus to the next box when a number is entered
        FocusScope.of(context).nextFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60.0,
      height: 50.0,
      child: TextField(
        style:  TextStyle(
            fontFamily: 'Urbanist', fontSize: 16, fontWeight: FontWeight.w700),
        controller: widget.controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          // Remove the character count display
          counterText: '',
        ),
      ),
    );
  }
}
