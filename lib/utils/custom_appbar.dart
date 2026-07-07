import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';

class CurvedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? child;

  const CurvedAppBar({super.key, this.child});

  @override
  Size get preferredSize => const Size.fromHeight(200);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: BottomCurveClipper(),
      child: Container(
        height: preferredSize.height,
        width: double.infinity,
        color: AppColors.primary,
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 10, // adjust for safe area
              left: 6,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            // Child content (center or custom)
            if (child != null)
              Center(
                child: child,
              ),
          ],
        ),
      ),
    );
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);

    path.quadraticBezierTo(
      0,
      size.height,
      40,
      size.height,
    );

    path.lineTo(size.width - 40, size.height);

    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width,
      size.height - 40,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
