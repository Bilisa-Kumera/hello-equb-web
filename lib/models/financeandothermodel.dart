class FinanceAndOtherResponse {
  final String? status;
  final Data? data;

  FinanceAndOtherResponse({
    this.status,
    this.data,
  });

  factory FinanceAndOtherResponse.fromJson(Map<String, dynamic> json) => FinanceAndOtherResponse(
        status: json["status"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "data": data?.toJson(),
      };
}

class Data {
  final List<UserData>? financeAndCar;
  final List<UserData>? financeAndHouse;
  final List<UserData>? financeAndTravel;
  final List<UserData>? specialFinance;

  Data({
    this.financeAndCar,
    this.financeAndHouse,
    this.financeAndTravel,
    this.specialFinance,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        financeAndCar: (json["financeAndCar"] as List<dynamic>?)
            ?.map((e) => UserData.fromJson(e))
            .toList(),
        financeAndHouse: (json["financeAndHouse"] as List<dynamic>?)
            ?.map((e) => UserData.fromJson(e))
            .toList(),
        financeAndTravel: (json["financeAndTravel"] as List<dynamic>?)
            ?.map((e) => UserData.fromJson(e))
            .toList(),
        specialFinance: (json["specialFinance"] as List<dynamic>?)
            ?.map((e) => UserData.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "financeAndCar": financeAndCar?.map((e) => e.toJson()).toList(),
        "financeAndHouse": financeAndHouse?.map((e) => e.toJson()).toList(),
        "financeAndTravel": financeAndTravel?.map((e) => e.toJson()).toList(),
        "specialFinance": specialFinance?.map((e) => e.toJson()).toList(),
      };
}

class UserData {
  final String? id;
  final String? middleName;
  final String? email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? avatar;
  final bool? isVerified;
  final String? state;
  final int? profileCompletion;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Equby>? joinedEqubs;

  UserData({
    this.id,
    this.middleName,
    this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.avatar,
    this.isVerified,
    this.state,
    this.profileCompletion,
    this.createdAt,
    this.updatedAt,
    this.joinedEqubs,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        id: json["id"],
        middleName: json["middleName"],
        email: json["email"],
        fullName: json["fullName"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        phoneNumber: json["phoneNumber"],
        avatar: json["avatar"],
        isVerified: json["isVerified"],
        state: json["state"],
        profileCompletion: json["profileCompletion"],
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : null,
        updatedAt: json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : null,
        joinedEqubs: (json["joinedEqubs"] as List<dynamic>?)
            ?.map((e) => Equby.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "middleName": middleName,
        "email": email,
        "fullName": fullName,
        "firstName": firstName,
        "lastName": lastName,
        "phoneNumber": phoneNumber,
        "avatar": avatar,
        "isVerified": isVerified,
        "state": state,
        "profileCompletion": profileCompletion,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "joinedEqubs": joinedEqubs?.map((e) => e.toJson()).toList(),
      };
}

class Equby {
  final String? id;
  final String? name;
  final String? description;
  final int? numberOfEqubers;
  final String? termAndCondition;
  final String? termAndConditionInAmharic;
  final int? equbAmount;
  final String? status;
  final String? state;
  final String? startDate;
  final EqubCategory? equbCategory;
  final EqubType? equbType;
  final String? equbTypeId;
  final String? equbCategoryId;
  final String? other;
  final int? equberCount;
  final double? serviceCharge;
  final String? nextRoundDate;
  final String? nextRoundTime;
  final String? nextRoundLotteryType;
  final bool? hasLastRoundWinner;

  Equby({
    this.id,
    this.name,
    this.description,
    this.numberOfEqubers,
    this.termAndCondition,
    this.termAndConditionInAmharic,
    this.equbAmount,
    this.status,
    this.state,
    this.startDate,
    this.equbCategory,
    this.equbType,
    this.equbTypeId,
    this.equbCategoryId,
    this.other,
    this.serviceCharge,
    this.equberCount,
    this.nextRoundDate,
    this.nextRoundTime,
    this.nextRoundLotteryType,
    this.hasLastRoundWinner,
  });

  factory Equby.fromJson(Map<String, dynamic> json) => Equby(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        numberOfEqubers: json["numberOfEqubers"],
        termAndCondition: json['termAndCondition']??'',
        termAndConditionInAmharic: json['termAndConditionInAmharic']??'',
        equbAmount: json["equbAmount"],
        status: json["status"],
        state: json["state"],
        startDate: json["startDate"],
        equbCategoryId: json["equbCategoryId"],
        equbTypeId: json["equbTypeId"],
        other: json["other"],
        serviceCharge: json["serviceCharge"]?.toDouble(),
        equberCount: json["equberCount"],
        nextRoundDate: json["nextRoundDate"],
        nextRoundTime: json["nextRoundTime"],
        nextRoundLotteryType: json["nextRoundLotteryType"],
        hasLastRoundWinner: json["hasLastRoundWinner"],
        equbCategory: json["equbCategory"] != null
            ? EqubCategory.fromJson(json["equbCategory"])
            : null,
        equbType: json["equbType"] != null
            ? EqubType.fromJson(json["equbType"])
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "numberOfEqubers": numberOfEqubers,
        "termAndCondition" : termAndCondition,
        "termAndConditionInAmharic": termAndConditionInAmharic,
        "equbAmount": equbAmount,
        "status": status,
        "state": state,
        "startDate": startDate,
        "equbCategoryId": equbCategoryId,
        "equbTypeId": equbTypeId,
        "other": other,
        "serviceCharge": serviceCharge,
        "equberCount": equberCount,
        "nextRoundDate": nextRoundDate,
        "nextRoundTime": nextRoundTime,
        "nextRoundLotteryType": nextRoundLotteryType,
        "hasLastRoundWinner": hasLastRoundWinner,
        "equbCategory": equbCategory?.toJson(),
        "equbType": equbType?.toJson(),
      };
}

class EqubCategory {
  final String? id;
  final String? name;
  final String? description;
  final bool? hasReason;
  final bool? isSaving;
  final bool? needsRequest;
  final int? order;
  final String? state;

  EqubCategory({
    this.id,
    this.name,
    this.description,
    this.hasReason,
    this.isSaving,
    this.needsRequest,
    this.order,
    this.state,
  });

  factory EqubCategory.fromJson(Map<String, dynamic> json) => EqubCategory(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        hasReason: json["hasReason"],
        isSaving: json["isSaving"],
        needsRequest: json["needsRequest"],
        order: json["order"],
        state: json["state"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "hasReason": hasReason,
        "isSaving": isSaving,
        "needsRequest": needsRequest,
        "order": order,
        "state": state,
      };
}

class EqubType {
  final String? id;
  final String? name;
  final String? description;
  final int? interval;
  final String? state;

  EqubType({
    this.id,
    this.name,
    this.description,
    this.interval,
    this.state,
  });

  factory EqubType.fromJson(Map<String, dynamic> json) => EqubType(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        interval: json["interval"],
        state: json["state"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "description": description,
        "interval": interval,
        "state": state,
      };
}
