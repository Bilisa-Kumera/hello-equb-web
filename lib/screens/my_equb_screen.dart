// ignore_for_file: deprecated_member_use, use_build_context_synchronously

class PendingEqub {
  final String id;
  final String name;
  final String description;
  final String equbTypeId;
  final String nextRoundLotteryType;
  final String equbCategoryId;
  final int numberOfEqubers;
  final int equbAmount;
  final String status;
  final String? userId;
  final String staffId;
  final int currentRound;
  final int nextRound;
  final int groupLimit;
  final double serviceCharge;
  final DateTime startDate;
  final DateTime? endDate;
  final String? ethiopianStartDate;
  final String? ethiopianEndDate;
  final String? nextRoundDate;
  final String? nextRoundTime;
  final String state;
  final String branchId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When the current user joined this equb (from their payments), if known.
  final DateTime? userJoinedAt;

  final EqubType? equbType;
  final EqubCategoryss? equbCategory;
  final List<Equber>? equbers;
  final Branch? branch;
  final String? totalPaid;

  /// Derived from approved equb payments on the joined-list payload.
  final int lastPaidRound;

  /// Derived from approved equb payments on the joined-list payload.
  // final int lastPaidRound;

  PendingEqub({
    required this.id,
    required this.name,
    required this.description,
    required this.equbTypeId,
    required this.nextRoundLotteryType,
    required this.equbCategoryId,
    required this.numberOfEqubers,
    required this.equbAmount,
    required this.status,
    this.userId,
    required this.staffId,
    required this.currentRound,
    required this.nextRound,
    required this.groupLimit,
    required this.serviceCharge,
    required this.startDate,
    this.endDate,
    this.ethiopianStartDate,
    this.ethiopianEndDate,
    this.nextRoundDate,
    this.nextRoundTime,
    required this.state,
    required this.branchId,
    required this.createdAt,
    required this.updatedAt,
    this.userJoinedAt,
    this.equbType,
    this.equbCategory,
    this.equbers,
    this.branch,
    this.totalPaid,
    this.lastPaidRound = 0,
  });

  int get slotCount => (equbers?.isNotEmpty ?? false) ? equbers!.length : 1;

  /// Fully paid up for every lottery slot in this equb.
  bool get isFullyPaid =>
      lastPaidRound >= numberOfEqubers && numberOfEqubers > 0;

  /// Earliest payment by [currentUserId] on this equb ≈ when they joined.
  static DateTime? joinedAtFromJson(
      Map<String, dynamic> json, String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return null;
    final payments = json['Payment'] ?? json['payments'];
    if (payments is! List) return null;

    DateTime? earliestRegistering;
    DateTime? earliestAny;
    for (final raw in payments) {
      if (raw is! Map) continue;
      if (raw['userId']?.toString() != currentUserId) continue;
      final created = DateTime.tryParse(raw['createdAt']?.toString() ?? '');
      if (created == null) continue;
      final type = raw['type']?.toString().toLowerCase() ?? '';
      if (type.contains('registering')) {
        if (earliestRegistering == null ||
            created.isBefore(earliestRegistering)) {
          earliestRegistering = created;
        }
      }
      if (earliestAny == null || created.isBefore(earliestAny)) {
        earliestAny = created;
      }
    }
    return earliestRegistering ?? earliestAny;
  }

  /// Last paid-up-to round from joined-list `Payment` rows (no detail fetch).
  static int lastPaidRoundFromJson(Map<String, dynamic> json) {
    final payments = json['Payment'] ?? json['payments'];
    if (payments is! List || payments.isEmpty) return 0;

    final roundAmount = (json['equbAmount'] as num?)?.toInt() ?? 0;
    if (roundAmount <= 0) return 0;

    final slots = json['equbers'] is List ? (json['equbers'] as List).length : 1;
    final slotCount = slots > 0 ? slots : 1;

    var paymentSum = 0.0;
    var maxRound = 0;
    for (final raw in payments) {
      if (raw is! Map) continue;
      final type = raw['type']?.toString().toLowerCase() ?? '';
      if (type == 'lottery') continue;
      if (raw['approved'] != true) continue;
      if (raw['state']?.toString() == 'deleted') continue;

      paymentSum += (raw['amount'] as num?)?.toDouble() ?? 0;
      final round = int.tryParse(raw['round']?.toString() ?? '') ?? 0;
      if (round > maxRound) maxRound = round;
    }

    final fromSum = (paymentSum / (roundAmount * slotCount)).floor();
    return fromSum > maxRound ? fromSum : maxRound;
  }

