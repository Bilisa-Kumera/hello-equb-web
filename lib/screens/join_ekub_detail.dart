// ignore_for_file: deprecated_member_use

import 'package:dio/dio.dart';
import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/core/amharic_translations.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/join_ekub_confirmation.dart';
import 'package:helloequb/screens/payment_arrangement_screen.dart';
import 'package:helloequb/screens/payment_screen.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/custom_button.dart';
import 'package:helloequb/utils/custom_snack_bar.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:intl/intl.dart';

import '../utils/custom_appbar.dart';
import '../utils/equb_date_utils.dart';
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

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
      };

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
    );
  }
}

class EqubDetail extends StatelessWidget {
  final dynamic equb;
  const EqubDetail({super.key, required this.equb});

  /// Calendar-day Gregorian label (avoids UTC→local off-by-one).
  String _formatGregorianCalendarDay(DateTime? date) {
    if (date == null) return 'TBD';
    final local = date.toLocal();
    return DateFormat('MMM dd, yyyy')
        .format(DateTime(local.year, local.month, local.day));
  }

  @override
  Widget build(BuildContext context) {
    final display = combineEthiopianGregorianDisplay(
      ethiopianDate: equb?.ethiopianStartDate?.toString(),
      gregorianDateStr: equb?.startDate?.toString(),
      formatGregorian: _formatGregorianCalendarDay,
    );

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
                  display == '-' ? 'TBD' : display,
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
  /// True when user already holds a half/quarter in this equb → no rejoin.
  bool hasPartialShare = false;
  bool _isOpeningPayment = false;

  final DataController dataController = DataController();

  int joinedAmount = 0;

  bool get _blockedFromJoinAgain => hasJoinedBefore && hasPartialShare;
  bool get _fullOnlyRejoin => hasJoinedBefore && !hasPartialShare;

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
        final raw = response.data['data'];
        final list = raw is List ? raw : <dynamic>[];
        final stakes = list
            .map((e) =>
                double.tryParse((e is Map ? e['stake'] : null)?.toString() ??
                        '100') ??
                100.0)
            .toList();
        setState(() {
          joinedAmount = list.length;
          hasPartialShare = stakes.any((s) => s < 99.5);
          if (list.isNotEmpty) {
            hasJoinedBefore = true;
          }
          if (hasPartialShare) {
            items = [];
            _showStakeList = false;
          } else if (list.isNotEmpty) {
            // Rejoin after full only — keep a single Full row.
            _seedDefaultStake();
          }
        });
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
    selectedValue = '1';
    final amount = _amountForShare('1');
    equivalentEtb = amount;
    equivalentController.text = numberFormat.format(amount);
    items = [
      ListItem(title: '1', subtitle: numberFormat.format(amount)),
    ];
    _showStakeList = true;
  }

  double _amountForShare(String share) {
    final base = double.parse(widget.equb.equbAmount.toString());
    if (share == '1') return base;
    final parts = share.split('/');
    if (parts.length == 2) {
      final denom = int.tryParse(parts[1]) ?? 1;
      return base / denom;
    }
    return base;
  }

  void _updateItemShare(int index, String share) {
    setState(() {
      final amount = _amountForShare(share);
      // Half/quarter: only one share row allowed in this join.
      if (share != '1' && items.length > 1) {
        items = [
          ListItem(title: share, subtitle: numberFormat.format(amount)),
        ];
      } else {
        items[index] = ListItem(
          title: share,
          subtitle: numberFormat.format(amount),
        );
      }
      selectedValue = share;
      equivalentEtb = amount;
      equivalentController.text = numberFormat.format(amount);
    });
  }

  /// Weekly equbs use groupLimit 4 → Full / Half / Quarter.
  /// Other equbs use groupLimit 1 → Full only.
  /// Rejoin after full → Full only. Partial rejoin blocked elsewhere.
  List<String> get _shareOptions {
    if (_fullOnlyRejoin) return ['1'];
    final limit = widget.equb.groupLimit ?? 1;
    final options = <String>['1'];
    if (limit >= 2) options.add('1/2');
    if (limit >= 4) options.add('1/4');
    return options;
  }

