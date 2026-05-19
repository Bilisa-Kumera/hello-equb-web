// ignore_for_file: library_private_types_in_public_api

import 'dart:typed_data';

import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomInputDialog extends StatefulWidget {
  const CustomInputDialog({super.key});

  @override
  _CustomInputDialogState createState() => _CustomInputDialogState();
}

class _CustomInputDialogState extends State<CustomInputDialog> {
  final TextEditingController _amountController = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    final pickedBytes =
        pickedImage == null ? null : await pickedImage.readAsBytes();
    setState(() {
      _image = pickedImage;
      _imageBytes = pickedBytes;
    });
  }

  Future<void> _takePhoto() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.camera);
    final pickedBytes =
        pickedImage == null ? null : await pickedImage.readAsBytes();
    setState(() {
      _image = pickedImage;
      _imageBytes = pickedBytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      contentPadding: const EdgeInsets.all(20),
      title: const Text(
          textScaleFactor: 1.0,
          'Submit Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          _imageBytes != null
              ? Image.memory(
                  _imageBytes!,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                )
              : const Text(textScaleFactor: 1.0, 'No image selected'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text(textScaleFactor: 1.0, 'Gallery'),
              ),
              TextButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera),
                label: const Text(textScaleFactor: 1.0, 'Camera'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              // Handle submission logic
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary, // Background color
              backgroundColor: AppColors.white, // Text color
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(textScaleFactor: 1.0, 'Submit'),
          ),
        ],
      ),
    );
  }
}
