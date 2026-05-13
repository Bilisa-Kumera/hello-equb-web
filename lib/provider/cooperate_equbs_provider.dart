import 'package:flutter/material.dart';
import 'package:ekubee/core/api_service_elper.dart';
import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/cooperate_models.dart';

import '../utils/getx_storage_custom.dart';
import '../utils/secure_storage.dart';

class CooperateEqubsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  List<Cooperate> _cooperates = [];
  Meta? _meta;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Cooperate> get cooperates => _cooperates;
  Meta? get meta => _meta;

  Future<void> fetchCooperates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String bearerToken = await SecureStorageHelper.getAccessToken() ?? '';
      final response =
          await _apiService.readAll(cooperateEqubUrl, bearerToken: bearerToken);
      if (response is String && response == 'Token is not valid') {
        _error = 'Token is not valid';
      } else if (response != null && response['status'] == 'success') {
        final parsed =
            CooperateResponse.fromJson(response as Map<String, dynamic>);
        _cooperates = parsed.data?.cooperates ?? [];
        _meta = parsed.data?.meta;
      } else {
        _error = 'Failed to load cooperates';
      }
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}
