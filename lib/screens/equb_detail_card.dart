import 'package:dio/dio.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/equb_date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../utils/colors_constant.dart';
import '../utils/lang_constants.dart';
import '../utils/secure_storage.dart';
import '../widgets/equb_tile_card.dart';
import 'join_ekub_detail.dart';
import 'package:helloequb/utils/style_constants.dart';

/// Caches join-status checks so list tiles don't spam the API.
class _EqubJoinStatusCache {
  static final Map<String, bool> _cache = {};

  static Future<bool> isJoined(
    String equbId, {
    bool forceRefresh = false,
  }) async {
    if (equbId.isEmpty) return false;
    if (!forceRefresh && _cache[equbId] == true) return true;

    try {
      final token = await SecureStorageHelper.getAccessToken() ?? '';
      final response = await Dio().post(
        checkJoinUrl,
        data: {'equbId': equbId},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );
      final joined = response.statusCode == 200 &&
          response.data is Map &&
          response.data['status'] == 'success' &&
          response.data['data']?['joined'] == true;
      // A positive result is safe to cache. A false result can become stale
      // immediately after the user joins this equb.
      if (joined) {
        _cache[equbId] = true;
      } else {
        _cache.remove(equbId);
      }
      return joined;
    } catch (_) {
      return false;
    }
  }
}

class EqubDetailCard extends StatefulWidget {
  final EqubModel equb;
  final String equbType;
  final String type;
  final String? imageUrl;
  final String? image;
  final String? description;
  final bool? isJoined;

  const EqubDetailCard({
    super.key,
    required this.equb,
    required this.type,
    required this.equbType,
    this.imageUrl,
    this.image,
    this.description,
    this.isJoined,
  });

  @override
  State<EqubDetailCard> createState() => _EqubDetailCardState();
}

class _EqubDetailCardState extends State<EqubDetailCard> {
  bool _isJoined = false;
  bool _checkedJoin = false;

  EqubModel get equb => widget.equb;

  @override
  void initState() {
    super.initState();
    if (widget.isJoined != null) {
      _isJoined = widget.isJoined!;
      _checkedJoin = true;
    } else {
      _loadJoinStatus();
    }
  }

