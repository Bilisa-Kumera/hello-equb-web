class ApiResponses {
  final String status;
  final PaymentData? data;

  ApiResponses({required this.status, this.data});

  factory ApiResponses.fromJson(Map<String, dynamic> json) {
    return ApiResponses(
      status: json['status'] as String,
      data: json['data'] != null ? PaymentData.fromJson(json['data']) : null,
    );
  }
}

class PaymentData {
  final Payment? payments;

  PaymentData({this.payments});

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      payments: json['payments'] != null ? Payment.fromJson(json['payments']) : null,
    );
  }
}

class Payment {
  final Equb? equb;
  final List<Lottery>? lotteries;

  Payment({this.equb, this.lotteries});

  factory Payment.fromJson(Map<String, dynamic> json) {
    var lotteriesList = json['lotteries'] as List? ?? [];
    return Payment(
      equb: json['equb'] != null ? Equb.fromJson(json['equb']) : null,
      lotteries: lotteriesList.map((lottery) => Lottery.fromJson(lottery)).toList(),
    );
  }
}

class Equb {
  final String id;
  final String name;
  final int goal;
  final int equbAmount;
  final int totalPaid;

  Equb({
    required this.id,
    required this.name,
    required this.goal,
    required this.equbAmount,
    required this.totalPaid,
  });

  factory Equb.fromJson(Map<String, dynamic> json) {
    return Equb(
      id: json['id'] as String,
      name: json['name'] as String,
      goal: json['goal'] as int,
      equbAmount: json['equbAmount'] as int,
      totalPaid: json['totalPaid'] as int,
    );
  }
}

class Lottery {
  final String lotteryNumber;
  final int totalPaid;
  final DateTime lastPaidOn;
  final String equberUserId;

  Lottery({
    required this.lotteryNumber,
    required this.totalPaid,
    required this.lastPaidOn,
    required this.equberUserId
  });

  factory Lottery.fromJson(Map<String, dynamic> json) {
    return Lottery(
      lotteryNumber: json['lotteryNumber'] as String,
      totalPaid: json['totalPaid'] as int,
      lastPaidOn: DateTime.parse(json['lastPaidOn'] as String),
      equberUserId: json['equberUserId'] as String
    );
  }
}
