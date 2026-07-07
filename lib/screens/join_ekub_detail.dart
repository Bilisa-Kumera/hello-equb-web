// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/screens/allequb_payment.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/amharic_translations.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/join_ekub_confirmation.dart';
import 'package:helloequb/screens/payment_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:intl/intl.dart';

import '../utils/custom_appbar.dart';
import '../utils/getx_storage_custom.dart';
import '../utils/secure_storage.dart';
import 'my_ekub_detail_screen.dart';

class EqubJoinDetail extends StatefulWidget {
  final EqubModel equb;
  final String equbType;

  const EqubJoinDetail({super.key, required this.equb, required this.equbType});

  @override
  State<EqubJoinDetail> createState() => _EqubJoinDetailState();
}

class ListItem {
  final String title;
  String subtitle;

  ListItem({required this.title, required this.subtitle});
}

class EqubDetail extends StatelessWidget {
  final dynamic equb;
  const EqubDetail({super.key, required this.equb});

  String _formatDate(String? dateStr, bool isEthiopianDate) {
    if (dateStr == null || dateStr.isEmpty) return 'TBD';

    try {
      final dateOnly = dateStr.split(' ').first;
      final parts = dateOnly.split(RegExp(r'[-/]'));

      if (parts.length < 3) return dateStr;

      final year = int.tryParse(parts[0]) ?? 0;
      final month = int.tryParse(parts[1]) ?? 1;
      final day = int.tryParse(parts[2]) ?? 1;

      if (isEthiopianDate) {
        const months = [
          "መስከረም",
          "ጥቅምት",
          "ኅዳር",
          "ታኅሣሥ",
          "ጥር",
          "የካቲት",
          "መጋቢት",
          "ሚያዝያ",
          "ግንቦት",
          "ሰኔ",
          "ሐምሌ",
          "ነሐሴ",
          "ጳጉሜን"
        ];

        final monthName =
            (month >= 1 && month <= 13) ? months[month - 1] : parts[1];

        return "$monthName $day, $year";
      } else {
        final dt = DateTime.parse(dateStr);
        return DateFormat('MMM dd, yyyy').format(dt);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = equb?.name ?? 'Equb';
    final description = equb?.description ?? 'No description provided';
    final startDate = _formatDate(equb?.startDate ?? '', false);
    final ethiopianStartDate =
        _formatDate(equb?.ethiopianStartDate ?? '', true);
    (equb?.equbers?.length ?? 0).toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.forestGreenDark.withOpacity(0.1),
                      AppColors.richDeepGreen.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.forestGreenDark.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 20,
                            color: AppColors.forestGreenDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.black87,
                            height: 1.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Modern info tile with better visual hierarchy
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppKeys.expectedStartDate.tr(context),
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$ethiopianStartDate ($startDate)",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EqubJoinDetailState extends State<EqubJoinDetail> {
  String selectedValue = '1';

  double equivalentEtb = 0;
  double expectedAmount = 0;

  bool hasJoinedBefore = false;
  bool isCheckingJoinStatus = true;

  final DataController dataController = DataController();

  int joinedAmount = 0;

  Future<void> fetchCheckUserEqub(ekubId) async {
    String? userId = await SecureStorageHelper.getUserId();
    final String url = '$baseUrl/user/equb/userEqub/$ekubId/$userId';
    try {
      final response = await Dio().get(url,
          options: Options(headers: {
            "Authorization":
                "Bearer ${await SecureStorageHelper.getAccessToken()}"
          }));
      if (response.statusCode == 200) {
        final responseData = response.data;
        setState(() {
          joinedAmount = response.data['data'].length;
        });
        if (responseData['data'] == null) {
        } else {
          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => const MyEkubScreen()));
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {}
  }

  Future<void> fetchCheckJoinStatus() async {
    try {
      final String url = checkJoinUrl;
      final String? bearerToken = await SecureStorageHelper.getAccessToken();
      final Dio dio = Dio();
      final response = await dio.post(
        url,
        data: {'equbId': widget.equb.id ?? ''},
        options: Options(headers: {
          'Authorization': 'Bearer ${bearerToken ?? ''}',
          'Content-Type': 'application/json',
        }),
      );

      if (response.statusCode == 200 && response.data != null) {
        final resp = response.data as Map<String, dynamic>;
        if (resp['status'] == 'success') {
          setState(() {
            hasJoinedBefore = resp['data']?['joined'] == true;
          });
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('checkJoinStatus error: $e');
    } finally {
      setState(() {
        isCheckingJoinStatus = false;
      });
    }
  }

  NumberFormat numberFormat = NumberFormat.decimalPattern('en_us');

  @override
  void initState() {
    equivalentEtb = double.parse(widget.equb.equbAmount.toString());
    super.initState();
    fetchCheckUserEqub(widget.equb.id);
    fetchCheckJoinStatus();
    equivalentController = TextEditingController(
        text: numberFormat
            .format(double.parse(widget.equb.equbAmount.toString())));
  }

  TextEditingController equivalentController = TextEditingController();
  int numbers = 0;

  List<ListItem> items = [];
  void _addItem(String selected, String equivalent) {
    setState(() {
      items.add(ListItem(title: selected, subtitle: equivalent));
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  Widget _buildModernDropdown() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: PopupMenuButton<String>(
          offset: const Offset(0, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          elevation: 8,
          initialValue: selectedValue,
          onSelected: (String? newValue) {
            setState(() {
              selectedValue = newValue!;
              if (newValue == '1') {
                equivalentEtb = double.parse(widget.equb.equbAmount.toString());
              } else {
                equivalentEtb = (1 / int.parse(newValue.split('/')[1])) *
                    double.parse(widget.equb.equbAmount.toString());
              }
              equivalentController.text = equivalentEtb.toStringAsFixed(2);
            });
          },
          itemBuilder: (BuildContext context) {
            return <String>[
              for (int i = 0; i < (widget.equb.groupLimit ?? 0); i++)
                i == 0 ? '1' : '1/${i + 1}'
            ].map<PopupMenuItem<String>>((String value) {
              return PopupMenuItem<String>(
                value: value,
                height: 48,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: value == selectedValue
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            value.contains('/') ? '½' : '1',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: value == selectedValue
                                  ? AppColors.primary
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        value == '1'
                            ? 'Full Share (1x)'
                            : 'Partial Share ($value)',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: value == selectedValue
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: value == selectedValue
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                      if (value == selectedValue) ...[
                        const Spacer(),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          selectedValue.contains('/') ? '½' : '1',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Share Amount',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedValue == '1' ? 'Full Share' : selectedValue,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey.shade600,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernAmountField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'ETB',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: TextField(
              enabled: false,
              controller: equivalentController,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAddButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _addItem(selectedValue, equivalentController.text),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernListItem(int index) {
    final item = items[index];
    final amount = double.tryParse(item.subtitle.replaceAll(',', '')) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.forestGreenDark.withOpacity(0.1),
                  AppColors.richDeepGreen.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestGreenDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppKeys.yourShare.tr(context),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ETB ${numberFormat.format(amount)}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _removeItem(index),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    expectedAmount = 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 16,
        ),
        child: SafeArea(
          child: isCheckingJoinStatus
            ? const Center(child: CircularProgressIndicator())
            : (hasJoinedBefore
              ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
               Text(
                  AppKeys.alreadyJoined.tr(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextButton(
                  text: AppKeys.payment.tr(context),
                  onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => const PaymentList(
                    ),
                    ),
                  );
                  },
                ),
                ],
              )
              : CustomTextButton(
                text: AppKeys.join.tr(context),
                onPressed: () {
                if (items.isEmpty) {
                  items.add(ListItem(
                  title: selectedValue,
                  subtitle: equivalentController.text,
                  ));
                }
                expectedAmount = 0;
                for (var item in items) {
                  expectedAmount +=
                    double.tryParse(item.subtitle.replaceAll(',', '')) ??
                      0.0;
                }

                items.isNotEmpty
                  ? Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JoinEkubConfirmation(
                          termAndCondition:
                            widget.equb.termAndCondition ?? '',
                          termAndConditionInAmharic:
                            widget.equb.termAndConditionInAmharic ??
                              '',
                          equbType:
                            widget.equb.equbType?['name'] ?? '',
                          ekubDescription:
                            widget.equb.description ?? '',
                          ekubId: widget.equb.id ?? '',
                          ekubAmount: widget.equb.equbAmount.toString(),
                          ekubName: widget.equb.name ?? '',
                          ekubRound:
                            widget.equb.nextRound.toString(),
                          groupLimit:
                            widget.equb.groupLimit.toString(),
                          joinedAmount:
                            widget.equb.equbers?.length.toString() ??
                              '',
                          type:
                            widget.equb.equbType?['name'] ?? '',
                          items: items,
                          expectedAmount: expectedAmount,
                          startDate: widget.equb.startDate ?? '',
                          numberOfEkubers:
                            widget.equb.numberOfEqubers.toString(),
                        )))
                  : Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => JoinEkubConfirmation(
                          termAndCondition:
                            widget.equb.termAndCondition ?? '',
                          termAndConditionInAmharic:
                            widget.equb.termAndConditionInAmharic ??
                              '',
                          equbType:
                            widget.equb.equbType?['name'],
                          ekubDescription:
                            widget.equb.description ?? '',
                          ekubId: widget.equb.id ?? '',
                          ekubAmount: widget.equb.equbAmount.toString(),
                          ekubName: widget.equb.name ?? '',
                          ekubRound:
                            widget.equb.nextRound.toString(),
                          groupLimit:
                            widget.equb.groupLimit.toString(),
                          joinedAmount:
                            widget.equb.equbers?.length.toString() ??
                              '',
                          type:
                            widget.equb.equbType?['name'],
                          items: items,
                          expectedAmount: expectedAmount,
                          startDate: widget.equb.startDate ?? '',
                          numberOfEkubers:
                            widget.equb.numberOfEqubers.toString(),
                        )));
                },
              )),
        ),
      ),
      appBar: CurvedAppBar(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Card(
              elevation: 8,
              shadowColor: AppColors.forestGreenDark.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.forestGreenDark,
                      AppColors.richDeepGreen,
                      AppColors.forestGreenDark.withOpacity(0.9),
                    ],
                  ),
                ),
                height: 110,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.loop_rounded,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.equb.numberOfEqubers.toString(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 12.sp,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.equb.name ?? '',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ETB ${numberFormat.format(
                                int.tryParse(
                                        widget.equb.equbAmount.toString())! *
                                    int.tryParse(widget.equb.numberOfEqubers
                                        .toString())!,
                              )}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),

              joinedAmount != 0
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                try {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyEkubDetailScreen(
                                        ekubType:
                                            widget.equb.equbType?.values.first,
                                        ekubAmount: widget.equb.equbAmount ?? 0,
                                        ekubCycle: 3,
                                        ekubId: widget.equb.id ?? '',
                                        ekubName: widget.equb.name ?? '',
                                        ekubRequest: true,
                                        ekubersNumber: 2,
                                        nextRoundDate:
                                            widget.equb.nextRoundDate ?? '',
                                        nextRoundLotteryType:
                                            widget.equb.nextRoundLotteryType ??
                                                '',
                                        nextRoundTime:
                                            widget.equb.nextRoundTime ?? '',
                                        serviceCharge: widget.equb.serviceCharge
                                            .toString(),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Invalid input values. Please check the ekub details.'),
                                      backgroundColor: AppColors.red,
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${AppKeys.youHaveJoined.tr(context)} $joinedAmount ${AppKeys.lotteriesBefore.tr(context)}',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.sp,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppKeys.tapToViewDetails.tr(context),
                                    style: TextStyle(
                                      color: AppColors.primary.withOpacity(0.7),
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.primary.withOpacity(0.5),
                            size: 16,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),

              const SizedBox(height: 8),

              // Equb Detail Card
              EqubDetail(equb: widget.equb),

              SizedBox(height: 24.h),

              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppKeys.yourShare.tr(context),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      fontSize: 16.sp,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${AppKeys.expectedAmount.tr(context)} ${widget.equbType.toLowerCase() == 'weekly' ? AppKeys.weekly.tr(context) : widget.equbType.toLowerCase() == 'daily' ? AppKeys.daily.tr(context) : widget.equbType.toLowerCase() == 'monthly' ? AppKeys.monthly.tr(context) : widget.equb.equbType?['name']}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ...items.asMap().entries.map((entry) {
                return _buildModernListItem(entry.key);
              }),

              Container(
                margin:
                    EdgeInsets.only(top: items.isNotEmpty ? 8 : 0, bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        AppKeys.addNewStake.tr(context),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Expanded(
                        //   flex: 2,
                        //   child: _buildModernDropdown(),
                        // ),
                        // const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _buildModernAmountField(),
                        ),
                        const SizedBox(width: 12),
                        _buildModernAddButton(),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
