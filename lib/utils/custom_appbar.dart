import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:flutter/material.dart';

class CurvedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? child;
  final double height;

  const CurvedAppBar({super.key, this.child, this.height = 200});

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.only(top: 25.r),
      child: Center(
        child: child,
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