  static const int _maxSelectableShares = 5;

  /// Cap at 5 full shares, or fewer if the equb has fewer total / open slots.
  int get _maxSharesAllowed {
    final total = widget.equb.numberOfEqubers ?? 0;
    final filled = widget.equb.equbers?.length ?? 0;
    if (total <= 0) return _maxSelectableShares;
    final remaining = (total - filled).clamp(0, total);
    final bySize = total < _maxSelectableShares ? total : _maxSelectableShares;
    final byRemaining =
        remaining < _maxSelectableShares ? remaining : _maxSelectableShares;
    final cap = bySize < byRemaining ? bySize : byRemaining;
    return cap < 1 ? 0 : cap;
  }

  bool get _canAddAnotherShare {
    if (_blockedFromJoinAgain) return false;
    if (items.any((i) => i.title != '1')) return false;
    return items.length < _maxSharesAllowed;
  }

  String _shareLabel(String value) {
    switch (value) {
      case '1':
        return '1 ${AppKeys.fullShare.tr(context)}';
      case '1/2':
        return '1/2 ${AppKeys.halfShare.tr(context)}';
      case '1/4':
        return '1/4 ${AppKeys.quarterShare.tr(context)}';
      default:
        return AppKeys.yourShare.tr(context);
    }
  }

  String _shareShortLabel(String value) {
    switch (value) {
      case '1':
        return AppKeys.full.tr(context);
      case '1/2':
        return AppKeys.half.tr(context);
      case '1/4':
        return AppKeys.quarter.tr(context);
      default:
        return value;
    }
  }

  bool _looksLikeUuid(String value) {
    return RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(value.trim());
  }

  String _resolveEqubPeriodRaw() {
    final candidates = <String?>[
      widget.equb.equbType?['name']?.toString(),
      widget.equb.equbType?['Name']?.toString(),
      widget.equbType,
    ];
    for (final c in candidates) {
      if (c == null || c.trim().isEmpty) continue;
      final lower = c.trim().toLowerCase();
      if (lower == 'weekly' || lower == 'daily' || lower == 'monthly') {
        return lower;
      }
    }
    for (final c in candidates) {
      if (c == null || c.trim().isEmpty) continue;
      if (_looksLikeUuid(c)) continue;
      return c.trim();
    }
    return '';
  }

  String _translatedEqubPeriod([String? type]) {
    final raw = (type ?? _resolveEqubPeriodRaw()).toLowerCase();
    switch (raw) {
      case 'weekly':
        return AppKeys.weekly.tr(context);
      case 'daily':
        return AppKeys.daily.tr(context);
      case 'monthly':
        return AppKeys.monthly.tr(context);
      default:
        return type ?? _resolveEqubPeriodRaw();
    }
  }

  String _shareGlyph(String value) {
    switch (value) {
      case '1/2':
        return '½';
      case '1/4':
        return '¼';
      default:
        return '1';
    }
  }

  void _addItem(String selected, String equivalent) {
    if (!_canAddAnotherShare && items.isNotEmpty) return;
    setState(() {
      _showStakeList = true;
      items.add(ListItem(title: selected, subtitle: equivalent));
    });
  }

