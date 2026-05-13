// import 'package:shared_preferences/shared_preferences.dart';

// // class SharedPreferencesService {
//   static final SharedPreferencesService _instance = SharedPreferencesService._internal();
//   late SharedPreferences _prefs;

//   factory SharedPreferencesService() {
//     return _instance;
//   }

//   SharedPreferencesService._internal();

//   Future<void> init() async {
//     _prefs = await SharedPreferences.getInstance();
//   }

//   // String methods
//   Future<bool> setString(String key, String value) async {
//     return await _prefs.setString(key, value);
//   }

//   String? getString(String key) {
//     return _prefs.getString(key);
//   }

//   // Bool methods
//   Future<bool> setBool(String key, bool value) async {
//     return await _prefs.setBool(key, value);
//   }

//   bool? getBool(String key) {
//     return _prefs.getBool(key);
//   }
// }
