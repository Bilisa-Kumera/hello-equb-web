import 'package:flutter/material.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/core/api_service_elper.dart';
import '../models/banner_model.dart';

class BannerProvider extends ChangeNotifier {
  List<BannerModel> _banners = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      try {
        notifyListeners();
      } catch (e) {
        // Provider was disposed, ignore
      }
    }
  }

  Future<void> fetchBanners() async {
    if (_disposed) return;

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      final apiService = ApiService();
      final data = await apiService.readAll(bannersUrl);

      if (_disposed) return;

      if (data != null &&
          data['data'] != null &&
          data['data']['banners'] is List) {
        final List banners = data['data']['banners'];
        _banners = banners.map((json) => BannerModel.fromJson(json)).toList();
      } else {
        _banners = [];
      }
    } catch (e) {
      if (!_disposed) {
        _error = e.toString();
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }
}