  void _addShareRow() {
    if (!_canAddAnotherShare) {
      final atShareCap = items.length >= _maxSharesAllowed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _blockedFromJoinAgain
                ? AppKeys.cannotJoinAgainPartial.tr(context)
                : atShareCap
                    ? 'You can select up to $_maxSharesAllowed Equb(s) for this join.'
                    : AppKeys.fullOnlyRejoin.tr(context),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final share = '1';
    final amount = _amountForShare(share);
    _addItem(share, numberFormat.format(amount));
  }

  void _showPartialJoinBlocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppKeys.cannotJoinAgainPartial.tr(context)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      if (items.length <= 1) return;
      items.removeAt(index);
    });
  }

  /// Opens Payment Arrangement for this equb with freshly fetched round/amounts.
  Future<void> _openCurrentEqubPayment() async {
    final equbId = widget.equb.id ?? '';
    if (equbId.isEmpty || _isOpeningPayment) return;

    setState(() => _isOpeningPayment = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final token = await SecureStorageHelper.getAccessToken() ?? '';
      final res = await Dio().get(
        ekubPaymentsUrl + equbId,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (res.statusCode != 200 && res.statusCode != 201) {
        setState(() => _isOpeningPayment = false);
        CustomSnackBar.show(
          context,
          AppKeys.noData.tr(context),
          Colors.red,
        );
        return;
      }

      final ekubRound = res.data['data']['equbRound']?.toString() ??
          widget.equb.nextRound?.toString() ??
          '1';
      final numberOfEqubers = int.tryParse(
              res.data['data']['numberOfEqubers']?.toString() ?? '') ??
          widget.equb.numberOfEqubers ??
          0;
      final payments = ((res.data['data']['payments'] as List?) ?? [])
          .map((e) => Payment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final listItemss = <ListItems>[];
      final listItems = <ListItem>[];
      for (final p in payments) {
        final isFullyPaid =
            p.fullyPaid || p.isFullyPaidForEqub(numberOfEqubers);
        final initialAmount = p.remainingPaymentAmount(numberOfEqubers);

        listItemss.add(ListItems(
          title: p.lotteryNumber,
          subtitle: initialAmount.toString(),
          userIds: p.equbersId,
          roundAmount: p.equbAmount,
          isFullyPaid: isFullyPaid,
          maxPayableAmount: p.maxRemainingPayable(numberOfEqubers),
          stake: p.stake,
          paidRound: p.paidRound,
          defaultAmount: initialAmount,
        ));
        listItems.add(ListItem(
          title: p.lotteryNumber,
          subtitle: initialAmount.toString(),
        ));
      }

      if (listItems.isEmpty) {
        setState(() => _isOpeningPayment = false);
        CustomSnackBar.show(
          context,
          AppKeys.noData.tr(context),
          Colors.red,
        );
        return;
      }

      final expected =
          listItemss.fold<double>(0, (s, e) => s + double.parse(e.subtitle));

      if (!mounted) return;
      setState(() => _isOpeningPayment = false);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentArragement(
            selectedJoinOption: listItems,
            selectedJoinOptions: listItemss,
            ekubAmount: widget.equb.equbAmount.toString(),
            ekubId: equbId,
            ekubName: widget.equb.name,
            ekubRound: ekubRound,
            round: ekubRound,
            expectedAmount: expected,
            type: 'payment',
            numberOfEqubers: numberOfEqubers.toString(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isOpeningPayment = false);
      CustomSnackBar.show(
        context,
        AppKeys.enableInternet.tr(context),
        Colors.red,
      );
    }
  }

  void _proceedToJoinConfirmation() {
    if (_blockedFromJoinAgain) {
      _showPartialJoinBlocked();
      return;
    }
    if (_fullOnlyRejoin && items.any((i) => i.title != '1')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppKeys.fullOnlyRejoin.tr(context)),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final stakes = items.isNotEmpty
        ? items
        : [
            ListItem(
              title: '1',
              subtitle: numberFormat.format(_amountForShare('1')),
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
          equbType: _resolveEqubPeriodRaw(),
          ekubDescription: widget.equb.description ?? '',
          ekubId: widget.equb.id ?? '',
          ekubAmount: widget.equb.equbAmount.toString(),
          ekubName: widget.equb.name ?? '',
          ekubRound: widget.equb.nextRound.toString(),
          groupLimit: widget.equb.groupLimit.toString(),
          joinedAmount: widget.equb.equbers?.length.toString() ?? '',
          type: _resolveEqubPeriodRaw(),
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
              equivalentController.text =
                  numberFormat.format(equivalentEtb);
              // Keep the default stake line in sync when not multi-adding.
              if (!_showStakeList) {
                items = [
                  ListItem(
                    title: selectedValue,
                    subtitle: equivalentController.text,
                  ),
                ];
              }
            });
          },
          itemBuilder: (BuildContext context) {
            return _shareOptions.map<PopupMenuItem<String>>((String value) {
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
                            _shareGlyph(value),
                            style: AppTextStyles.poppins60014,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _shareLabel(value),
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
                          _shareGlyph(selectedValue),
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
                          AppKeys.shareAmount.tr(context),
                          style: AppTextStyles.poppins50011
                              .copyWith(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _shareLabel(selectedValue),
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

  /// Compact share picker inside each lottery row.
  Widget _buildRowShareDropdown(int index, String currentShare) {
    final canChoose = _shareOptions.length > 1;
    if (!canChoose) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
        ),
        child: Text(
          _shareLabel(currentShare),
          style: AppTextStyles.poppins60012.copyWith(color: AppColors.primary),
        ),
      );
    }

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 36),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => _updateItemShare(index, value),
      itemBuilder: (context) {
        final options = _shareOptions;
        return [
          for (var i = 0; i < options.length; i++)
            PopupMenuItem<String>(
              value: options[i],
              padding: EdgeInsets.fromLTRB(
                  10, i == 0 ? 10 : 4, 10, i == options.length - 1 ? 10 : 4),
              height: 48,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: options[i] == currentShare
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: options[i] == currentShare
                        ? AppColors.primary.withOpacity(0.55)
                        : Colors.grey.shade300,
                    width: options[i] == currentShare ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shareLabel(options[i]),
                        style: AppTextStyles.poppins60012.copyWith(
                          color: options[i] == currentShare
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (options[i] == currentShare)
                      const Icon(Icons.check_circle,
                          size: 18, color: AppColors.primary)
                    else
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
        ];
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 148, minHeight: 40),
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _shareLabel(currentShare),
                style: AppTextStyles.poppins60012
                    .copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListItem(int index) {
    final item = items[index];
    final amount = double.tryParse(item.subtitle.replaceAll(',', '')) ?? 0.0;
    final share = item.title;

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
            width: 28,
            height: 28,
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
          SizedBox(width: 20.w),
          _buildRowShareDropdown(index, share),
          const Spacer(),
          Text(
            'ETB ${numberFormat.format(amount)}',
            style: AppTextStyles.poppins70014.copyWith(color: AppColors.primary),
          ),
          if (items.length > 1) ...[
            const SizedBox(width: 6),
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
                        if (!_blockedFromJoinAgain)
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
                          if (!_blockedFromJoinAgain) SizedBox(height: 8.h),
                          OutlinedButton(
                            onPressed:
                                _isOpeningPayment ? null : _openCurrentEqubPayment,
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
                children: [
                  Text(
                    AppKeys.yourShare.tr(context),
                    style: AppTextStyles.poppins60014
                        .copyWith(color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          () {
                            final period = _translatedEqubPeriod();
                            final label = AppKeys.expectedAmount.tr(context);
                            return period.isEmpty
                                ? label
                                : '$label $period';
                          }(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.poppins60011
                              .copyWith(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (_blockedFromJoinAgain)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    AppKeys.cannotJoinAgainPartial.tr(context),
                    style: AppTextStyles.poppins50013.copyWith(
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),
                )
              else ...[
                ...items.asMap().entries.map((entry) {
                  return _buildModernListItem(entry.key);
                }),
                if (_canAddAnotherShare)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _addShareRow,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(AppKeys.addAnotherShare.tr(context)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          backgroundColor: AppColors.primary.withOpacity(0.08),
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
