class ReportDataResponse {
  final String? status;
  final ReportData? data;

  ReportDataResponse({
    this.status,
    this.data,
  });

  factory ReportDataResponse.fromJson(Map<String, dynamic> json) {
    return ReportDataResponse(
      status: json['status'] as String?,
      data: json['data'] != null ? ReportData.fromJson(json['data']) : null,
    );
  }
}

class ReportData {
  final String? equbName;
  final EqubType? equbType;
  final List<Equber>? equbers;

  ReportData({
    this.equbName,
    this.equbType,
    this.equbers,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      equbName: json['equbName'] as String?,
      equbType: json['equbType'] != null ? EqubType.fromJson(json['equbType']) : null,
      equbers: json['equbers'] != null
          ? (json['equbers'] as List).map((equber) => Equber.fromJson(equber)).toList()
          : null,
    );
  }
}

class EqubType {
  final String? id;
  final String? name;
  final String? description;
  final int? interval;
  final String? state;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EqubType({
    this.id,
    this.name,
    this.description,
    this.interval,
    this.state,
    this.createdAt,
    this.updatedAt,
  });

  factory EqubType.fromJson(Map<String, dynamic> json) {
    return EqubType(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      interval: json['interval'] as int?,
      state: json['state'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

class Equber {
  final String? lotteryNumber;
  final int? totalPaid;
  final int? claimAmount;
  final List<Payment>? payments;
  final Guarantee? guarantee;

  Equber({
    this.lotteryNumber,
    this.totalPaid,
    this.claimAmount,
    this.payments,
    this.guarantee,
  });

  factory Equber.fromJson(Map<String, dynamic> json) {
    return Equber(
      lotteryNumber: json['lotteryNumber'] as String?,
      totalPaid: json['totalPaid'] as int?,
      claimAmount: json['claimAmount'] as int?,
      payments: json['payments'] != null
          ? (json['payments'] as List).map((paymentJson) => Payment.fromJson(paymentJson)).toList()
          : null,
      guarantee: json['guarantee'] is Map<String, dynamic>
          ? Guarantee.fromJson(json['guarantee'])
          : null,
    );
  }
}

class Guarantee {
  final String? id;
  final String? middleName;
  final String? email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  Guarantee({
    this.id,
    this.middleName,
    this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  factory Guarantee.fromJson(Map<String, dynamic> json) {
    return Guarantee(
      id: json['id'] as String?,
      middleName: json['middleName'] as String?,
      email: json['email'] as String?,
      fullName: json['fullName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}

class Payment {
  final String? id;
  final int? amount;
  final String? paymentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? equberUserId;

  Payment({
    this.id,
    this.amount,
    this.paymentId,
    this.createdAt,
    this.updatedAt,
    this.equberUserId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String?,
      amount: json['amount'] as int?,
      paymentId: json['paymentId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      equberUserId: json['equberUserId'] as String?,
    );
  }
}
