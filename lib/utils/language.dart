import 'package:flutter/material.dart';
import 'package:ekubee/utils/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  Locale? _currentLocale = const Locale('en', '');

  Locale? get currentLocale => _currentLocale;

  Future<void> init() async {
    // Initialize the selected language from shared preferences
    // SharedPreferences pref .getInstance();
    String? languageCode =
        PrefUtils.sharedPreferences?.getString('language_code') ?? 'en';
    _currentLocale = Locale(languageCode, '');
  }

  Future<void> changeLanguage(Locale newLocale) async {
    _currentLocale = newLocale;
    // Persist the selected language to shared preferences
    PrefUtils.sharedPreferences!
        .setString('language_code', newLocale.languageCode);
    notifyListeners();
  }
}
