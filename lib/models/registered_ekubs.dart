class Equbs {
  String id;
  String name;
  String description;
  String serviceCharge;
  String equbTypeId;
  String equbCategoryId;
  dynamic numberOfEqubers;
  dynamic ekubAmount;
  String status;
  String? userId;
  String staffId;
  int currentRound;
  int nextRound;
  int groupLimit;
  DateTime? nextRoundDate;
  int currentRoundWinners;
  String nextRoundTime;
  DateTime startDate;
  DateTime? endDate;
  String state;
  String branchId;
  DateTime createdAt;
  DateTime updatedAt;
  EqubType equbType;
  EqubCategoryys equbCategory;
  Branch branch;
  List<Equbers> equbers; // New field

  Equbs({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceCharge,
    required this.equbTypeId,
    required this.equbCategoryId,
    required this.numberOfEqubers,
    required this.status,
    this.userId,
    required this.ekubAmount,
    required this.staffId,
    required this.currentRound,
    required this.nextRound,
    required this.groupLimit,
    this.nextRoundDate,
    required this.currentRoundWinners,
    required this.nextRoundTime,
    required this.startDate,
    this.endDate,
    required this.state,
    required this.branchId,
    required this.createdAt,
    required this.updatedAt,
    required this.equbType,
    required this.equbCategory,
    required this.branch,
    required this.equbers, // New field
  });

  factory Equbs.fromJson(Map<String, dynamic> json) {
    return Equbs(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      serviceCharge: json['serviceCharge'].toString(),
      equbTypeId: json['equbTypeId'],
      equbCategoryId: json['equbCategoryId'],
      numberOfEqubers: json['numberOfEqubers'],
      status: json['status'],
      ekubAmount: json['equbAmount'],
      userId: json['userId'],
      staffId: json['staffId'],
      currentRound: json['currentRound'],
      nextRound: json['nextRound'],
      groupLimit: json['groupLimit']??1,
      nextRoundDate: json['nextRoundDate'] != null ? DateTime.parse(json['nextRoundDate']) : null,
      currentRoundWinners: json['currentRoundWinners'],
      nextRoundTime: json['nextRoundTime'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      state: json['state'],
      branchId: json['branchId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      equbType: EqubType.fromJson(json['equbType']),
      equbCategory: EqubCategoryys.fromJson(json['equbCategory']),
      branch: Branch.fromJson(json['branch']),
      equbers: json['equbers'] != null ? (json['equbers'] as List)
          .map((item) => Equbers.fromJson(item))
          .toList(): [], // Handling the new field
    );
  }
}

class EqubType {
  String id;
  String name;

  EqubType({
    required this.id,
    required this.name,
  });

  factory EqubType.fromJson(Map<String, dynamic> json) {
    return EqubType(
      id: json['id'],
      name: json['name'],
    );
  }
}

class EqubCategoryys {
  String id;
  String name;
  bool isSaving;

  EqubCategoryys({
    required this.id,
    required this.name,
    required this.isSaving
  });

  factory EqubCategoryys.fromJson(Map<String, dynamic> json) {
    return EqubCategoryys(
      id: json['id'],
      name: json['name'],
      isSaving: json['isSaving']??false
    );
  }
}

class Branch {
  String id;
  String name;

  Branch({
    required this.id,
    required this.name,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Equbers {
  String id;

  Equbers({
    required this.id,
  });

  factory Equbers.fromJson(Map<String, dynamic> json) {
    return Equbers(
      id: json['id'],
    );
  }
}

