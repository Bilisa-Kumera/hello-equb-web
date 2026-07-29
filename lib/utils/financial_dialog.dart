import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';

import 'style_constants.dart';

class FinancialDialog extends StatefulWidget {
  final String title;
  final String selectedBank;
  final String accountHolderName;
  final String accountNumber;
  final List<String> banks;
  bool? isUpdate;
  final Function(String bankId, String accountName, String accountNumber)
      onSubmit;

  FinancialDialog({
    super.key,
    required this.title,
    required this.selectedBank,
    required this.accountHolderName,
    required this.accountNumber,
    required this.banks,
    required this.onSubmit,
    this.isUpdate,
  });

  @override
  _FinancialDialogState createState() => _FinancialDialogState();
}

class _FinancialDialogState extends State<FinancialDialog> {
  late String selectedBank;
  late TextEditingController accountHolderNameController;
  late TextEditingController accountNumberController;
  late int selectedBankIndex;

  @override
  void initState() {
    super.initState();
    selectedBank = widget.selectedBank;
    accountHolderNameController =
        TextEditingController(text: widget.accountHolderName);
    accountNumberController = TextEditingController(text: widget.accountNumber);
    selectedBankIndex = widget.banks.indexOf(widget.selectedBank);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Text(
              widget.title,
              textScaleFactor: 1.0,
              style: AppTextStyles.poppins70020
                  .copyWith(color: AppColors.white),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Bank',
                  textScaleFactor: 1.0,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 5),
                DropdownButtonFormField<int>(
                  value: selectedBankIndex,
                  decoration: InputDecoration(
                    hintText: 'Select bank',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  items: List.generate(widget.banks.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        widget.banks[index],
                        textScaleFactor: 1.0,
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }),
                  onChanged: (int? newValue) {
                    setState(() {
                      selectedBankIndex = newValue!;
                      selectedBank = widget.banks[newValue];
                    });
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Account Holder Name',
                  textScaleFactor: 1.0,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountHolderNameController,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                Text(
                  'Enter Account No.',
                  textScaleFactor: 1.0,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    widget.onSubmit(
                      widget.banks[selectedBankIndex],
                      accountHolderNameController.text,
                      accountNumberController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.white,
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    widget.isUpdate ?? false ? 'Update' : 'Submit',
                    textScaleFactor: 1.0,
                    style: AppTextStyles.buttonLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
