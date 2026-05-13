import 'package:ekubee/provider/getmyequb_provider.dart';
import 'package:ekubee/features/app_update/data/datasources/update_remote_data_source.dart';
import 'package:ekubee/features/app_update/data/repositories/update_repository_impl.dart';
import 'package:ekubee/features/app_update/domain/usecases/check_for_update_use_case.dart';
import 'package:ekubee/features/app_update/presentation/providers/update_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ekubee/screens/splash_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ekubee/utils/app_localizations.dart';
import 'package:ekubee/utils/language.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ekubee/utils/colors_constant.dart';
import 'package:ekubee/provider/equb_type_provider.dart';
import 'package:ekubee/provider/equb_category_provider.dart';
import 'package:ekubee/provider/equb_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ekubee/screens/notification_screen.dart';
import 'package:ekubee/screens/my_ekub_detail_screen.dart';
import 'dart:convert';
import 'package:ekubee/screens/guarantee_request.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'provider/allequb_payment.dart';
import 'provider/cooperate_equbs_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> requestCameraAndGalleryPermissions() async {
  await Permission.camera.request();
  await Permission.storage.request();
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initGetStorageSafely() async {
  try {
    // Some devices/ROMs can have a broken/unreadable documents dir (app_flutter),
    // which makes `GetStorage.init()` throw and crash the app at startup.
    // Using the support directory avoids that dependency.
    final supportDir = await getApplicationSupportDirectory();
    await GetStorage('GetStorage', supportDir.path).initStorage;
  } catch (e) {
    // Fallback to the default init; if it still fails, don't crash the app.
    try {
      await GetStorage.init();
    } catch (_) {}
  }
}

dynamic _handleNotificationNavigation(Map<String, dynamic> data) {
  if (data['type'] == 'Equb Draw') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => MyEkubDetailScreen(
          ekubId: data['equbId'] ?? '',
          ekubName: data['equbName'] ?? '',
          ekubAmount: int.tryParse(data['equbAmount']?.toString() ?? '') ?? 0,
          ekubersNumber:
              int.tryParse(data['numberOfEqubers']?.toString() ?? '') ?? 0,
          ekubCycle: int.tryParse(data['equberLength']?.toString() ?? '') ?? 0,
          nextRoundDate: data['nextRoundDate'] ?? '',
          nextRoundTime: data['nextRoundTime'] ?? '',
          ekubRequest:
              data['equbRequest'] == true || data['equbRequest'] == 'true',
          nextRoundLotteryType: data['nextRoundLotteryType'] ?? '',
          serviceCharge: data['equbServiceCharge']?.toString() ?? '',
          ekubType: data['type'] ?? '',
        ),
      ),
    );
  } else if (data['payload'] == 'request') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => AcceptDeclineScreen(
          guaranteeNeedyId: data['guaranteeNeedyId'] ?? '',
          guaranteeTobeId: data['guaranteeId'] ?? '',
          equbId: data['equbId'] ?? '',
          equbName: data['equbName'] ?? '',
          equbAmount: data['equbAmount']?.toString() ?? '',
          fullName: data['fullName'] ?? '',
        ),
      ),
    );
  } else {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _ensureFirebaseInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      Map<String, dynamic> data = {};
      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          data = Map<String, dynamic>.from(jsonDecode(response.payload!));
        } catch (_) {}
      }
      _handleNotificationNavigation(data);
    },
  );

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await FirebaseMessaging.instance.requestPermission();
  }
  // if (Platform.isAndroid || Platform.isIOS) {
  //   await FirebaseMessaging.instance.requestPermission();
  // }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.notification != null) {
      await flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification?.title,
        message.notification?.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  });

  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      _handleNotificationNavigation(message.data);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationNavigation(message.data);
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await PrefUtils().init();
  var languageProvider = LanguageProvider();
  await languageProvider.init();

  // Initialize GetStorage
  await _initGetStorageSafely();

  final updateRemoteDataSource = UpdateRemoteDataSourceImpl();
  final updateRepository = UpdateRepositoryImpl(updateRemoteDataSource);
  final checkForUpdateUseCase = CheckForUpdateUseCase(updateRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EqubTypeProvider()),
        ChangeNotifierProvider(create: (_) => EqubCategoryProvider()),
        ChangeNotifierProvider(create: (_) => EqubProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => GetMyEqubProvider()),
        ChangeNotifierProvider(create: (_) => EqubPaymentProvider()),
        ChangeNotifierProvider(create: (_) => CooperateEqubsProvider()),
        ChangeNotifierProvider(
          create: (_) => UpdateProvider(
            checkForUpdateUseCase: checkForUpdateUseCase,
            updateRepository: updateRepository,
          ),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Consumer2<ThemeProvider, LanguageProvider>(
              builder: (context, provider, languageProvider, child) {
            return MaterialApp(
              title: '',
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: AppColors.black),
                useMaterial3: true,
              ),
              home: const SplashScreen(),
              localizationsDelegates: const [
                AppLocalizationDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('am', 'ET'),
                Locale('fr', 'FR'),
                Locale('es', 'ES'),
              ],
              locale: Locale(
                  PrefUtils.sharedPreferences?.getString('language_code') ??
                      'en',
                  ''),
            );
          });
        },
      ),
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _ensureFirebaseInitialized();
}

Completer<void>? _firebaseInitCompleter;

Future<void> _ensureFirebaseInitialized() async {
  if (_firebaseInitCompleter != null) {
    return _firebaseInitCompleter!.future;
  }

  _firebaseInitCompleter = Completer<void>();

  try {
    Firebase.app();
    _firebaseInitCompleter!.complete();
    return;
  } catch (_) {
    // Fall through to initialize.
  }

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBLyGjSfl6aerMMJh9Ub6qIBgOILQBTp_U',
        appId: '1:1036981151221:android:203871b087561c778facbc',
        messagingSenderId: '1036981151221',
        projectId: 'hello-equb',
        storageBucket: 'hello-equb.firebasestorage.app',
      ),
    );
    _firebaseInitCompleter!.complete();
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      _firebaseInitCompleter!.complete();
    } else {
      _firebaseInitCompleter!.completeError(e);
      rethrow;
    }
  } catch (e) {
    _firebaseInitCompleter!.completeError(e);
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class ThemeProvider extends ChangeNotifier {
  themeChange(String themeType) async {
    PrefUtils().setThemeData(themeType);
    notifyListeners();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  void changeLocale(Locale newLocale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return Consumer2<ThemeProvider, LanguageProvider>(
              builder: (context, provider, languageProvider, child) {
            return MaterialApp(
              title: '',
              navigatorKey: _navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: AppColors.black),
                useMaterial3: true,
              ),
              home: const SplashScreen(),
              localizationsDelegates: const [
                AppLocalizationDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', 'US'),
                Locale('am', 'ET'),
                Locale('fr', 'FR'),
                Locale('es', 'ES'),
              ],
              locale: Locale(
                  PrefUtils.sharedPreferences?.getString('language_code') ??
                      'en',
                  ''),
            );
          });
        },
      ),
    );
  }
}
