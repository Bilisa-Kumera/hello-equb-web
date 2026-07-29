import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/main.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../screens/my_equb_screen.dart';
import '../utils/getx_storage_custom.dart';
import '../utils/secure_storage.dart';

class GetMyEqubProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  bool _isLoading = false;
  String? _errorMessage;
  List<PendingEqub> _equbs = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<PendingEqub> get equbs => _equbs;

  Future<void> fetchEqubs({
    required String equbTypeId,
    required String equbCategoryId,
    required String userId,
    String status = 'joined',
    String search = '',
    String sortBy = 'newest',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final queryParams = <String, String>{
      'equbTypeId': equbTypeId,
      'user': userId,
      'status': status,
    };

    // IMPORTANT: When "All" is selected we pass an empty category id.
    // Some backends treat `equbCategoryId=` differently than omitting the param.
    if (equbCategoryId.isNotEmpty) {
      queryParams['equbCategoryId'] = equbCategoryId;
    }

    // Intentionally do not send `search`/`sortBy` until the backend contract is confirmed.

    final String endpoint =
        Uri.parse('$baseUrl/user/equb').replace(queryParameters: queryParams).toString();


    final String accessToken = await SecureStorageHelper.getAccessToken() ?? '';

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
        // The API returns: {status: ..., data: {equbs: [ ... ]}}
        final data = response.data;
        if (data is Map &&
            data['data'] != null &&
            data['data']['equbs'] is List) {
          _equbs = (data['data']['equbs'] as List)
              .map((json) => PendingEqub.fromJson(
                    json as Map<String, dynamic>,
                    currentUserId: userId,
                  ))
              .toList();
          PendingEqub.sortByLatestJoined(_equbs);
        } else {
          _equbs = [];
        }
      } else {
        _errorMessage = 'Failed to load equbs';
        _equbs = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
      _equbs = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _equbs = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}
