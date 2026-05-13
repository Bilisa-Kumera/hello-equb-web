import 'package:flutter/material.dart';
import 'package:ekubee/core/api_service_elper.dart';
import 'package:ekubee/core/api_url.dart';

class EqubCategory {
  final String? id;
  final String? name;
  final String? description;
  final bool? hasReason;
  final bool? isSaving;
  final bool? needsRequest;
  final bool? otherTypeEqub;
  final int? order;
  final String? state;
  final String? imageIcon;
  final String? createdAt;
  final String? updatedAt;

  EqubCategory({
    this.id,
    this.name,
    this.description,
    this.hasReason,
    this.isSaving,
    this.needsRequest,
    this.order,
    this.otherTypeEqub,
    this.imageIcon,
    this.state,
    this.createdAt,
    this.updatedAt,
  });

  factory EqubCategory.fromJson(Map<String, dynamic> json) {
    return EqubCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      hasReason: json['hasReason'],
      isSaving: json['isSaving'],
      imageIcon: json['icon'] ?? '',
      otherTypeEqub: json['otherTypeEqub'] ?? false,
      needsRequest: json['needsRequest'],
      order: json['order'],
      state: json['state'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }
}

class EqubCategoryProvider extends ChangeNotifier {
  final ApiService? _apiService = ApiService();
  List<EqubCategory>? _equbCategories = [];
  bool? _isLoading = false;
  String? _error;

  List<EqubCategory>? get equbCategories => _equbCategories;
  bool? get isLoading => _isLoading;
  String? get error => _error;

  Future<void>? fetchEqubCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response =
          await _apiService?.readAll('$baseUrl/user/equb-category');
      if (response != null && response['status'] == 'success') {
        final List? cats = response['data']['equbCategories'];
        _equbCategories = cats?.map((e) => EqubCategory.fromJson(e)).toList();
      } else {
        _error = 'Failed to load equb categories';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
