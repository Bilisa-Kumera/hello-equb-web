import 'dart:convert';

import 'package:ekubee/core/api_url.dart';
import 'package:ekubee/models/allequb_payment.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../utils/getx_storage_custom.dart';
import '../utils/secure_storage.dart';

class EqubPaymentProvider extends ChangeNotifier {
  List<Equb> equbs = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = false;
  String? lastError;

  final int limit = 10; 
  final Dio _dio = Dio();
  final String apiUrl = '$baseUrl/user/equb/getAllJoinedEqubs';
  final DataController dataController = DataController();

  Future<void> fetchEqubs({int page = 1}) async {
    if (isLoading || page > totalPages) return;

    isLoading = true;
    lastError = null;
    notifyListeners();
    final String accessToken = await SecureStorageHelper.getAccessToken() ?? '';

    try {
      final response = await _dio.get(
        apiUrl,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
        ),
      );

      if (response.statusCode == 200) {
        final dynamic raw = response.data;
        final Map<String, dynamic> data = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(jsonDecode(raw.toString()));

        final equbResponse = EqubResponse.fromMap(data);

        final List<Equb> nextEqubs = equbResponse.data?.equbs ?? const [];
        if (page == 1) {
          equbs = List<Equb>.from(nextEqubs);
        } else {
          equbs.addAll(nextEqubs);
        }

        totalPages = ((equbResponse.data?.meta?.total ?? 0) / limit).ceil();
        currentPage = page;
      }
    } catch (e) {
      lastError = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (currentPage < totalPages) {
      await fetchEqubs(page: currentPage + 1);
    }
  }

  Future<void> refreshEqubs() async {
    equbs.clear();
    currentPage = 1;
    totalPages = 1;
    await fetchEqubs(page: 1);
  }
}
