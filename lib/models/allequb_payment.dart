class EqubResponse {
  String? status;
  EqubData? data;

  EqubResponse({this.status, this.data});

  factory EqubResponse.fromMap(Map<String, dynamic> map) {
    return EqubResponse(
      status: map['status'] as String?,
      data: map['data'] != null ? EqubData.fromMap(map['data']) : null,
    );
  }
}

class EqubData {
  List<Equb>? equbs;
  Meta? meta;

  EqubData({this.equbs, this.meta});

  factory EqubData.fromMap(Map<String, dynamic> map) {
    return EqubData(
      equbs: map['equbs'] != null
          ? List<Equb>.from((map['equbs'] as List).map((x) => Equb.fromMap(x)))
          : null,
      meta: map['meta'] != null ? Meta.fromMap(map['meta']) : null,
    );
  }
}

class Equb {
  String? id;
  String? name;
  String? description;
  String? equbTypeId;
  String? equbCategoryId;
  String? other;
  int? goal;
  int? numberOfEqubers;
  int? equbAmount;
  String? status;
  String? userId;
  String? staffId;
  int? previousRound;
  int? currentRound;
  int? nextRound;
  int? groupLimit;
  double? serviceCharge;
  String? nextRoundDate;
  String? nextRoundLotteryType;
  int? currentRoundWinners;
  String? nextRoundTime;
  String? startDate;
  String? endDate;
  String? state;
  String? branchId;
  String? createdAt;
  String? updatedAt;
  bool? hasLastRoundWinner;
  EqubType? equbType;
  List<Payment>? payment;
  EqubCategory? equbCategory;
  List<Equber>? equbers;

  Equb({
    this.id,
    this.name,
    this.description,
    this.equbTypeId,
    this.equbCategoryId,
    this.other,
    this.goal,
    this.numberOfEqubers,
    this.equbAmount,
    this.status,
    this.userId,
    this.staffId,
    this.previousRound,
    this.currentRound,
    this.nextRound,
    this.groupLimit,
    this.serviceCharge,
    this.nextRoundDate,
    this.nextRoundLotteryType,
    this.currentRoundWinners,
    this.nextRoundTime,
    this.startDate,
    this.endDate,
    this.state,
    this.branchId,
    this.createdAt,
    this.updatedAt,
    this.hasLastRoundWinner,
    this.equbType,
    this.payment,
    this.equbCategory,
    this.equbers,
  });

  factory Equb.fromMap(Map<String, dynamic> map) {
    return Equb(
      id: map['id']?.toString(),
      name: map['name']?.toString(),
      description: map['description']?.toString(),
      equbTypeId: map['equbTypeId']?.toString(),
      equbCategoryId: map['equbCategoryId']?.toString(),
      other: map['other']?.toString(),
      goal: _asInt(map['goal']),
      numberOfEqubers: _asInt(map['numberOfEqubers']),
      equbAmount: _asInt(map['equbAmount']),
      status: map['status']?.toString(),
      userId: map['userId']?.toString(),
      staffId: map['staffId']?.toString(),
      previousRound: _asInt(map['previousRound']),
      currentRound: _asInt(map['currentRound']),
      nextRound: _asInt(map['nextRound']),
      groupLimit: _asInt(map['groupLimit']),
      serviceCharge: _asDouble(map['serviceCharge']),
      nextRoundDate: map['nextRoundDate']?.toString(),
      nextRoundLotteryType: map['nextRoundLotteryType']?.toString(),
      currentRoundWinners: _asInt(map['currentRoundWinners']),
      nextRoundTime: map['nextRoundTime']?.toString(),
      startDate: map['startDate']?.toString(),
      endDate: map['endDate']?.toString(),
      state: map['state']?.toString(),
      branchId: map['branchId']?.toString(),
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
      hasLastRoundWinner: _asBool(map['hasLastRoundWinner']),
      equbType:
          map['equbType'] != null ? EqubType.fromMap(map['equbType']) : null,
      payment: map['Payment'] != null
          ? List<Payment>.from(
              (map['Payment'] as List).map((x) => Payment.fromMap(x)))
          : null,
      equbCategory: map['equbCategory'] != null
          ? EqubCategory.fromMap(map['equbCategory'])
          : null,
      equbers: map['equbers'] != null
          ? List<Equber>.from(
              (map['equbers'] as List).map((x) => Equber.fromMap(x)))
          : null,
    );
  }
}

class EqubType {
  String? id;
  String? name;

  EqubType({this.id, this.name});

  factory EqubType.fromMap(Map<String, dynamic> map) {
    return EqubType(
      id: map['id'] as String?,
      name: map['name'] as String?,
    );
  }
}

class Payment {
  String? id;
  String? type;
  double? amount;
  String? paymentMethod;
  int? round;
  bool? approved;
  String? state;
  String? createdAt;
  String? updatedAt;
  String? staffId;
  String? companyBankAccountId;
  String? equbId;
  String? equberId;
  String? equberUserId;
  String? picture;
  String? reference;
  String? userId;
  String? transactionId;

  Payment({
    this.id,
    this.type,
    this.amount,
    this.paymentMethod,
    this.round,
    this.approved,
    this.state,
    this.createdAt,
    this.updatedAt,
    this.staffId,
    this.companyBankAccountId,
    this.equbId,
    this.equberId,
    this.equberUserId,
    this.picture,
    this.reference,
    this.userId,
    this.transactionId,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id']?.toString(),
      type: map['type']?.toString(),
      amount: _asDouble(map['amount']),
      paymentMethod: map['paymentMethod']?.toString(),
      round: _asInt(map['round']),
      approved: _asBool(map['approved']),
      state: map['state']?.toString(),
      createdAt: map['createdAt']?.toString(),
      updatedAt: map['updatedAt']?.toString(),
      staffId: map['staffId']?.toString(),
      companyBankAccountId: map['companyBankAccountId']?.toString(),
      equbId: map['equbId']?.toString(),
      equberId: map['equberId']?.toString(),
      equberUserId: map['equberUserId']?.toString(),
      picture: map['picture']?.toString(),
      reference: map['reference']?.toString(),
      userId: map['userId']?.toString(),
      transactionId: map['transactionId']?.toString(),
    );
  }
}

class EqubCategory {
  String? id;
  String? name;
  bool? needsRequest;
  bool? isSaving;

  EqubCategory({this.id, this.name, this.needsRequest, this.isSaving});

  factory EqubCategory.fromMap(Map<String, dynamic> map) {
    return EqubCategory(
      id: map['id'] as String?,
      name: map['name'] as String?,
      needsRequest: map['needsRequest'] as bool?,
      isSaving: map['isSaving'] as bool?,
    );
  }
}

class Equber {
  String? id;
  String? lotteryNumber;

  Equber({this.id, this.lotteryNumber});

  factory Equber.fromMap(Map<String, dynamic> map) {
    return Equber(
      id: map['id'] as String?,
      lotteryNumber: map['lotteryNumber'] as String?,
    );
  }
}

class Meta {
  int? page;
  int? limit;
  int? total;

  Meta({this.page, this.limit, this.total});

  factory Meta.fromMap(Map<String, dynamic> map) {
    return Meta(
      page: _asInt(map['page']),
      limit: _asInt(map['limit']),
      total: _asInt(map['total']),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final normalized = value.toString().toLowerCase().trim();
  if (normalized == 'true') return true;
  if (normalized == 'false') return false;
  return null;
}
