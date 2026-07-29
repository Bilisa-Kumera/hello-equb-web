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
  });

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
      id: json['id'],
      name: json['name'],
      nextRoundLotteryType: json['nextRoundLotteryType'] ?? '',
      description: json['description'] ?? '',
      equbTypeId: json['equbTypeId'],
      equbCategoryId: json['equbCategoryId'],
      numberOfEqubers: json['numberOfEqubers'],
      equbAmount: json['equbAmount'],
      status: json['status'],
      userId: json['userId'],
      staffId: json['staffId'],
      currentRound: json['currentRound'],
      nextRound: json['nextRound'],
      groupLimit: json['groupLimit'],
      serviceCharge: (json['serviceCharge'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      ethiopianStartDate: json['ethiopianStartDate'] as String?,
      ethiopianEndDate: json['ethiopianEndDate'] as String?,
      nextRoundDate: json['nextRoundDate'],
      nextRoundTime: json['nextRoundTime'],
      state: json['state'],
      branchId: json['branchId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      userJoinedAt: joinedAtFromJson(json, currentUserId),
      equbType:
          json['equbType'] != null ? EqubType.fromJson(json['equbType']) : null,
      equbCategory: json['equbCategory'] != null
          ? EqubCategoryss.fromJson(json['equbCategory'])
          : null,
      equbers: json['equbers'] != null
          ? List<Equber>.from(json['equbers'].map((x) => Equber.fromJson(x)))
          : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
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
        id: json['id'],
        name: json['name'],
        needsRequest: json['needsRequest'],
        isSaving: json['isSaving'] ?? false);
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
