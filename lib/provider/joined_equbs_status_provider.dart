import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/screens/my_equb_screen.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';
import 'package:helloequb/utils/lang_constants.dart';
import 'package:helloequb/utils/secure_storage.dart';

class JoinedEqubsStatusProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  static const _cacheKey = 'hasJoinedEqubs';

  final DataController _dataController = DataController();
  final Dio _dio = Dio();

  bool _hasJoinedEqubs;
  bool _isLoading = false;
  bool _isWatching = false;

  JoinedEqubsStatusProvider()
      : _hasJoinedEqubs =
            DataController().retrieveData<bool>(_cacheKey) ?? false;

  bool get hasJoinedEqubs => _hasJoinedEqubs;
  bool get isLoading => _isLoading;

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

  List<PendingEqub> _parseJoinedEqubs(dynamic raw) {
    final Map<String, dynamic> data = raw is Map<String, dynamic>
        ? raw
        : Map<String, dynamic>.from(jsonDecode(raw.toString()));
    final equbsJson = data['data']?['equbs'];

    if (equbsJson is! List) return const [];

    return equbsJson
        .map((json) => PendingEqub.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final accessToken = await SecureStorageHelper.getAccessToken() ?? '';
      final userId = await SecureStorageHelper.getUserId() ?? '';
      if (accessToken.isEmpty || userId.isEmpty) return;

      final response = await _dio.get(
        ekubsUrl,
        queryParameters: {
          '_page': '1',
          '_limit': '50',
          'user': userId,
          'status': 'joined',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200) {
        final equbs = _parseJoinedEqubs(response.data);
        final nextValue = equbs.any(_isActiveJoinedEqub);

        if (_hasJoinedEqubs != nextValue) {
          _hasJoinedEqubs = nextValue;
          _dataController.storeData(_cacheKey, _hasJoinedEqubs);
          notifyListeners();
        }
      }
    } catch (_) {
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
