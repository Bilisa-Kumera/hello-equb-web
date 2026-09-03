import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/models/app_promo_model.dart';
import 'package:helloequb/provider/app_promo_provider.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:url_launcher/url_launcher.dart';

class AppPromoOverlay extends StatelessWidget {
  final AppPromo promo;

  const AppPromoOverlay({
    super.key,
    required this.promo,
  });

  Future<void> _openLink(BuildContext context) async {
    final url = promo.linkUrl?.trim();
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = promo.linkUrl != null && promo.linkUrl!.trim().isNotEmpty;
    final hasTitle = promo.title != null && promo.title!.trim().isNotEmpty;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16.r)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220.h,
                    child: Image.network(
                      promo.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 220.h,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_outlined),
                            SizedBox(height: 8.h),
                            Text(
                              'Image unavailable',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasTitle || hasLink)
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasTitle)
                          Text(
                            promo.title!.trim(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (hasLink) ...[
                          if (hasTitle) SizedBox(height: 12.h),
                          TextButton(
                            onPressed: () => _openLink(context),
                            child: const Text('Learn more'),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            top: -10.h,
            right: -10.w,
            child: Material(
              color: AppColors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: Padding(
                  padding: EdgeInsets.all(6.r),
                  child: Icon(Icons.close, size: 22.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAppPromoIfNeeded(
  BuildContext context,
  AppPromoProvider provider,
) async {
  final promo = await provider.fetchActivePromo();
  if (!context.mounted || promo == null) return;
  if (!provider.shouldShowPromo(promo)) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AppPromoOverlay(promo: promo),
  );

  provider.dismissPromo(promo.id);
}
