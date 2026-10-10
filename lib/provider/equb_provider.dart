import 'package:helloequb/core/api_url.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/models/equb_model.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

import '../utils/secure_storage.dart';

class EqubProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<EqubModel> _equbs = [];
  List<EqubModel> _activeSortedEqubs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _hasMore = true;
  int _page = 1;
  int _limit = 50;
  int? _total;
  String _currentEqubTypeId = '';
  String _currentEqubCategoryId = '';
  int _fetchGeneration = 0;

  List<EqubModel> get equbs => _equbs;
  List<EqubModel> get activeSortedEqubs => _activeSortedEqubs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get page => _page;
  int get limit => _limit;
  int? get total => _total;
  String get currentEqubTypeId => _currentEqubTypeId;
  String get currentEqubCategoryId => _currentEqubCategoryId;

  bool matchesFilter({
    required String equbTypeId,
    required String equbCategoryId,
  }) {
    return _currentEqubTypeId == equbTypeId &&
        _currentEqubCategoryId == equbCategoryId;
  }

  void _recomputeActiveSorted() {
    _activeSortedEqubs = _equbs.where((equb) => equb.isActive).toList()
      ..sort((a, b) => (a.equbAmount ?? 0).compareTo(b.equbAmount ?? 0));
  }

  Future<void> fetchEqubs(
      {required String equbTypeId,
      required String equbCategoryId,
      int limit = 50}) async {
    final generation = ++_fetchGeneration;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _equbs = [];
    _activeSortedEqubs = [];
    _page = 1;
    _limit = limit;
    _total = null;
    _hasMore = true;
    _currentEqubTypeId = equbTypeId;
    _currentEqubCategoryId = equbCategoryId;
    notifyListeners();
    try {
      // Load first page, then quietly pull remaining pages so low-amount equbs
      // are not missing until the user scrolls (pagination + client sort).
      while (true) {
        final url =
            '$baseUrl/user/equb/?equbTypeId=$equbTypeId&equbCategoryId=$equbCategoryId&_page=$_page&_limit=$_limit';

        final DataController dataController = DataController();
        await dataController.initialize();
        String accessToken =
            await SecureStorageHelper.getAccessToken() ?? '';
        final response =
            await _apiService.readAll(url, bearerToken: accessToken);
        // Ignore stale responses from older tab fetches.
        if (generation != _fetchGeneration) return;
        if (response == null || response['status'] != 'success') {
          _error = 'Failed to load equbs';
          break;
        }

        final List data = (response['data']?['equbs'] as List?) ?? const [];
        final pageEqubs = data.map((e) => EqubModel.fromJson(e)).toList();
        if (_page == 1) {
          _equbs = pageEqubs;
        } else {
          final existingIds = _equbs.map((e) => e.id).toSet();
          _equbs.addAll(pageEqubs.where((e) => !existingIds.contains(e.id)));
        }

        final meta = response['data']?['meta'];
        if (meta is Map && meta['total'] != null) {
          final parsedTotal = meta['total'];
          if (parsedTotal is int) {
            _total = parsedTotal;
          } else if (parsedTotal is String) {
            _total = int.tryParse(parsedTotal);
          }
        }

        _hasMore = _total != null
            ? (_equbs.length < (_total ?? 0))
            : (data.length == _limit);
        if (!_hasMore || data.isEmpty) {
          _hasMore = false;
          break;
        }
        _page += 1;
        // Safety cap: avoid unbounded loops on bad meta.
        if (_page > 40) {
          break;
        }
      }
    } catch (e) {
      if (generation != _fetchGeneration) return;
      _error = e.toString();
    }
    if (generation != _fetchGeneration) return;
    _recomputeActiveSorted();
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
      _recomputeActiveSorted();
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
