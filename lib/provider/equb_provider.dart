import 'package:helloequb/core/api_url.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

import '../utils/secure_storage.dart';

class EqubProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<EqubModel> _equbs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _hasMore = true;
  int _page = 1;
  int _limit = 50;
  int? _total;
  String _currentEqubTypeId = '';
  String _currentEqubCategoryId = '';

  List<EqubModel> get equbs => _equbs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get page => _page;
  int get limit => _limit;
  int? get total => _total;

  Future<void> fetchEqubs(
      {required String equbTypeId,
      required String equbCategoryId,
      int limit = 50}) async {
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _equbs = [];
    _page = 1;
    _limit = limit;
    _total = null;
    _hasMore = true;
    _currentEqubTypeId = equbTypeId;
    _currentEqubCategoryId = equbCategoryId;
    notifyListeners();
    try {
      final url =
          '$baseUrl/user/equb/?equbTypeId=$equbTypeId&equbCategoryId=$equbCategoryId&_page=$_page&_limit=$_limit';

      final DataController dataController = DataController();
      await dataController.initialize();
      String accessToken =
          await SecureStorageHelper.getAccessToken() ?? '';
      final response = await _apiService.readAll(url, bearerToken: accessToken);
      if (response != null && response['status'] == 'success') {
        final List data = (response['data']?['equbs'] as List?) ?? const [];
        _equbs = data.map((e) => EqubModel.fromJson(e)).toList();

        final meta = response['data']?['meta'];
        if (meta is Map && meta['total'] != null) {
          final parsedTotal = meta['total'];
          if (parsedTotal is int) {
            _total = parsedTotal;
          } else if (parsedTotal is String) {
            _total = int.tryParse(parsedTotal);
          }
        }

        _hasMore = _total != null ? (_equbs.length < (_total ?? 0)) : (data.length == _limit);
      } else {
        _error = 'Failed to load equbs';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreEqubs(
      {required String equbTypeId, required String equbCategoryId}) async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    if (equbTypeId != _currentEqubTypeId ||
        equbCategoryId != _currentEqubCategoryId) {
      // A different filter is active; avoid mixing pages.
      return;
    }

    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    final nextPage = _page + 1;
    try {
      final url =
          '$baseUrl/user/equb/?equbTypeId=$equbTypeId&equbCategoryId=$equbCategoryId&_page=$nextPage&_limit=$_limit';

      String accessToken = await SecureStorageHelper.getAccessToken() ?? '';
      final response = await _apiService.readAll(url, bearerToken: accessToken);
      if (response != null && response['status'] == 'success') {
        final List data = (response['data']?['equbs'] as List?) ?? const [];
        final nextEqubs = data.map((e) => EqubModel.fromJson(e)).toList();

        final existingIds = _equbs.map((e) => e.id).toSet();
        _equbs.addAll(nextEqubs.where((e) => !existingIds.contains(e.id)));
        _page = nextPage;

        final meta = response['data']?['meta'];
        if (meta is Map && meta['total'] != null) {
          final parsedTotal = meta['total'];
          if (parsedTotal is int) {
            _total = parsedTotal;
          } else if (parsedTotal is String) {
            _total = int.tryParse(parsedTotal) ?? _total;
          }
        }

        _hasMore =
            _total != null ? (_equbs.length < (_total ?? 0)) : (data.length == _limit);
        if (data.isEmpty) _hasMore = false;
      } else {
        _error = 'Failed to load more equbs';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
