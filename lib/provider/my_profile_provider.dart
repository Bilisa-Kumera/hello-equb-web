import 'package:flutter/material.dart';
import 'package:ekubee/core/api_service_elper.dart';
import 'package:ekubee/core/api_url.dart';

class MyProfile {
  final String id;
  final String fullName;
  final String email;
  final String? avatar;
  // Add other fields as needed

  MyProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatar,
  });

  factory MyProfile.fromJson(Map<String, dynamic> json) {
    return MyProfile(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
    );
  }
}

class MyProfileProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  MyProfile? _profile;
  bool _isLoading = false;
  String? _error;

  MyProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.readAll('$baseUrl/user/profile/me');
      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        _profile = MyProfile.fromJson(data);
      } else {
        _error = 'Failed to load profile';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
