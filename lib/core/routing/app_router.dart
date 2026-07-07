import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:helloequb/features/superapp_auth/presentation/pages/cbebirr_plus_continue_page.dart';
import 'package:helloequb/features/superapp_auth/presentation/pages/telebirr_continue_page.dart';
import 'package:helloequb/screens/LoginScreenWithPin.dart';
import 'package:helloequb/screens/home_screen.dart';
import 'package:helloequb/screens/language_screen.dart';
import 'package:helloequb/screens/splash_screen.dart';

class AppRouter {
  static GoRouter create(GlobalKey<NavigatorState> navigatorKey) {
    return GoRouter(
      navigatorKey: navigatorKey,
      redirect: (context, state) {
        if (!kIsWeb) return null;
        final location = state.uri.path;
        if (location == '/' ||
            location == '/telebirr' ||
            location == '/cbebirr-plus' ||
            location == '/login' ||
            location == '/language' ||
            location == '/home' ||
            location == '/telebirr-login') {
          return null;
        }
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
          builder: (context, state) => const HomeScreen(),
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
      ],
    );
  }
}
