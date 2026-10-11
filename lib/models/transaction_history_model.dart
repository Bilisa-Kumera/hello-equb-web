class Payment {
  final String id;
  final double amount;
  final Equb equb;
  final String paymentMethod;
  final String type;
  final DateTime createdAt;
  final double totalServiceFee;

  Payment({
    required this.id,
    required this.amount,
    required this.equb,
    required this.paymentMethod,
    required this.type,
    required this.createdAt,
    this.totalServiceFee = 0.0,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: json['amount'].toDouble(),
      equb: Equb.fromJson(json['equb']),
      paymentMethod: json['paymentMethod'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
      totalServiceFee: json['totalServiceFee'] != null 
          ? double.tryParse(json['totalServiceFee'].toString()) ?? 0.0 
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'equb': equb.toJson(),
      'type': type,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'totalServiceFee': totalServiceFee,
    };
  }
}

class Equb {
  final String id;
  final String name;
  final String status;
  final double serviceCharge;

  Equb({
    required this.id,
    required this.name,
    this.status = '',
    this.serviceCharge = 0.0,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';

  factory Equb.fromJson(Map<String, dynamic> json) {
    return Equb(
      id: json['id'],
      name: json['name'],
      status: json['status']?.toString() ?? '',
      serviceCharge: json['serviceCharge'] != null
          ? double.tryParse(json['serviceCharge'].toString()) ?? 0.0
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'serviceCharge': serviceCharge,
    };
  }
}

class PaymentsResponse {
  final String status;
  final double totalPaid;
  final double totalReceived;
  final double totalServiceFee;
  final List<Payment> paymentsMade;
  final List<Payment> paymentsReceived;

  PaymentsResponse({
    required this.status,
    required this.totalPaid,
    required this.totalReceived,
    required this.totalServiceFee,
    required this.paymentsMade,
    required this.paymentsReceived,
  });

  factory PaymentsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentsResponse(
      status: json['status'],
      totalPaid: json['data']['totalPaid'].toDouble(),
      totalReceived: json['data']['totalReceived'].toDouble(),
      totalServiceFee: json['data']['totalServiceFee']?.toDouble() ?? 0.0,
      paymentsMade: List<Payment>.from(
          json['data']['paymentsMade'].map((x) => Payment.fromJson(x))),
      paymentsReceived: List<Payment>.from(
          json['data']['paymentsReceived'].map((x) => Payment.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': {
        'totalPaid': totalPaid,
        'totalReceived': totalReceived,
        'totalServiceFee': totalServiceFee,
        'paymentsMade': List<dynamic>.from(paymentsMade.map((x) => x.toJson())),
        'paymentsReceived':
            List<dynamic>.from(paymentsReceived.map((x) => x.toJson())),
      },
    };
  }

  /// Excludes payments tied to completed equbs (shown on Equb History instead).
  PaymentsResponse withoutCompletedEqubs() {
    bool isOpen(Payment p) => !p.equb.isCompleted;
    final made = paymentsMade.where(isOpen).toList();
    final received = paymentsReceived.where(isOpen).toList();
    return PaymentsResponse(
      status: status,
      totalPaid: made.fold(0.0, (sum, p) => sum + p.amount),
      totalReceived: received.fold(0.0, (sum, p) => sum + p.amount),
      totalServiceFee: totalServiceFee,
      paymentsMade: made,
      paymentsReceived: received,
    );
  }
}
