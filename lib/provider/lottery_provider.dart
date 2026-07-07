import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/api_url.dart';

class LotteryModel {
  final String id;
  final int lotteryNumber;
  final bool hasWonEqub;
  final bool isNotified;
  final String equbId;
  final bool isGroup;
  final int dividedBy;
  final int filledPercent;
  final int totalPaid;
  final int paidRound;
  final int financePoint;
  final int kycPoint;
  final int adminPoint;
  final int totalEligibilityPoint;
  final bool included;
  final bool excluded;
  final bool show;
  final int? winRound;
  final String state;
  final String? createdAt;
  final String? updatedAt;
  final List<dynamic> users;
  final dynamic lotteryRequest;

  LotteryModel({
    required this.id,
    required this.lotteryNumber,
    required this.hasWonEqub,
    required this.isNotified,
    required this.equbId,
    required this.isGroup,
    required this.dividedBy,
    required this.filledPercent,
    required this.totalPaid,
    required this.paidRound,
    required this.financePoint,
    required this.kycPoint,
    required this.adminPoint,
    required this.totalEligibilityPoint,
    required this.included,
    required this.excluded,
    required this.show,
    this.winRound,
    required this.state,
    this.createdAt,
    this.updatedAt,
    this.users = const [],
    this.lotteryRequest,
  });

  factory LotteryModel.fromJson(Map<String, dynamic> json) {
    return LotteryModel(
      id: json["id"]?.toString() ?? '',
      lotteryNumber: int.tryParse(json["lotteryNumber"]?.toString() ?? '') ?? 0,
      hasWonEqub: json["hasWonEqub"] ?? false,
      isNotified: json["isNotified"] ?? false,
      equbId: json["equbId"]?.toString() ?? '',
      isGroup: json["isGroup"] ?? json["isGruop"] ?? false,
      dividedBy: int.tryParse(json["dividedBy"]?.toString() ?? '') ?? 0,
      filledPercent: int.tryParse(json["filledPercent"]?.toString() ?? '') ?? 0,
      totalPaid: int.tryParse(json["totalPaid"]?.toString() ?? '') ?? 0,
      paidRound: int.tryParse(json["paidRound"]?.toString() ?? '') ?? 0,
      financePoint: int.tryParse(json["financePoint"]?.toString() ?? '') ?? 0,
      kycPoint: int.tryParse(json["kycPoint"]?.toString() ?? '') ?? 0,
      adminPoint: int.tryParse(json["adminPoint"]?.toString() ?? '') ?? 0,
      totalEligibilityPoint:
          int.tryParse(json["totalEligibilityPoint"]?.toString() ?? '') ?? 0,
      included: json["included"] ?? false,
      excluded: json["excluded"] ?? false,
      show: json["show"] ?? false,
      winRound: json["winRound"] == null
          ? null
          : int.tryParse(json["winRound"]?.toString() ?? ''),
      state: json["state"] ?? '',
      createdAt: json["createdAt"]?.toString(),
      updatedAt: json["updatedAt"]?.toString(),
      users: (json["users"] as List<dynamic>?) ?? const [],
      lotteryRequest: json["lotteryRequest"],
    );
  }
}

class LotteryProvider extends ChangeNotifier {
  final Dio dio = Dio();

  bool isLoading = false;
  String? error;

  List<LotteryModel> lotteries = [];
  List<LotteryModel> winners = [];
  List<LotteryModel> eligibleMembers = [];

  Future<void> fetchLotteries(String equbId) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final response = await dio.get(lotteriesListUrl + equbId);

      if (response.statusCode == 200) {
        final data = response.data["data"];

        // Winners of the current round
        final List winnersData = data["currentRoundWinners"] ?? [];
        winners = winnersData
            .map((e) => LotteryModel.fromJson(e))
            .toList();

        // Main eligible members list (this is what populates the wheel)
        final List eligibleData = data["eligibleMembers"] ??
            data["equbEligibleMembers"] ?? [];
        eligibleMembers = eligibleData
            .map((e) => LotteryModel.fromJson(e))
            .toList();

        // Combine both so the wheel can show all relevant numbers
        lotteries = [...winners, ...eligibleMembers];
      }
    } catch (e) {
      error = e.toString();
      debugPrint("LotteryProvider Error: $e");
    }

    isLoading = false;
    notifyListeners();
  }
}