  /// Newest join first. Falls back to equb [createdAt] when join time is unknown.
  static void sortByLatestJoined(List<PendingEqub> equbs) {
    equbs.sort((a, b) {
      final aDate = a.userJoinedAt ?? a.createdAt;
      final bDate = b.userJoinedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
  }

  factory PendingEqub.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    return PendingEqub(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nextRoundLotteryType: json['nextRoundLotteryType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      equbTypeId: json['equbTypeId']?.toString() ?? '',
      equbCategoryId: json['equbCategoryId']?.toString() ?? '',
      numberOfEqubers: (json['numberOfEqubers'] as num?)?.toInt() ?? 0,
      equbAmount: (json['equbAmount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
      userId: json['userId']?.toString(),
      staffId: json['staffId']?.toString() ?? '',
      currentRound: (json['currentRound'] as num?)?.toInt() ?? 0,
      nextRound: (json['nextRound'] as num?)?.toInt() ?? 0,
      groupLimit: (json['groupLimit'] as num?)?.toInt() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.parse(json['startDate'].toString()),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      ethiopianStartDate: json['ethiopianStartDate']?.toString(),
      ethiopianEndDate: json['ethiopianEndDate']?.toString(),
      nextRoundDate: json['nextRoundDate']?.toString(),
      nextRoundTime: json['nextRoundTime']?.toString(),
      state: json['state']?.toString() ?? '',
      branchId: json['branchId']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      userJoinedAt: joinedAtFromJson(json, currentUserId),
      equbType:
          json['equbType'] != null ? EqubType.fromJson(json['equbType']) : null,
      equbCategory: json['equbCategory'] != null
          ? EqubCategoryss.fromJson(
              Map<String, dynamic>.from(json['equbCategory'] as Map),
            )
          : null,
      equbers: json['equbers'] != null
          ? List<Equber>.from(json['equbers'].map((x) => Equber.fromJson(x)))
          : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      lastPaidRound: lastPaidRoundFromJson(json),
    );
  }
}

class EqubType {
  final String id;
  final String name;
  final int? interval;

  EqubType({
    required this.id,
    required this.name,
    this.interval,
  });

  factory EqubType.fromJson(Map<String, dynamic> json) {
    return EqubType(
      id: json['id'],
      name: json['name'],
      interval: json['interval'] as int?,
    );
  }
}

class EqubCategoryss {
  final String id;
  final String name;
  final bool needsRequest;
  bool isSaving;

  EqubCategoryss(
      {required this.id,
      required this.name,
      required this.needsRequest,
      required this.isSaving});

  factory EqubCategoryss.fromJson(Map<String, dynamic> json) {
    return EqubCategoryss(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        needsRequest: json['needsRequest'] == true,
        isSaving: json['isSaving'] == true);
  }
}

class Equber {
  final String id;

  Equber({required this.id});

  factory Equber.fromJson(Map<String, dynamic> json) {
    return Equber(
      id: json['id'],
    );
  }
}

class Branch {
  final String id;
  final String name;

  Branch({required this.id, required this.name});

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'],
      name: json['name'],
    );
  }
}

class EqubCache {
  static final Map<String, List<PendingEqub>> _cache = {};

  static List<PendingEqub>? get(String key) => _cache[key];
  static void set(String key, List<PendingEqub> value) {
    _cache[key] = value;
  }
}
