import 'package:helloequb/core/api_url.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/core/api_service_elper.dart';

class EqubType {
  final String? id;
  final String? name;
  final String? description;
  final int? interval;
  final String? state;

  EqubType({
    this.id,
    this.name,
    this.description,
    this.interval,
    this.state,
  });

  factory EqubType.fromJson(Map<String, dynamic> json) {
    return EqubType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      interval: json['interval'],
      state: json['state'],
    );
  }
}

class EqubTypeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<EqubType>? _equbTypes;
  bool? _isLoading;
  String? _error;

  List<EqubType>? get equbTypes => _equbTypes;
  bool? get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEqubTypes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.readAll('$baseUrl/user/equb-type');
      if (response != null && response['status'] == 'success') {
        final List types = response['data']['equbTypes'];
        _equbTypes = types.map((e) => EqubType.fromJson(e)).toList();
      } else {
        _error = 'Failed to load equb types';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
