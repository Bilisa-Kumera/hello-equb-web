import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/features/superapp_auth/presentation/pages/not_in_superapp_page.dart';
import 'package:helloequb/features/superapp_auth/presentation/pages/telebirr_continue_page.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/language_screen.dart';
import 'package:helloequb/screens/splash_screen.dart';

class AppRouter {
  static GoRouter create(GlobalKey<NavigatorState> navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/not-superapp',
          builder: (context, state) => const NotInSuperAppPage(),
        ),
        GoRoute(
          path: '/telebirr',
          builder: (context, state) => const TelebirrContinuePage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreenWithPin(phoneNumber: ''),
        ),
        GoRoute(
          path: '/language',
          builder: (context, state) => const LanguageSelection(),
        ),
      ],
    );
  }
}
