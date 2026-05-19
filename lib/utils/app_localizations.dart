//ignore: unused_import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helloequb/core/afaan_oromoo_translation.dart';
import 'package:helloequb/core/amharic_translations.dart';
import 'package:helloequb/core/english_translation.dart';
import 'package:helloequb/core/tigrigna_translation.dart';
import 'package:helloequb/utils/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';

class PrefUtils {
  static SharedPreferences? sharedPreferences;

  PrefUtils() {
    // init();
    SharedPreferences.getInstance().then((value) {
      sharedPreferences = value;
    });
  }

  Future<void> init() async {
    sharedPreferences ??= await SharedPreferences.getInstance();
  }

  ///will clear all the data stored in preference
  void clearPreferencesData() async {
    sharedPreferences!.clear();
  }

  Future<void> setThemeData(String value) {
    return sharedPreferences!.setString('themeData', value);
  }

  String getThemeData() {
    try {
      return sharedPreferences!.getString('themeData')!;
    } catch (e) {
      return 'primary';
    }
  }
}

class AppLocalization {
  AppLocalization(this.locale);

  Locale locale;

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': enUS,
    'am': amET,
    'fr': omET,
    'es': tgET,
  };

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  static List<String> languages() => _localizedValues.keys.toList();
  String getString(String text) =>
      _localizedValues[locale.languageCode]![text] ?? text;
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalization.languages().contains(locale.languageCode);

  //Returning a SynchronousFuture here because an async "load" operation
  //cause an async "load" operation
  @override
  Future<AppLocalization> load(Locale locale) {
    return SynchronousFuture<AppLocalization>(AppLocalization(locale));
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

extension LocalizationExtension on String {
  String tr(BuildContext context) {
    return AppLocalization.of(context).getString(this);
  }
}
