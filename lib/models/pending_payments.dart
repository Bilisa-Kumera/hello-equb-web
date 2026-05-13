
class Equb {
  final String id;
  final String? name;

  Equb({
    required this.id,
    this.name,
  });

  factory Equb.fromJson(Map<String, dynamic> json) {
    return Equb(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class EquberUserPayment {
  final String id;
  final double? amount;
  final String? paymentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? equberUserId;

  EquberUserPayment({
    required this.id,
    this.amount,
    this.paymentId,
    this.createdAt,
    this.updatedAt,
    this.equberUserId,
  });

  factory EquberUserPayment.fromJson(Map<String, dynamic> json) {
    return EquberUserPayment(
      id: json['id'],
      amount: (json['amount'] as num?)?.toDouble(),
      paymentId: json['paymentId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      equberUserId: json['equberUserId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paymentId': paymentId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'equberUserId': equberUserId,
    };
  }
}

class Payment {
  final String id;
  final String? type;
  final double? amount;
  final String? paymentMethod;
  final int? round;
  final bool? approved;
  final String? state;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? staffId;
  final String? equbId;
  final String? equberId;
  final String? picture;
  final String? reference;
  final String? userId;
  final Equb? equb;
  final List<EquberUserPayment>? equberUserPayments;

  Payment({
    required this.id,
    this.type,
    this.amount,
    this.paymentMethod,
    this.round,
    this.approved,
    this.state,
    this.createdAt,
    this.updatedAt,
    this.staffId,
    this.equbId,
    this.equberId,
    this.picture,
    this.reference,
    this.userId,
    this.equb,
    this.equberUserPayments,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num?)?.toDouble(),
      paymentMethod: json['paymentMethod'],
      round: json['round'],
      approved: json['approved'],
      state: json['state'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      staffId: json['staffId'],
      equbId: json['equbId'],
      equberId: json['equberId'],
      picture: json['picture'],
      reference: json['reference'],
      userId: json['userId'],
      equb: json['equb'] != null ? Equb.fromJson(json['equb']) : null,
      equberUserPayments: json['equberUserPayments'] != null
          ? (json['equberUserPayments'] as List)
              .map((e) => EquberUserPayment.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'round': round,
      'approved': approved,
      'state': state,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'staffId': staffId,
      'equbId': equbId,
      'equberId': equberId,
      'picture': picture,
      'reference': reference,
      'userId': userId,
      'equb': equb?.toJson(),
      'equberUserPayments':
          equberUserPayments?.map((e) => e.toJson()).toList(),
    };
  }
}

class Meta {
  final int? page;
  final int? limit;
  final int? total;

  Meta({
    this.page,
    this.limit,
    this.total,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
    };
  }
}

class Data {
  final List<Payment>? payments;
  final Meta? meta;

  Data({
    this.payments,
    this.meta,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      payments: json['payments'] != null
          ? (json['payments'] as List)
              .map((e) => Payment.fromJson(e))
              .toList()
          : null,
      meta: json['meta'] != null ? Meta.fromJson(json['meta']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payments': payments?.map((e) => e.toJson()).toList(),
      'meta': meta?.toJson(),
    };
  }
}

class ApiResponse {
  final String status;
  final Data? data;

  ApiResponse({
    required this.status,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'],
      data: json['data'] != null ? Data.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data?.toJson(),
    };
  }
}
