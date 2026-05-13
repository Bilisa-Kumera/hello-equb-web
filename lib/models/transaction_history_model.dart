class Payment {
  final String id;
  final double amount;
  final Equb equb;
  final String paymentMethod;
  final String type;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.amount,
    required this.equb,
    required this.paymentMethod,
    required this.type,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      amount: json['amount'].toDouble(),
      equb: Equb.fromJson(json['equb']),
      paymentMethod: json['paymentMethod'],
      type: json['type'],
      createdAt: DateTime.parse(json['createdAt']),
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
    };
  }
}

class Equb {
  final String id;
  final String name;

  Equb({
    required this.id,
    required this.name,
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

class PaymentsResponse {
  final String status;
  final double totalPaid;
  final double totalReceived;
  final List<Payment> paymentsMade;
  final List<Payment> paymentsReceived;

  PaymentsResponse({
    required this.status,
    required this.totalPaid,
    required this.totalReceived,
    required this.paymentsMade,
    required this.paymentsReceived,
  });

  factory PaymentsResponse.fromJson(Map<String, dynamic> json) {
    return PaymentsResponse(
      status: json['status'],
      totalPaid: json['data']['totalPaid'].toDouble(),
      totalReceived: json['data']['totalReceived'].toDouble(),
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
        'paymentsMade': List<dynamic>.from(paymentsMade.map((x) => x.toJson())),
        'paymentsReceived':
            List<dynamic>.from(paymentsReceived.map((x) => x.toJson())),
      },
    };
  }
}
