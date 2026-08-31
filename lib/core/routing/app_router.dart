import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/features/superapp_auth/presentation/pages/cbebirr_plus_continue_page.dart';
import 'package:helloequb/features/superapp_auth/presentation/pages/telebirr_continue_page.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/main_navigation_screen.dart';
import 'package:helloequb/screens/language_screen.dart';
import 'package:helloequb/screens/splash_screen.dart';
import 'package:helloequb/screens/my_ekub_detail_screen.dart';

import '../../screens/join_ekub_detail.dart';
import '../../screens/payment_screen.dart';

class AppRouter {
  static GoRouter create(GlobalKey<NavigatorState> navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      redirect: (context, state) {
        if (!kIsWeb) return null;
        final location = state.uri.path;
        // Allow known routes and any sub‑paths (e.g., with trailing slash or query parameters)
        if (location == '/' ||
            location == '/telebirr' ||
            location == '/cbebirr-plus' ||
            location == '/login' ||
            location == '/language' ||
            location == '/home' ||
            location == '/my-equbs' ||
            location.startsWith('/my-equb-detail') ||
            location == '/telebirr-login' ||
            location.startsWith('/payment')) {
          return null;
        }
        // Unknown web route – redirect to root which loads the auth guard page.
        return '/';
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) =>
              kIsWeb ? const TelebirrContinuePage() : const SplashScreen(),
        ),
        GoRoute(
          path: '/not-superapp',
          redirect: (context, state) => '/login',
        ),
        GoRoute(
          path: '/telebirr',
          builder: (context, state) => const TelebirrContinuePage(),
        ),
        GoRoute(
          path: '/cbebirr-plus',
          builder: (context, state) => const CbeBirrPlusContinuePage(),
        ),
        GoRoute(
          path: '/telebirr-login',
          builder: (context, state) {
            final appToken = state.extra;
            if (appToken is String && appToken.trim().isNotEmpty) {
              return TelebirrMiniAppLoginPage(appToken: appToken);
            }
            return const TelebirrContinuePage();
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            final tabParam = int.tryParse(
              state.uri.queryParameters['tab'] ?? '',
            );
            // Default to Home tab (index 1) when `?tab=` is not provided.
            final initialIndex = (tabParam ?? 1).clamp(0, 2);
            return MainNavigationScreen(initialIndex: initialIndex);
          },
        ),
        GoRoute(
          path: '/my-equbs',
          builder: (context, state) {
            final tabParam = int.tryParse(
              state.uri.queryParameters['tab'] ?? '',
            );
            // Default to My Equbs tab (index 0) when `?tab=` is not provided.
            final initialIndex = (tabParam ?? 0).clamp(0, 2);
            return MainNavigationScreen(initialIndex: initialIndex);
          },
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const LoginScreenWithPin(phoneNumber: ''),
        ),
        GoRoute(
          path: '/language',
          builder: (context, state) => const LanguageSelection(),
        ),
        GoRoute(
          path: '/my-equb-detail',
          builder: (context, state) {
            final ekubId = state.uri.queryParameters['ekubId'] ?? '';
            final ekubName = state.uri.queryParameters['ekubName'] ?? '';
            final ekubAmount = int.tryParse(state.uri.queryParameters['ekubAmount'] ?? '0') ?? 0;
            final ekubersNumber = int.tryParse(state.uri.queryParameters['ekubersNumber'] ?? '0') ?? 0;
            final ekubCycle = int.tryParse(state.uri.queryParameters['ekubCycle'] ?? '0') ?? 0;
            final nextRoundDate = state.uri.queryParameters['nextRoundDate'] ?? '';
            final nextRoundTime = state.uri.queryParameters['nextRoundTime'] ?? '';
            final ekubRequest = (state.uri.queryParameters['ekubRequest'] ?? 'false') == 'true';
            final nextRoundLotteryType = state.uri.queryParameters['nextRoundLotteryType'] ?? '';
            final serviceCharge = state.uri.queryParameters['serviceCharge'] ?? '';
            final ekubType = state.uri.queryParameters['ekubType'] ?? '';
            return MyEkubDetailScreen(
              ekubId: ekubId,
              ekubName: ekubName,
              ekubAmount: ekubAmount,
              ekubersNumber: ekubersNumber,
              ekubCycle: ekubCycle,
              nextRoundDate: nextRoundDate,
              nextRoundTime: nextRoundTime,
              ekubRequest: ekubRequest,
              nextRoundLotteryType: nextRoundLotteryType,
              serviceCharge: serviceCharge,
              ekubType: ekubType,
            );
          },
                  ),
          GoRoute(
            path: '/payment',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final ekubId = extra['ekubId'] as String?;
              final ekubName = extra['ekubName'] as String?;
              final ekubRound = extra['ekubRound'] as String?;
              final ekubAmount = extra['ekubAmount'] as String?;
              
              final selectedJoinOptionsJson = extra['selectedJoinOptions'] as String? ?? '[]';
              final selectedJoinOptionJson = extra['selectedJoinOption'] as String? ?? '[]';
              
              final selectedJoinOptions = (jsonDecode(selectedJoinOptionsJson) as List)
                  .map((e) => ListItems(title: e['title'] ?? '', subtitle: e['subtitle'] ?? '', userIds: e['userIds'] ?? ''))
                  .toList();
              final selectedJoinOption = (jsonDecode(selectedJoinOptionJson) as List)
                  .map((e) => ListItem(title: e['title'] ?? '', subtitle: e['subtitle'] ?? ''))
                  .toList();
              
              final joinOption = extra['joinOption'] as String?;
              final joinAmount = extra['joinAmount'] as String?;
              final type = extra['type'] as String?;
              
              return PaymentScreen(
                ekubId: ekubId,
                ekubName: ekubName,
                ekubRound: ekubRound,
                ekubAmount: ekubAmount,
                selectedJoinOptions: selectedJoinOptions,
                selectedJoinOption: selectedJoinOption,
                joinOption: joinOption,
                joinAmount: joinAmount,
                type: type,
              );
            },
          ),
      ],
    );
  }
}