  @override
  void didUpdateWidget(covariant EqubDetailCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.equb.id != widget.equb.id ||
        oldWidget.isJoined != widget.isJoined) {
      if (widget.isJoined != null) {
        setState(() {
          _isJoined = widget.isJoined!;
          _checkedJoin = true;
        });
      } else {
        setState(() {
          _isJoined = false;
          _checkedJoin = false;
        });
        _loadJoinStatus(forceRefresh: true);
      }
    }
  }

  Future<void> _loadJoinStatus({bool forceRefresh = false}) async {
    final id = equb.id ?? '';
    if (id.isEmpty) {
      if (mounted) setState(() => _checkedJoin = true);
      return;
    }
    final joined = await _EqubJoinStatusCache.isJoined(
      id,
      forceRefresh: forceRefresh,
    );
    if (!mounted || equb.id != id) return;
    setState(() {
      _isJoined = joined;
      _checkedJoin = true;
    });
  }

  String _formatGregorian(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd MMM yyyy').format(date.toLocal());
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? _resolveEndDate() {
    final parsedEnd = _parseDate(equb.endDate);
    if (parsedEnd != null) return parsedEnd;

    final start = _parseDate(equb.startDate);
    if (start == null) return null;

    final typeName = (equb.equbType?['name'] as String?) ?? widget.type;
    final interval = equb.equbType?['interval'] as int?;

    return calculateEqubEndDate(
      startDate: start,
      numberOfRounds: equb.numberOfEqubers ?? 0,
      intervalDays: interval,
      typeName: typeName,
    );
  }

  int get _joinedCount => equb.equbers?.length ?? 0;
  int get _neededCount => equb.numberOfEqubers ?? 0;
  bool get _isFilled => _neededCount > 0 && _joinedCount >= _neededCount;

  void _showFullScreenImage(
    BuildContext context,
    String heroTag,
    String imageUrl,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: heroTag,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildTopSection(BuildContext context) {
    final hasImage =
        (widget.imageUrl ?? '').isNotEmpty || (widget.image ?? '').isNotEmpty;
    final hasDescription = (widget.description ?? '').isNotEmpty;
    if (!hasImage && !hasDescription) return null;

    final imagel = widget.image != null
        ? '${mediaUrl}images/equb/${widget.image}'
        : '${mediaUrl}images/category/${widget.imageUrl}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          GestureDetector(
            onTap: () =>
                _showFullScreenImage(context, '${equb.id}_$imagel', imagel),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                imagel,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180.h,
                  color: Colors.grey.shade100,
                  child: const Center(
                    child:
                        Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        if (hasDescription) ...[
          if (hasImage) SizedBox(height: 10.h),
          Text(
            widget.description!,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  // int get _intervalDays {
  //   final typeName = (equb.equbType?['name'] as String?) ?? widget.type;
  //   final interval = equb.equbType?['interval'] as int?;
  //   return resolveEqubIntervalDays(interval: interval, typeName: typeName);
  // }

  // Widget _buildMembersProgress(BuildContext context) {
  //   final total = _neededCount <= 0 ? 1 : _neededCount;
  //   final joined = _joinedCount.clamp(0, total);
  //   final progress = joined / total;
  //   final percent = (progress * 100).round();
  //   final spotsLeft = (total - joined).clamp(0, total);
  //   final muted = Colors.grey.shade600;
  //   final interval = _intervalDays;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           Icon(Icons.people_outline, size: 14.sp, color: muted),
  //           SizedBox(width: 4.w),
  //           Text(
  //             '$joined/$total',
  //             style: AppTextStyles.labelSmall.copyWith(color: muted),
  //           ),
  //           const Spacer(),
  //           Icon(Icons.calendar_today_outlined, size: 12.sp, color: muted),
  //           SizedBox(width: 4.w),
  //           Text(
  //             '${AppKeys.every.tr(context)} $interval ${AppKeys.days.tr(context).toLowerCase()}',
  //             style: AppTextStyles.labelSmall.copyWith(color: muted),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: 8.h),
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(8.r),
  //         child: LinearProgressIndicator(
  //           value: progress,
  //           minHeight: 6.h,
  //           backgroundColor: Colors.grey.shade200,
  //           valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
  //         ),
  //       ),
  //       SizedBox(height: 6.h),
  //       Row(
  //         children: [
  //           Text(
  //             '$percent% ${AppKeys.filled.tr(context)}',
  //             style: AppTextStyles.captionMuted.copyWith(color: muted),
  //           ),
  //           const Spacer(),
  //           Builder(
  //             builder: (context) {
  //               final isLow = spotsLeft < 2;
  //               final accent = isLow ? Colors.red : AppColors.primary;
  //               final label = isLow
  //                   ? (spotsLeft == 1
  //                       ? AppKeys.spotLeft.tr(context)
  //                       : AppKeys.spotsLeft.tr(context))
  //                   : AppKeys.spotsToGo.tr(context);
  //               return Row(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Icon(Icons.bolt, size: 14.sp, color: accent),
  //                   SizedBox(width: 2.w),
  //                   Text(
  //                     '$spotsLeft $label',
  //                     style: AppTextStyles.labelSmall.copyWith(
  //                       color: accent,
  //                       fontWeight: FontWeight.w700,
  //                     ),
  //                   ),
  //                 ],
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final equbName = (equb.name?.trim().isNotEmpty ?? false)
        ? equb.name!.trim()
        : (widget.type.isNotEmpty ? widget.type : 'Equb');
    final amount = numberFormat.format(equb.equbAmount ?? 0);
    final totalAmount = numberFormat.format(
      (equb.equbAmount ?? 0) * (equb.numberOfEqubers ?? 0),
    );
    final status = (equb.status?.trim().isNotEmpty ?? false)
        ? equb.status!
        : (equb.isActive ? 'started' : 'pending');

    final startParts = resolveEthiopianGregorianParts(
      ethiopianDate: equb.ethiopianStartDate,
      gregorianDateStr: equb.startDate,
      formatGregorian: _formatGregorian,
    );
    final endParts = resolveEthiopianGregorianParts(
      ethiopianDate: equb.ethiopianEndDate,
      gregorianDate: _parseDate(equb.endDate) ?? _resolveEndDate(),
      formatGregorian: _formatGregorian,
    );
    final currentRound = equb.currentRound ?? 0;
    final totalRounds = equb.numberOfEqubers ?? 0;

    return EqubTileCard(
      title: equbName,
      amountText: '$amount ${AppKeys.currencyBirr.tr(context)}',
      badgeText: status,
      isJoined: _checkedJoin && _isJoined,
      topSection: _buildTopSection(context),
      details: [
        EqubTileDetail(
          icon: Icons.account_balance_wallet_outlined,
          label: AppKeys.totalAmount.tr(context),
          value: '$totalAmount ${AppKeys.currencyBirr.tr(context)}',
        ),
        EqubTileDetail(
          icon: Icons.calendar_today_outlined,
          label: AppKeys.expectedStartDate.tr(context),
          value: startParts.ethiopian,
          secondaryValue:
              startParts.gregorian == '-' ? null : startParts.gregorian,
        ),
        EqubTileDetail(
          icon: Icons.event_outlined,
          label: AppKeys.expectedEndDate.tr(context),
          value: endParts.ethiopian,
          secondaryValue:
              endParts.gregorian == '-' ? null : endParts.gregorian,
        ),
        EqubTileDetail(
          icon: Icons.autorenew_rounded,
          label: AppKeys.round.tr(context),
          value: '$currentRound/$totalRounds',
        ),

      ],
      // bottomSection: _buildMembersProgress(context),
      actionRow: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            if (_isFilled) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppKeys.alreadyFilled.tr(context)),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EqubJoinDetail(
                  equb: equb,
                  equbType: widget.equbType,
                ),
              ),
            );
            if (mounted) {
              await _loadJoinStatus(forceRefresh: true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isFilled ? Colors.grey.shade500 : AppColors.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 10.h),
          ),
          child: Text(
            _isFilled
                ? AppKeys.alreadyFilled.tr(context)
                : _isJoined
                    ? AppKeys.joinAgain.tr(context)
                    : AppKeys.join.tr(context),
            style: AppTextStyles.button.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
