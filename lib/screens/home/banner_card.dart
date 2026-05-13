import 'package:flutter/material.dart';
import 'package:ekubee/models/banner_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BannerCard extends StatelessWidget {
  final BannerModel banner;
  const BannerCard({required this.banner, Key? key}) : super(key: key);
  String _fixBannerUrl(String url) {
    // if it already has "/banner/" -> return as is
    if (url.contains('/banner/')) return url;
    // if it's in /images/ but missing banner -> inject it
    if (url.contains('/images/')) {
      return url.replaceFirst('/images/', '/images/banner/');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160.h,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image from network, fills full width and height
            Image.network(
              _fixBannerUrl(banner.imageUrl),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fitHeight,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/banner.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
