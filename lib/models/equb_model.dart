class EqubModel {
  final String? id;
  final String? name;
  final String? description;
  final String? equbTypeId;
  final String? equbCategoryId;
  final String? other;
  final dynamic goal;
  final int? numberOfEqubers;
  final String? termAndCondition;
  final String? termAndConditionInAmharic;
  final String? image;
  final int? equbAmount;
  final bool isActive;
  final String? status;
  final String? userId;
  final String? staffId;
  final int? previousRound;
  final int? currentRound;
  final int? nextRound;
  final int? groupLimit;
  final double? serviceCharge;
  final String? nextRoundDate;
  final String? nextRoundLotteryType;
  final int? currentRoundWinners;
  final bool? otherTypeEqub;
  final String? nextRoundTime;
  final String? startDate;
  final String? endDate;
  final String? ethiopianStartDate;
  final String? state;
  final String? branchId;
  final String? createdAt;
  final String? updatedAt;
  final bool? hasLastRoundWinner;
  final Map<String, dynamic>? equbType;
  final List<dynamic>? payment;
  final Map<String, dynamic>? equbCategory;
  final List<dynamic>? equbers;
  final Map<String, dynamic>? branch;

  EqubModel({
    this.id,
    this.name,
    this.description,
    this.equbTypeId,
    this.equbCategoryId,
    this.other,
    this.goal,
    this.numberOfEqubers,
    this.termAndCondition,
    this.termAndConditionInAmharic,
    this.image,
    this.equbAmount,
    required this.isActive,
    this.status,
    this.userId,
    this.otherTypeEqub,
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
    this.ethiopianStartDate,
    this.state,
    this.branchId,
    this.createdAt,
    this.updatedAt,
    this.hasLastRoundWinner,
    this.equbType,
    this.payment,
    this.equbCategory,
    this.equbers,
    this.branch,
  });

  factory EqubModel.fromJson(Map<String, dynamic> json) {
    return EqubModel(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      equbTypeId: json['equbTypeId'] as String?,
      equbCategoryId: json['equbCategoryId'] as String?,
      other: json['other'] as String?,
      goal: json['goal'],
      numberOfEqubers: json['numberOfEqubers'] as int?,
      termAndCondition: json['termAndCondition'] ?? '',
      termAndConditionInAmharic: json['termAndConditionInAmharic'] ?? '',
      image: json['image'] as String?,
      equbAmount: json['equbAmount'] as int?,
      isActive: json['isActive'] as bool? ?? false,
      otherTypeEqub: json['otherTypeEqub'] ?? false,
      status: json['status'] as String?,
      userId: json['userId'] as String?,
      staffId: json['staffId'] as String?,
      previousRound: json['previousRound'] as int?,
      currentRound: json['currentRound'] as int?,
      nextRound: json['nextRound'] as int?,
      groupLimit: json['groupLimit'] as int?,
      serviceCharge: (json['serviceCharge'] is int)
          ? (json['serviceCharge'] as int).toDouble()
          : json['serviceCharge'] as double?,
      nextRoundDate: json['nextRoundDate'] as String?,
      nextRoundLotteryType: json['nextRoundLotteryType'] as String?,
      currentRoundWinners: json['currentRoundWinners'] as int?,
      nextRoundTime: json['nextRoundTime'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      ethiopianStartDate: json['ethiopianStartDate'] as String?,
      state: json['state'] as String?,
      branchId: json['branchId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      hasLastRoundWinner: json['hasLastRoundWinner'] as bool?,
      equbType: json['equbType'] as Map<String, dynamic>?,
      payment: json['Payment'] as List<dynamic>?,
      equbCategory: json['equbCategory'] as Map<String, dynamic>?,
      equbers: json['equbers'] as List<dynamic>?,
      branch: json['branch'] as Map<String, dynamic>?,
    );
  }
}
