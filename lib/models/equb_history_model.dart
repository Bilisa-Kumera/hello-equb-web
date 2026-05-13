class EqubHistoryResponse {
  final String status;
  final EqubHistoryData data;

  EqubHistoryResponse({
    required this.status,
    required this.data,
  });

  factory EqubHistoryResponse.fromJson(Map<String, dynamic> json) {
    return EqubHistoryResponse(
      status: json['status']?.toString() ?? '',
      data: EqubHistoryData.fromJson(
        Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      ),
    );
  }
}

class EqubHistoryData {
  final List<EqubHistoryEqub> equbs;
  final EqubHistoryMeta? meta;

  EqubHistoryData({
    required this.equbs,
    required this.meta,
  });

  factory EqubHistoryData.fromJson(Map<String, dynamic> json) {
    final equbsJson = (json['equbs'] as List?) ?? const [];
    return EqubHistoryData(
      equbs: equbsJson
          .whereType<Map>()
          .map((e) => EqubHistoryEqub.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      meta: json['meta'] is Map
          ? EqubHistoryMeta.fromJson(Map<String, dynamic>.from(json['meta']))
          : null,
    );
  }
}

class EqubHistoryMeta {
  final int page;
  final int limit;
  final int total;

  EqubHistoryMeta({
    required this.page,
    required this.limit,
    required this.total,
  });

  factory EqubHistoryMeta.fromJson(Map<String, dynamic> json) {
    return EqubHistoryMeta(
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
    );
  }
}

class EqubHistoryEqub {
  final String id;
  final String name;
  final String description;
  final String status; // e.g. completed
  final String state; // e.g. active/inactive
  final int numberOfEqubers;
  final double equbAmount;
  final double serviceCharge;
  final int previousRound;
  final int currentRound;
  final int nextRound;
  final String nextRoundTime;
  final String nextRoundLotteryType;
  final DateTime? nextRoundDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool hasLastRoundWinner;
  final EqubHistoryEqubType? equbType;
  final EqubHistoryEqubCategory? equbCategory;
  final EqubHistoryBranch? branch;
  final List<EqubHistoryPayment> payments;

  EqubHistoryEqub({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.state,
    required this.numberOfEqubers,
    required this.equbAmount,
    required this.serviceCharge,
    required this.previousRound,
    required this.currentRound,
    required this.nextRound,
    required this.nextRoundTime,
    required this.nextRoundLotteryType,
    required this.nextRoundDate,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
    required this.hasLastRoundWinner,
    required this.equbType,
    required this.equbCategory,
    required this.branch,
    required this.payments,
  });

  factory EqubHistoryEqub.fromJson(Map<String, dynamic> json) {
    final paymentsJson = (json['Payment'] as List?) ?? const [];
    return EqubHistoryEqub(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      numberOfEqubers: _toInt(json['numberOfEqubers']),
      equbAmount: _toDouble(json['equbAmount']),
      serviceCharge: _toDouble(json['serviceCharge']),
      previousRound: _toInt(json['previousRound']),
      currentRound: _toInt(json['currentRound']),
      nextRound: _toInt(json['nextRound']),
      nextRoundTime: json['nextRoundTime']?.toString() ?? '',
      nextRoundLotteryType: json['nextRoundLotteryType']?.toString() ?? '',
      nextRoundDate: _tryParseDateTime(json['nextRoundDate']),
      startDate: _tryParseDateTime(json['startDate']),
      endDate: _tryParseDateTime(json['endDate']),
      createdAt: _tryParseDateTime(json['createdAt']),
      updatedAt: _tryParseDateTime(json['updatedAt']),
      hasLastRoundWinner: json['hasLastRoundWinner'] == true,
      equbType: json['equbType'] is Map
          ? EqubHistoryEqubType.fromJson(
              Map<String, dynamic>.from(json['equbType']),
            )
          : null,
      equbCategory: json['equbCategory'] is Map
          ? EqubHistoryEqubCategory.fromJson(
              Map<String, dynamic>.from(json['equbCategory']),
            )
          : null,
      branch: json['branch'] is Map
          ? EqubHistoryBranch.fromJson(
              Map<String, dynamic>.from(json['branch']),
            )
          : null,
      payments: paymentsJson
          .whereType<Map>()
          .map((e) => EqubHistoryPayment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class EqubHistoryEqubType {
  final String id;
  final String name;

  EqubHistoryEqubType({
    required this.id,
    required this.name,
  });

  factory EqubHistoryEqubType.fromJson(Map<String, dynamic> json) {
    return EqubHistoryEqubType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class EqubHistoryEqubCategory {
  final String id;
  final String name;

  EqubHistoryEqubCategory({
    required this.id,
    required this.name,
  });

  factory EqubHistoryEqubCategory.fromJson(Map<String, dynamic> json) {
    return EqubHistoryEqubCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class EqubHistoryBranch {
  final String id;
  final String name;

  EqubHistoryBranch({
    required this.id,
    required this.name,
  });

  factory EqubHistoryBranch.fromJson(Map<String, dynamic> json) {
    return EqubHistoryBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class EqubHistoryPayment {
  final String id;
  final String type;
  final double amount;
  final String paymentMethod;
  final int round;
  final bool approved;
  final String state;
  final DateTime? createdAt;
  final String? reference;

  EqubHistoryPayment({
    required this.id,
    required this.type,
    required this.amount,
    required this.paymentMethod,
    required this.round,
    required this.approved,
    required this.state,
    required this.createdAt,
    required this.reference,
  });

  factory EqubHistoryPayment.fromJson(Map<String, dynamic> json) {
    return EqubHistoryPayment(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      round: _toInt(json['round']),
      approved: json['approved'] == true,
      state: json['state']?.toString() ?? '',
      createdAt: _tryParseDateTime(json['createdAt']),
      reference: json['reference']?.toString(),
    );
  }
}

int _toInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

DateTime? _tryParseDateTime(dynamic v) {
  final s = v?.toString();
  if (s == null || s.isEmpty || s == 'null') return null;
  return DateTime.tryParse(s);
}

