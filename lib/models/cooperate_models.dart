import 'equb_model.dart';

class CooperateResponse {
  final String? status;
  final CooperateData? data;

  CooperateResponse({this.status, this.data});

  factory CooperateResponse.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CooperateResponse();
    return CooperateResponse(
      status: json['status'] as String?,
      data: CooperateData.fromJson(json['data'] as Map<String, dynamic>?),
    );
  }
}

class CooperateData {
  final List<Cooperate>? cooperates;
  final Meta? meta;

  CooperateData({this.cooperates, this.meta});

  factory CooperateData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CooperateData(cooperates: const [], meta: null);
    final List<dynamic>? rawList = json['cooperates'] as List<dynamic>?;
    return CooperateData(
      cooperates: (rawList ?? const [])
          .map((e) => Cooperate.fromJson(e as Map<String, dynamic>?))
          .toList(),
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>?),
    );
  }
}

class Meta {
  final int? page;
  final int? limit;
  final int? total;

  Meta({this.page, this.limit, this.total});

  factory Meta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Meta();
    return Meta(
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
    );
  }
}

class Cooperate {
  final String? id;
  final String? email;
  final String? name;
  final String? phoneNumber;
  final String? address;
  final String? imageIcon;
  final String? code;
  final String? state;
  final String? createdAt;
  final String? updatedAt;
  final List<CooperateEqubLink>? cooperateEqub;
  final List<EqubModel>? equbs;

  Cooperate({
    this.id,
    this.email,
    this.name,
    this.phoneNumber,
    this.imageIcon,
    this.address,
    this.code,
    this.state,
    this.createdAt,
    this.updatedAt,
    this.cooperateEqub,
    this.equbs,
  });

  factory Cooperate.fromJson(Map<String, dynamic>? json) {
    if (json == null) return Cooperate();
    final List<dynamic>? rawLinks = json['CooperateEqub'] as List<dynamic>?;
    final List<dynamic>? rawEqubs = json['equbs'] as List<dynamic>?;
    return Cooperate(
      id: json['id'] as String?,
      email: json['email'] as String?,
      name: json['name'] as String?,
      imageIcon: json['icon']??'',
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      code: json['code'] as String?,
      state: json['state'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      cooperateEqub: (rawLinks ?? const [])
          .map((e) => CooperateEqubLink.fromJson(e as Map<String, dynamic>?))
          .toList(),
      equbs: (rawEqubs ?? const [])
          .map((e) => EqubModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CooperateEqubLink {
  final String? id;
  final String? equbId;
  final String? cooperatesId;
  final String? createdAt;
  final String? updatedAt;
  final EqubModel? equb;

  CooperateEqubLink({
    this.id,
    this.equbId,
    this.cooperatesId,
    this.createdAt,
    this.updatedAt,
    this.equb,
  });

  factory CooperateEqubLink.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CooperateEqubLink();
    final equbJson = json['equb'];
    return CooperateEqubLink(
      id: json['id'] as String?,
      equbId: json['equbId'] as String?,
      cooperatesId: json['cooperatesId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      equb: equbJson is Map<String, dynamic>
          ? EqubModel.fromJson(equbJson)
          : null,
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed;
  }
  return null;
}

