import 'package:helloequb/core/api_url.dart';

String fixPromoImageUrl(String url) {
  if (url.contains('/banner/')) return url;
  if (url.contains('/images/')) {
    return url.replaceFirst('/images/', '/images/banner/');
  }
  return url;
}

class AppPromo {
  final String id;
  final String imageUrl;
  final String? title;
  final String? linkUrl;

  AppPromo({
    required this.id,
    required this.imageUrl,
    this.title,
    this.linkUrl,
  });

  factory AppPromo.fromJson(Map<String, dynamic> json) {
    final picture = json['picture']?.toString() ?? '';
    final rawUrl = '${mediaUrl}images/$picture';
    return AppPromo(
      id: json['id']?.toString() ?? '',
      imageUrl: fixPromoImageUrl(rawUrl),
      title: json['title']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
    );
  }
}
