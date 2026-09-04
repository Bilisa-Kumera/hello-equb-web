import 'package:flutter/material.dart';
import 'package:helloequb/core/api_service_elper.dart';
import 'package:helloequb/core/api_url.dart';
import 'package:helloequb/models/app_promo_model.dart';
import 'package:helloequb/utils/getx_storage_custom.dart';

class AppPromoProvider extends ChangeNotifier {
  static const dismissedPromoIdKey = 'dismissed_app_promo_id';

  final DataController _dataController = DataController();

  AppPromo? _promo;
  bool _isLoading = false;
  bool _disposed = false;

  AppPromo? get promo => _promo;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  String? get dismissedPromoId =>
      _dataController.retrieveData<String>(dismissedPromoIdKey);

  bool shouldShowPromo(AppPromo promo) {
    final dismissedId = dismissedPromoId;
    if (dismissedId == null || dismissedId.isEmpty) return true;
    return dismissedId != promo.id;
  }

  void dismissPromo(String promoId) {
    _dataController.storeData<String>(dismissedPromoIdKey, promoId);
  }

  Future<AppPromo?> fetchActivePromo() async {
    if (_disposed) return null;

    _isLoading = true;
    _safeNotifyListeners();

    try {
      final apiService = ApiService();
      final data = await apiService.readAll(appPromoActiveUrl);

      if (_disposed) return null;

      final promoJson = data?['data']?['promo'];
      if (promoJson == null || promoJson is! Map<String, dynamic>) {
        _promo = null;
        return null;
      }

      final promo = AppPromo.fromJson(promoJson);
      if (promo.id.isEmpty || promo.imageUrl.isEmpty) {
        _promo = null;
        return null;
      }

      _promo = promo;
      return promo;
    } catch (_) {
      _promo = null;
      return null;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        _safeNotifyListeners();
      }
    }
  }
}
