import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api_url.dart';

class LotteryModel {
  final String id;
  final int lotteryNumber;
  final bool hasWonEqub;
  final int totalPaid;
  final int totalEligibilityPoint;
  final bool included;
  final bool excluded;
  final String state;
  final String? createdAt;

  LotteryModel({
    required this.id,
    required this.lotteryNumber,
    required this.hasWonEqub,
    required this.totalPaid,
    required this.totalEligibilityPoint,
    required this.included,
    required this.excluded,
    required this.state,
    this.createdAt,
  });

  factory LotteryModel.fromJson(Map<String, dynamic> json) {
    return LotteryModel(
      id: json["id"] ?? '',
lotteryNumber:
    int.tryParse(
      json["lotteryNumber"].toString(),
    ) ??
    0,      hasWonEqub: json["hasWonEqub"] ?? false,
      totalPaid: json["totalPaid"] ?? 0,
      totalEligibilityPoint:
          json["totalEligibilityPoint"] ?? 0,
      included: json["included"] ?? false,
      excluded: json["excluded"] ?? false,
      state: json["state"] ?? '',
      createdAt: json["createdAt"],
    );
  }
}

class LotteryProvider extends ChangeNotifier {
  final Dio dio = Dio();

  bool isLoading = false;

  List<LotteryModel> lotteries = [];
  
  Future<void> fetchLotteries(String equbId) async {
    try {
      isLoading = true;
      notifyListeners();

      final response = await dio.get(
        lotteriesListUrl+equbId,
      );

      
    if (response.statusCode == 200) {

      final List data =
          response.data["data"]["eligibleMembers"];

      lotteries = data
          .map((e) => LotteryModel.fromJson(e))
          .toList();
    }
    } catch (e) {
      debugPrint(e.toString());
    }

    isLoading = false;
    notifyListeners();
  }
}