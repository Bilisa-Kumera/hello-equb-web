import 'package:flutter/material.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/floating_nav_bar.dart';
import 'package:helloequb/utils/lang_constants.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showMyEqubTab;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showMyEqubTab = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = <FloatingNavBarItem>[
      if (showMyEqubTab)
        FloatingNavBarItem(
          icon: Icons.work_outline,
          activeIcon: Icons.work,
          label: AppKeys.myEkub.tr(context),
        ),
      FloatingNavBarItem(
        icon: Icons.add_box_outlined,
        activeIcon: Icons.add_box,
        label: AppKeys.newEqub.tr(context),
      ),
      FloatingNavBarItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: AppKeys.account.tr(context),
      ),
    ];

    return Container(
      color: Colors.transparent,
      child: FloatingNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: items,
      ),
    );
  }
}
