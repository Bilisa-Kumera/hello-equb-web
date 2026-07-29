import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/core/api_url.dart';

import 'equb_detail_card.dart';
import 'join_ekub_detail.dart';
import 'package:helloequb/utils/style_constants.dart';

class CooperateListScreen extends StatelessWidget {
  final String title;
  final List<EqubModel> equbs;

  const CooperateListScreen(
      {super.key, required this.title, required this.equbs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed:()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 76, 109, 93),
        title: Row(
          children: [
           
            Text(title, style: AppTextStyles.poppins40014.copyWith(color: Colors.white)),
          ],
        ),
      ),
      body: equbs.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final e = equbs[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EqubJoinDetail(
                          equb: e,
                          equbType: e.equbType?.entries.first.value ??
                              e.equbType?['name'] ??
                              'N/A',
                        ),
                      ),
                    );
                  },
                  child: EqubDetailCard(
                    key: ValueKey(e.id),
                    equb: e,
                    equbType: e.equbType?.entries.first.value ?? '',
                    type: e.equbType?['name'] ?? '',
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: equbs.length,
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, color: Colors.grey, size: 48),
          const SizedBox(height: 8),
          Text('No Equbs found',
              style: AppTextStyles.poppins40014.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _EqubCard extends StatelessWidget {
  final EqubModel equb;

  const _EqubCard({required this.equb});

  @override
  Widget build(BuildContext context) {
    final String name = equb.name ?? '-';
    final String type = (equb.equbType != null)
        ? (equb.equbType!['name'] as String? ?? '')
        : '';
    final String category = (equb.equbCategory != null)
        ? (equb.equbCategory!['name'] as String? ?? '')
        : '';
    final String amount =
        equb.equbAmount != null ? numberFormat.format(equb.equbAmount) : '-';
    final String members = (equb.numberOfEqubers ?? 0).toString();
    final String nextDate = equb.nextRoundDate ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.06),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.vibrantGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.groups_2_rounded,
                color: AppColors.vibrantGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.poppins70016.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(label: type.isEmpty ? '—' : type),
                    _Chip(label: category.isEmpty ? '—' : category),
                    _Chip(label: 'Br ${amount}'),
                    _Chip(label: '$members members'),
                    if (nextDate.isNotEmpty) _Chip(label: 'Next: $nextDate'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTextStyles.poppins60012.copyWith(color: Colors.grey[800]),
      ),
    );
  }
}
