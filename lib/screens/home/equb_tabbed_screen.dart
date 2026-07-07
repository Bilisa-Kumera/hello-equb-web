// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import '../../models/financeandothermodel.dart';
import '../../utils/lang_constants.dart';
import 'equb_list_by_category.dart';
import 'helpers.dart';

class EqubTabbedScreen extends StatefulWidget {
  final EqubCategory category;
  final List<EqubType> equbTypes;
  final String equbTypeId;
  final String equbType;

  const EqubTabbedScreen({
    super.key,
    required this.category,
    required this.equbTypes,
    required this.equbTypeId,
    required this.equbType,
  });

  @override
  State<EqubTabbedScreen> createState() => _EqubTabbedScreenState();
}

class _EqubTabbedScreenState extends State<EqubTabbedScreen> {
  @override
  Widget build(BuildContext context) {
    final List<EqubType> equbTypesWithAll = [
      EqubType(id: '', name: AppKeys.all.tr(context)),
      ...widget.equbTypes,
    ];

    return DefaultTabController(
      length: equbTypesWithAll.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          backgroundColor: const Color.fromARGB(255, 76, 109, 93),
          title: Row(
            children: [
              Text(
                widget.equbType,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                labelColor: AppColors.white,
                unselectedLabelColor: Colors.white70,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3,
                    color: AppColors.white,
                  ),
                  insets: EdgeInsets.symmetric(horizontal: 16),
                ),
                tabs: equbTypesWithAll.map((equbType) {
                  return Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 7),
                      decoration: BoxDecoration(
                        color: getEqubTypeColor(equbType.name),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        equbType.name ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: equbTypesWithAll.map((equbType) {
            return EqubListByCategory(
              category: widget.category,
              equbTypeId: equbType.id ?? '',
              type: equbType.name ?? '',
            );
          }).toList(),
        ),
      ),
    );
  }
}
