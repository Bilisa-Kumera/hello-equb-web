class EqubCategoryModel {
  final String status;
  final EqubCategoryData data;

  EqubCategoryModel({required this.status, required this.data});

  factory EqubCategoryModel.fromJson(Map<String, dynamic> json) {
    return EqubCategoryModel(
      status: json['status'],
      data: EqubCategoryData.fromJson(json['data']),
    );
  }
}

class EqubCategoryData {
  final List<EqubCategorys> equbCategories;
  final EqubCategoryMeta meta;

  EqubCategoryData({required this.equbCategories, required this.meta});

  factory EqubCategoryData.fromJson(Map<String, dynamic> json) {
    var categoriesList = json['equbCategorys'] as List<dynamic>;
    List<EqubCategorys> categories = categoriesList.map((categoryJson) => EqubCategorys.fromJson(categoryJson)).toList();
    return EqubCategoryData(
      equbCategories: categories,
      meta: EqubCategoryMeta.fromJson(json['meta']),
    );
  }
}
class EqubCategorys {
  final String id;
  final String name;
  final int orderId;
  final String description;
  final bool hasReason;
  final bool needsRequest;
  final String state;
  final DateTime createdAt;
  final DateTime updatedAt;

  EqubCategorys({
    required this.id,
    required this.name,
    required this.description,
    required this.orderId,
    required this.hasReason,
    required this.needsRequest,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create EqubCategory from JSON (map)
  factory EqubCategorys.fromJson(Map<String, dynamic> json) {
    return EqubCategorys(
      id: json['id'],
      name: json['name'],
      orderId: json['order']??0,
      description: json['description'],
      hasReason: json['hasReason'],
      needsRequest: json['needsRequest'],
      state: json['state'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Method to convert EqubCategory to a map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': orderId,
      'description': description,
      'hasReason': hasReason,
      'needsRequest': needsRequest,
      'state': state,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}


class EqubCategoryMeta {
  final int page;
  final int limit;
  final int total;

  EqubCategoryMeta({required this.page, required this.limit, required this.total});

  factory EqubCategoryMeta.fromJson(Map<String, dynamic> json) {
    return EqubCategoryMeta(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
    );
  }
}
