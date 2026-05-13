import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/equb_model.dart';
import 'package:ekubee/utils/app_localizations.dart';
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

  const EqubDetailCard(
      {super.key,
      required this.equb,
      required this.type,
      required this.equbType});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'TBD';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('d/M/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = equb.name ?? 'Ashewa Equb';
    final round = equb.numberOfEqubers?.toString() ?? '100';
    final amount = numberFormat.format(equb.equbAmount);
    final totalAmount = numberFormat.format(
      equb.equbAmount! * int.parse(equb.numberOfEqubers.toString()),
    );
    final startDate = _formatDate(equb.startDate ?? '');
    final ethiopianStartDate = _formatDate(equb.ethiopianStartDate ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (type.isNotEmpty)
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
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
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
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
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black87,
                fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
              ),
              children: [
                TextSpan(
                  text: "${AppKeys.amount.tr(context)} : ",
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
          Text("${AppKeys.totalAmount.tr(context)} : $totalAmount",
              style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(
              "${AppKeys.expectedStartDate.tr(context)}:$ethiopianStartDate($startDate)",
              style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppKeys.cancel.tr(context).toUpperCase(),
                    style: const TextStyle(color: Colors.black87),
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
                        builder: (_) =>
                            EqubJoinDetail(equb: equb, equbType: equbType),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    AppKeys.join.tr(context),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
