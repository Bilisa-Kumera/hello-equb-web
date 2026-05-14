import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';

Future<void> openDeviceSettings() async {
  if (!Platform.isAndroid) return;

  const AndroidIntent intent = AndroidIntent(
    action: 'android.settings.SETTINGS',
  );
  await intent.launch();
}

