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

  // On web we treat the "My Equbs" tab as always available so that
  // navigation (and URL path mapping) stays consistent across screens.
  final showMyEqub = kIsWeb || provider.hasJoinedEqubs;
  final maxIndex = showMyEqub ? 2 : 1;
  final safeIndex = (initialIndex ?? 0).clamp(0, maxIndex);

  if (kIsWeb && GoRouter.maybeOf(context) != null) {
    // Web: keep the browser URL in sync with the visible base/tabs.
    // `/home` is the base route for both Home (tab=1) and Profile (tab=2),
    // so we use `?tab=` to preserve which tab is active.
    String targetPath = '/home';
    if (showMyEqub) {
      targetPath = safeIndex == 0 ? '/my-equbs' : '/home';
      if (targetPath == '/home' && safeIndex == 2) {
        targetPath = '/home?tab=2';
      }
    }

    context.go(targetPath);
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
  final showMyEqub = kIsWeb || context.read<JoinedEqubsStatusProvider>().hasJoinedEqubs;
  return showMyEqub ? 1 : 0;
}

int accountTabIndex(BuildContext context) {
  final showMyEqub = kIsWeb || context.read<JoinedEqubsStatusProvider>().hasJoinedEqubs;
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
