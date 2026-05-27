import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../utils/colors_constant.dart';
import '../utils/lang_constants.dart';
import 'join_ekub_detail.dart';

class EqubDetailCard extends StatelessWidget {
  final EqubModel equb;
  final String equbType;
  final String type;
  final String? imageUrl;
  final String? image;
  final String? description;

  const EqubDetailCard({
    super.key,
    required this.equb,
    required this.type,
    required this.equbType,
    this.imageUrl,
    this.image,
    this.description,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBD';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d/M/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  void _showFullScreenImage(
  BuildContext context,
  String heroTag,
  String image,
) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.95),
    builder: (_) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(0),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    image,
                    fit: BoxFit.contain,
                  ),
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
                    borderRadius:
                        BorderRadius.circular(100),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    final title = equb.name ?? 'Ashewa Equb';
    final round = equb.numberOfEqubers?.toString() ?? '100';
    final amount = numberFormat.format(equb.equbAmount);

    final totalAmount = numberFormat.format(
      equb.equbAmount! * int.parse(
        equb.numberOfEqubers.toString(),
      ),
    );

    final startDate = _formatDate(equb.startDate ?? '');
    final ethiopianStartDate =
        _formatDate(equb.ethiopianStartDate ?? '');

    final imagel = image != null ? '${mediaUrl}images/equb/$image': '${mediaUrl}images/category/$imageUrl';



    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// IMAGE + DESCRIPTION SECTION
          if ((imageUrl ?? '').isNotEmpty ||
              (description ?? '').isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.green.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.green.withOpacity(0.08),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    /// IMAGE
                    if ((imageUrl ?? '').isNotEmpty)
                      GestureDetector(
                        onTap: () =>
                            _showFullScreenImage(
                          context,
                          "${equb.id}_$imagel",
                          imagel,
                        ),
                        child: Stack(
                          children: [
                           Hero(
  tag: "${equb.id}_$imagel",
                              child: SizedBox(
                                height: 220,
                                width: double.infinity,
                                child: Image.network(
                                  imagel,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) =>
                                          Container(
                                    color:
                                        Colors.grey.shade100,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  loadingBuilder:
                                      (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                    if (loadingProgress ==
                                        null) {
                                      return child;
                                    }

                                    return Container(
                                      height: 220,
                                      alignment:
                                          Alignment.center,
                                      child:
                                          const CircularProgressIndicator(
                                        color: AppColors
                                            .vibrantGreen,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding:
                                    const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius:
                                      BorderRadius.circular(
                                    100,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),

                            Positioned(
                              left: 16,
                              bottom: 16,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius:
                                      BorderRadius.circular(
                                    100,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Tap to view',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// DESCRIPTION
                    if ((description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors
                                    .vibrantGreen
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                size: 22,
                                color:
                                    AppColors.vibrantGreen,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                description!,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  height: 1.7,
                                  color: Colors.black87,
                                  fontWeight:
                                      FontWeight.w500,
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

          /// TYPE
          if (type.isNotEmpty)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),

          const SizedBox(height: 10),

          /// TITLE + ROUND
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                "${AppKeys.round.tr(context)} : $round",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// AMOUNT
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black87,
                fontFamily: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.fontFamily,
              ),
              children: [
                TextSpan(
                  text:
                      "${AppKeys.amount.tr(context)} : ",
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          /// TOTAL
          Text(
            "${AppKeys.totalAmount.tr(context)} : $totalAmount",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          /// DATE
          Text(
            "${AppKeys.expectedStartDate.tr(context)} : "
            "$ethiopianStartDate ($startDate)",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 14),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.grey.shade400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    AppKeys.cancel
                        .tr(context)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EqubJoinDetail(
                          equb: equb,
                          equbType: equbType,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor:
                        AppColors.vibrantGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    AppKeys.join.tr(context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}