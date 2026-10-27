import 'dart:convert';
import 'package:helloequb/core/api_url.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../screens/my_equb_screen.dart';
import '../utils/lang_constants.dart';
import '../utils/secure_storage.dart';

class GetMyEqubProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<PendingEqub> _equbs = [];
  List<PendingEqub> _visibleEqubs = [];
  bool _hasMore = true;
  int _page = 1;
  int _limit = 30;
  int? _total;
  String _currentUserId = '';
  String _currentEqubTypeId = '';
  String _currentEqubCategoryId = '';
  String _currentStatus = 'joined';

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<PendingEqub> get equbs => _equbs;
  List<PendingEqub> get visibleEqubs => _visibleEqubs;
  bool get hasMore => _hasMore;

  void _recomputeVisibleEqubs() {
    // Keep active joined equbs visible even when payment math marks them
    // "fully paid" (common on small test equbs / multi-round payments).
    _visibleEqubs = _equbs
        .where((e) =>
            e.status.trim().toLowerCase() != AppKeys.completed &&
            e.status.trim().toLowerCase() != 'completed')
        .toList();
    PendingEqub.sortByLatestJoined(_visibleEqubs);
  }

  Future<void> fetchEqubs({
    required String equbTypeId,
    required String equbCategoryId,
    required String userId,
    String status = 'joined',
    int limit = 30,
  }) async {
    _isLoading = true;
    _isLoadingMore = false;
    _errorMessage = null;
    _equbs = [];
    _visibleEqubs = [];
    _page = 1;
    _limit = limit;
    _total = null;
    _hasMore = true;
    _currentUserId = userId;
    _currentEqubTypeId = equbTypeId;
    _currentEqubCategoryId = equbCategoryId;
    _currentStatus = status;
    notifyListeners();

    await _loadPage(reset: true);
  }

  Future<void> loadMoreEqubs() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    final nextPage = reset ? 1 : _page + 1;

    final queryParams = <String, String>{
      'user': _currentUserId,
      'status': _currentStatus,
      '_page': '$nextPage',
      '_limit': '$_limit',
    };

    if (_currentEqubTypeId.isNotEmpty) {
      queryParams['equbTypeId'] = _currentEqubTypeId;
    }
    if (_currentEqubCategoryId.isNotEmpty) {
      queryParams['equbCategoryId'] = _currentEqubCategoryId;
    }

    final endpoint =
        Uri.parse('$baseUrl/user/equb').replace(queryParameters: queryParams).toString();
    final accessToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        dynamic data = response.data;
        if (data is String) {
          try {
            data = jsonDecode(data);
          } catch (_) {}
        }

        List<dynamic>? rawEqubsList;
        Map<dynamic, dynamic>? metaMap;

        if (data is Map) {
          final dataMap = data['data'];
          if (dataMap is Map && dataMap['equbs'] is List) {
            rawEqubsList = dataMap['equbs'] as List<dynamic>;
          } else if (data['equbs'] is List) {
            rawEqubsList = data['equbs'] as List<dynamic>;
          } else if (dataMap is List) {
            rawEqubsList = dataMap;
          }

          if (data['meta'] is Map) {
            metaMap = data['meta'] as Map;
          } else if (dataMap is Map && dataMap['meta'] is Map) {
            metaMap = dataMap['meta'] as Map;
          }
        } else if (data is List) {
          rawEqubsList = data;
        }

        if (rawEqubsList != null) {
          final nextEqubs = rawEqubsList
              .whereType<Map>()
              .map((json) => PendingEqub.fromJson(
                    Map<String, dynamic>.from(json),
                    currentUserId: _currentUserId,
                  ))
              .toList();

          if (reset) {
            _equbs = nextEqubs;
          } else {
            final existingIds = _equbs.map((e) => e.id).toSet();
            _equbs.addAll(
              nextEqubs.where((equb) => !existingIds.contains(equb.id)),
            );
          }
          _page = nextPage;

          if (metaMap != null && metaMap['total'] != null) {
            final parsedTotal = metaMap['total'];
            if (parsedTotal is int) {
              _total = parsedTotal;
            } else if (parsedTotal is String) {
              _total = int.tryParse(parsedTotal);
            }
          }

          _hasMore = _total != null
              ? (_equbs.length < (_total ?? 0))
              : (nextEqubs.length == _limit);
          if (nextEqubs.isEmpty) _hasMore = false;

          _recomputeVisibleEqubs();
        } else if (reset) {
          _equbs = [];
          _visibleEqubs = [];
          _hasMore = false;
        }
      } else {
        _errorMessage = 'Failed to load equbs';
        if (reset) {
          _equbs = [];
          _visibleEqubs = [];
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      if (reset) {
        _equbs = [];
        _visibleEqubs = [];
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void clear() {
    _equbs = [];
    _visibleEqubs = [];
    _errorMessage = null;
    _isLoading = false;
    _isLoadingMore = false;
    _hasMore = true;
    _page = 1;
    _total = null;
    notifyListeners();
  }
}
