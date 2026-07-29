// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

import 'secure_storage.dart';

import 'style_constants.dart';

Future<void> showBeautifulInputDialog(BuildContext context, String ekubId,
    {String? itemName, double? amount, String? reason, String? requestId}) {
  bool isUpdate = requestId != null;

  final TextEditingController itemNameController =
      TextEditingController(text: itemName ?? '');
  final TextEditingController reasonController =
      TextEditingController(text: reason ?? '');
  final TextEditingController amountController =
      TextEditingController(text: amount != null ? amount.toString() : '');

  final formKey = GlobalKey<FormState>();
  final Dio dio = Dio(); // Dio instance for network requests
  final DataController dataController = DataController();

  Future<void> submitRequest(
      String itemName, String amount, String reason) async {
    String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = isUpdate
          ? await dio.patch(
              requestUrl + requestId,
              options: Options(
                headers: {
                  if (bearerToken.isNotEmpty)
                    "Authorization": "Bearer $bearerToken",
                },
              ),
              data: {
                'itemName': itemName,
                'amount': amount,
                'description': reason,
              },
            )
          : await dio.post(
              requestUrl + ekubId,
              options: Options(
                headers: {
                  if (bearerToken.isNotEmpty)
                    "Authorization": "Bearer $bearerToken",
                },
              ),
              data: {
                'itemName': itemName,
                'amount': amount,
                'description': reason,
              },
            );

      if (response.statusCode == 200) {
        // Handle success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text(textScaleFactor: 1.0, 'Request submitted successfully!'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        // Handle non-200 responses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                textScaleFactor: 1.0,
                'Failed to submit request: ${response.statusMessage}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } on DioError catch (e) {
      // Handle Dio-specific errors (e.g., network issues)
      String errorMessage = e.response?.data['message'] ?? e.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(textScaleFactor: 1.0, 'Error: $errorMessage'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      // Handle general exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(textScaleFactor: 1.0, 'An unexpected error occurred.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Rounded edges
            ),
            title: Text(
              textScaleFactor: 1.0,
              !isUpdate ? 'Submit Request' : "Update Request",
              style: AppTextStyles.dialogTitle
                  .copyWith(color: AppColors.primary),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      textScaleFactor: 1.0,
                      'Item Name:',
                      style: AppTextStyles.poppins50016
                          .copyWith(color: AppColors.neutralGray),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: itemNameController,
                      decoration: InputDecoration(
                        labelText: 'Please enter item name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Item name cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      textScaleFactor: 1.0,
                      'Item Price:',
                      style: AppTextStyles.poppins50016
                          .copyWith(color: AppColors.neutralGray),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Please enter amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Amount cannot be empty';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      textScaleFactor: 1.0,
                      'Request Reason:',
                      style: AppTextStyles.poppins50016
                          .copyWith(color: AppColors.neutralGray),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason for request',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      maxLines: 3, // Allow multiline input for reasons
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Reason cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    // If form is valid, make the Dio POST request
                    submitRequest(
                      itemNameController.text,
                      amountController.text,
                      reasonController.text,
                    );
                    Navigator.of(context).pop();
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  textScaleFactor: 1.0,
                  isUpdate ? 'Update' : 'Submit',
                  style: AppTextStyles.onPrimaryBold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  textScaleFactor: 1.0,
                  'Cancel',
                  style: AppTextStyles.poppins70016
                      .copyWith(color: AppColors.red),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
