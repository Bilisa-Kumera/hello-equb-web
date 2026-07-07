import 'package:helloequb/core/api_url.dart';

class BannerModel {
  final String id;
  final String imageUrl;
  // final String title;
  // final String? description;

  BannerModel({
    required this.id,
    required this.imageUrl,
    // required this.title,
    // this.description,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      // title: json['name'] ?? '',
      imageUrl: '${mediaUrl}images/${json['picture']}',
      // description: json['description'],
    );
  }
}
