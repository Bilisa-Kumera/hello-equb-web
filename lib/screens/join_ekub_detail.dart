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
import 'package:helloequb/utils/style_constants.dart';

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
    final startDate = _formatDate(equb?.startDate ?? '', false);
    final ethiopianStartDate =
        _formatDate(equb?.ethiopianStartDate ?? '', true);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppKeys.expectedStartDate.tr(context),
                  style: AppTextStyles.poppins60011.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$ethiopianStartDate ($startDate)",
                  style: AppTextStyles.poppins60013
                      .copyWith(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
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
    _seedDefaultStake();
  }

  TextEditingController equivalentController = TextEditingController();
  int numbers = 0;

  List<ListItem> items = [];
  bool _showStakeList = false;

  void _seedDefaultStake() {
    final amount = numberFormat.format(
      double.parse(widget.equb.equbAmount.toString()),
    );
    items = [ListItem(title: selectedValue, subtitle: amount)];
  }

  void _addItem(String selected, String equivalent) {
    setState(() {
      if (!_showStakeList) {
        _showStakeList = true;
      }
      items.add(ListItem(title: selected, subtitle: equivalent));
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      if (items.isEmpty || items.length == 1) {
        if (items.isEmpty) {
          _seedDefaultStake();
        }
        _showStakeList = false;
      }
    });
  }

  void _proceedToJoinConfirmation() {
    final stakes = _showStakeList
        ? items
        : [
            ListItem(
              title: items.isNotEmpty ? items.first.title : selectedValue,
              subtitle: items.isNotEmpty
                  ? items.first.subtitle
                  : equivalentController.text,
            ),
          ];
    expectedAmount = 0;
    for (var item in stakes) {
      expectedAmount +=
          double.tryParse(item.subtitle.replaceAll(',', '')) ?? 0.0;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JoinEkubConfirmation(
          termAndCondition: widget.equb.termAndCondition ?? '',
          termAndConditionInAmharic:
              widget.equb.termAndConditionInAmharic ?? '',
          equbType: widget.equb.equbType?['name'] ?? '',
          ekubDescription: widget.equb.description ?? '',
          ekubId: widget.equb.id ?? '',
          ekubAmount: widget.equb.equbAmount.toString(),
          ekubName: widget.equb.name ?? '',
          ekubRound: widget.equb.nextRound.toString(),
          groupLimit: widget.equb.groupLimit.toString(),
          joinedAmount: widget.equb.equbers?.length.toString() ?? '',
          type: widget.equb.equbType?['name'] ?? '',
          items: stakes,
          expectedAmount: expectedAmount,
          startDate: widget.equb.startDate ?? '',
          numberOfEkubers: widget.equb.numberOfEqubers.toString(),
        ),
      ),
    );
  }

  // Widget _buildJoinMembersProgress() {
  //   final total = widget.equb.numberOfEqubers ?? 0;
  //   final joined = widget.equb.equbers?.length ?? 0;
  //   final safeTotal = total <= 0 ? 1 : total;
  //   final safeJoined = joined.clamp(0, safeTotal);
  //   final progress = safeJoined / safeTotal;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Expanded(
  //             child: Text(
  //               AppKeys.membersFilled.tr(context),
  //               style: AppTextStyles.bodySmall.copyWith(
  //                 color: Colors.grey.shade700,
  //               ),
  //             ),
  //           ),
  //           Text(
  //             '$safeJoined / $total',
  //             style: AppTextStyles.labelSmall.copyWith(
  //               color: AppColors.primary,
  //               fontWeight: FontWeight.w700,
  //             ),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: 8.h),
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(8.r),
  //         child: LinearProgressIndicator(
  //           value: progress,
  //           minHeight: 8.h,
  //           backgroundColor: Colors.grey.shade200,
  //           valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  bool get _isEqubFilled {
    final total = widget.equb.numberOfEqubers ?? 0;
    final joined = widget.equb.equbers?.length ?? 0;
    return total > 0 && joined >= total;
  }

  void _showFilledMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppKeys.alreadyFilled.tr(context)),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                            style: AppTextStyles.poppins60014,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        value == '1'
                            ? 'Full Share (1x)'
                            : 'Partial Share ($value)',
                        style: AppTextStyles.poppins60014,
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
                          style: AppTextStyles.poppins70014
                              .copyWith(color: AppColors.primary),
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
                          style: AppTextStyles.poppins50011
                              .copyWith(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedValue == '1' ? 'Full Share' : selectedValue,
                          style: AppTextStyles.poppins60014
                              .copyWith(color: Colors.black87),
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
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'ETB',
              style: AppTextStyles.poppins60013
                  .copyWith(color: Colors.grey.shade500),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: TextField(
              enabled: false,
              controller: equivalentController,
              textAlign: TextAlign.left,
              style: AppTextStyles.poppins70014
                  .copyWith(color: Colors.black87),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                hintText: '0.00',
                hintStyle: AppTextStyles.poppins40014
                    .copyWith(color: Colors.grey.shade400),
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
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _addItem(selectedValue, equivalentController.text),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDefaultStake() {
    final amount = double.tryParse(
            equivalentController.text.replaceAll(',', '')) ??
        equivalentEtb;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '1',
                style: AppTextStyles.poppins70014
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppKeys.yourShare.tr(context),
              style: AppTextStyles.poppins60013.copyWith(color: Colors.black87),
            ),
          ),
          Text(
            'ETB ${numberFormat.format(amount)}',
            style: AppTextStyles.poppins70014.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildModernListItem(int index) {
    final item = items[index];
    final amount = double.tryParse(item.subtitle.replaceAll(',', '')) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: AppTextStyles.poppins70014
                    .copyWith(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppKeys.yourShare.tr(context),
              style: AppTextStyles.poppins60013.copyWith(color: Colors.black87),
            ),
          ),
          Text(
            'ETB ${numberFormat.format(amount)}',
            style: AppTextStyles.poppins70014.copyWith(color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _removeItem(index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade400,
                size: 18,
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
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 12,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // _buildJoinMembersProgress(),
              // SizedBox(height: 12.h),
              isCheckingJoinStatus
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasJoinedBefore) ...[
                          Text(
                            AppKeys.alreadyJoined.tr(context),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.captionMuted.copyWith(
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                        CustomTextButton(
                          text: _isEqubFilled
                              ? AppKeys.alreadyFilled.tr(context)
                              : hasJoinedBefore
                                  ? AppKeys.joinAgain.tr(context)
                                  : AppKeys.join.tr(context),
                          buttonColor: _isEqubFilled
                              ? Colors.grey.shade500
                              : AppColors.darkMutedGreen,
                          onPressed: _isEqubFilled
                              ? _showFilledMessage
                              : _proceedToJoinConfirmation,
                        ),
                        if (hasJoinedBefore) ...[
                          SizedBox(height: 8.h),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PaymentList(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Text(
                              AppKeys.payment.tr(context),
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ],
          ),
        ),
      ),
      appBar: CurvedAppBar(
        height: 148,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(color: AppColors.white60),
                    color: Colors.transparent,
                  ),
                  height: 72,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          textScaleFactor: 1.0,
                          widget.equb.name ?? '',
                          style: AppTextStyles.poppins60012
                              .copyWith(color: AppColors.white),
                        ),
                        SizedBox(
                          width: 160.w,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              textScaleFactor: 1.0,
                              numberFormat.format(
                                (int.tryParse(
                                            widget.equb.equbAmount.toString()) ??
                                        0) *
                                    (int.tryParse(widget.equb.numberOfEqubers
                                            .toString()) ??
                                        0),
                              ),
                              style: AppTextStyles.poppins70022
                                  .copyWith(color: AppColors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              joinedAmount != 0
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppKeys.youHaveJoined.tr(context)} $joinedAmount ${AppKeys.lotteriesBefore.tr(context)}',
                                  style: AppTextStyles.poppins70014.copyWith(
                                      color: AppColors.primary, height: 1.4),
                                ),
                                // const SizedBox(height: 4),
                                // Text(
                                //   AppKeys.tapToViewDetails.tr(context),
                                //   style: AppTextStyles.poppins40012
                                //       .copyWith(color: AppColors.primary),
                                // ),
                              ],
                            ),
                          ),
                          // Icon(
                          //   Icons.arrow_forward_ios_rounded,
                          //   color: AppColors.primary.withOpacity(0.5),
                          //   size: 16,
                          // ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),

              EqubDetail(equb: widget.equb),

              SizedBox(height: 12.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppKeys.yourShare.tr(context),
                    style: AppTextStyles.poppins60014
                        .copyWith(color: Colors.black87),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${AppKeys.expectedAmount.tr(context)} ${widget.equbType.toLowerCase() == 'weekly' ? AppKeys.weekly.tr(context) : widget.equbType.toLowerCase() == 'daily' ? AppKeys.daily.tr(context) : widget.equbType.toLowerCase() == 'monthly' ? AppKeys.monthly.tr(context) : widget.equb.equbType?['name']}',
                      style: AppTextStyles.poppins60011
                          .copyWith(color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (!_showStakeList) _buildCompactDefaultStake(),

              if (_showStakeList)
                ...items.asMap().entries.map((entry) {
                  return _buildModernListItem(entry.key);
                }),

              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _buildModernAmountField()),
                    const SizedBox(width: 10),
                    _buildModernAddButton(),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
