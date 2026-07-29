import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/provider/joined_equbs_status_provider.dart';
import 'package:helloequb/screens/main_navigation_screen.dart';
import 'package:provider/provider.dart';

Future<void> navigateToMainShell(
  BuildContext context, {
  int? initialIndex,
}) async {
  final provider = context.read<JoinedEqubsStatusProvider>();
  await provider.refresh();

  if (!context.mounted) return;

  final showMyEqub = provider.hasJoinedEqubs;
  final maxIndex = showMyEqub ? 2 : 1;
  final safeIndex = (initialIndex ?? 0).clamp(0, maxIndex);

  if (kIsWeb && GoRouter.maybeOf(context) != null) {
    context.go('/home');
    return;
  }

  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => MainNavigationScreen(initialIndex: safeIndex),
    ),
    (_) => false,
  );
}

int newEqubTabIndex(BuildContext context) {
  final showMyEqub = context.read<JoinedEqubsStatusProvider>().hasJoinedEqubs;
  return showMyEqub ? 1 : 0;
}

int accountTabIndex(BuildContext context) {
  final showMyEqub = context.read<JoinedEqubsStatusProvider>().hasJoinedEqubs;
  return showMyEqub ? 2 : 1;
}

void onMainBottomNavTap(
  BuildContext context, {
  required int tappedIndex,
  required int currentIndex,
}) {
  if (tappedIndex == currentIndex) return;
  navigateToMainShell(context, initialIndex: tappedIndex);
}
