import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/my_equb_screen.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/core/logging/app_logger.dart';
import 'package:helloequb/utils/secure_storage.dart';

class JoinedEqubsStatusProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  static const _cacheKey = 'hasJoinedEqubs';

  final DataController _dataController = DataController();
  final Dio _dio = Dio();

  bool _hasJoinedEqubs;
  bool _isLoading = false;
  bool _isWatching = false;
  Set<String> _joinedEqubIds = {};

  JoinedEqubsStatusProvider()
      : _hasJoinedEqubs =
            DataController().retrieveData<bool>(_cacheKey) ?? false;

  bool get hasJoinedEqubs => _hasJoinedEqubs;
  bool get isLoading => _isLoading;
  Set<String> get joinedEqubIds => Set.unmodifiable(_joinedEqubIds);

  void setHasJoinedEqubs(bool value) {
    if (_hasJoinedEqubs == value) return;
    _hasJoinedEqubs = value;
    _dataController.storeData(_cacheKey, value);
    notifyListeners();
  }

  /// Called when My Equbs screen loads data — only promotes to true.
  void syncFromPendingEqubs(Iterable<PendingEqub> equbs) {
    if (_hasJoinedEqubs) return;

    final hasActive = equbs.any((equb) {
      final status = equb.status.trim().toLowerCase();
      return status.isNotEmpty && status != AppKeys.completed;
    });

    if (hasActive) {
      setHasJoinedEqubs(true);
    }
  }

  /// Refreshes joined-equb status when the app resumes (mobile only).
  void startApprovalWatch() {
    if (kIsWeb || _isWatching) return;

    _isWatching = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void stopApprovalWatch() {
    if (!_isWatching) return;

    _isWatching = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isWatching || kIsWeb) return;

    if (state == AppLifecycleState.resumed && !_hasJoinedEqubs) {
      refresh(silent: true);
    }
  }

  static bool looksLikeApprovalNotification(RemoteMessage message) {
    final parts = <String>[
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      ...message.data.values.map((value) => value.toString()),
    ];
    final text = parts.join(' ').toLowerCase();

    if (!text.contains('approved')) return false;

    return text.contains('join') ||
        text.contains('equb') ||
        text.contains('payment') ||
        text.contains('lottery');
  }

  bool _isActiveJoinedEqub(PendingEqub equb) {
    final status = equb.status.trim().toLowerCase();
    return status.isNotEmpty && status != AppKeys.completed;
  }

  List<PendingEqub> _parseJoinedEqubs(dynamic raw, {String? userId}) {
    dynamic data = raw;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }

    List<dynamic>? equbsJson;
    if (data is Map) {
      final dataMap = data['data'];
      if (dataMap is Map && dataMap['equbs'] is List) {
        equbsJson = dataMap['equbs'] as List<dynamic>;
      } else if (data['equbs'] is List) {
        equbsJson = data['equbs'] as List<dynamic>;
      } else if (dataMap is List) {
        equbsJson = dataMap;
      }
    } else if (data is List) {
      equbsJson = data;
    }

    if (equbsJson == null) return const [];

    return equbsJson
        .whereType<Map>()
        .map((json) => PendingEqub.fromJson(
              Map<String, dynamic>.from(json),
              currentUserId: userId,
            ))
        .toList();
  }

  Future<void> refresh({
    bool silent = false,
    String type = '',
    String category = '',
  }) async {
    AppLogger.log('JoinedEqubsStatusProvider.refresh() initiated.');
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final accessToken = await SecureStorageHelper.getAccessToken() ?? '';
      final userId = (await SecureStorageHelper.getUserId())?.trim() ?? '';
      AppLogger.log('JoinedEqubsStatusProvider: retrieved userId="$userId", tokenLength=${accessToken.length}');
      if (accessToken.isEmpty) {
        AppLogger.warn('JoinedEqubsStatusProvider: aborting refresh - access token is empty');
        return;
      }

      final String url =
          '$ekubsUrl?_page&_limit&equbType=$type&equbCategory=$category&user=$userId&status=joined';

      AppLogger.log('JoinedEqubsStatusProvider: GET $url');
      AppLogger.log('JoinedEqubsStatusProvider: Headers: Authorization="Bearer ${accessToken.substring(0, accessToken.length > 8 ? 8 : accessToken.length)}..."');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      AppLogger.success('JoinedEqubsStatusProvider: API response status=${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final equbs = _parseJoinedEqubs(response.data, userId: userId);
        _joinedEqubIds = equbs.map((equb) => equb.id).toSet();
        final nextValue = equbs.any(_isActiveJoinedEqub);
        AppLogger.log('JoinedEqubsStatusProvider: parsed ${equbs.length} equbs, active joined found: $nextValue');

        if (_hasJoinedEqubs != nextValue) {
          _hasJoinedEqubs = nextValue;
          _dataController.storeData(_cacheKey, _hasJoinedEqubs);
          notifyListeners();
        }
      }
    } catch (e) {
      AppLogger.error('JoinedEqubsStatusProvider: API refresh error: $e');
      // Keep cached value on failure.
    } finally {
      if (!silent && _isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    stopApprovalWatch();
    super.dispose();
  }
}
