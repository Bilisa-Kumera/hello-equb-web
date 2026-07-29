import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

// Primary Colors
const Color primaryPink = Color(0xFFFF69B4); // Hot Pink
const Color secondaryPink = Color(0xFFFFB6C1); // Light Pink
const Color accentPink = Color(0xFFFF1493); // Deep Pink
const Color softPink = Color(0xFFFFC0CB); // Pink
const Color bgColor = Colors.white;

  // Background Colors
   const Color darkBgColor = Color(0xFF1A1A1A);

  // Text Colors
   const Color textPrimary = Color(0xFF2C2C2C);
   const Color textSecondary = Color(0xFF6B6B6B);
   const Color textLight = Color(0xFF9E9E9E);

  // Status Colors
   const Color success = Color(0xFF4CAF50);
   const Color error = Color(0xFFE57373);
   const Color warning = Color(0xFFFFB74D);
   const Color info = Color(0xFF64B5F6);



// Gradient Colors
const LinearGradient pinkGradient = LinearGradient(
  colors: [primaryPink, accentPink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient softPinkGradient = LinearGradient(
  colors: [softPink, secondaryPink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Fonts
const String pacifico = 'Pacifico';
const String dancingScript = 'DancingScript';
const String greatVibes = 'GreatVibes';
const String poppins = 'Poppins';

// Common Constants
final double kWidth = Get.width;
final double kHeight = Get.height;
const double maxSlide = 225.0;
const double dragLeftStart = maxSlide - 30;
const double dragRightStart = 60;
const Duration animationDuration = Duration(milliseconds: 500);
final DateFormat dayFormatter = DateFormat('yyyy-MM-dd');

// Light Mode Colors
const MaterialColor lightModeColor = MaterialColor(0xFFFF69B4, {
  50: Color.fromRGBO(255, 105, 180, .1),
  100: Color.fromRGBO(255, 105, 180, .2),
  200: Color.fromRGBO(255, 105, 180, .3),
  300: Color.fromRGBO(255, 105, 180, .4),
  400: Color.fromRGBO(255, 105, 180, .5),
  500: Color.fromRGBO(255, 105, 180, .6),
  600: Color.fromRGBO(255, 105, 180, .7),
  700: Color.fromRGBO(255, 105, 180, .8),
  800: Color.fromRGBO(255, 105, 180, .9),
  900: Color.fromRGBO(255, 105, 180, 1),
});

// Text Styles - Pacifico
final TextStyle pacifico40 = TextStyle(
  fontFamily: pacifico,
  fontSize: 40.sp,
  color: Colors.black,
);

final TextStyle pacifico32 = TextStyle(
  fontFamily: pacifico,
  fontSize: 32.sp,
  color: Colors.black,
);

final TextStyle pacifico24 = TextStyle(
  fontFamily: pacifico,
  fontSize: 24.sp,
  color: Colors.black,
);


final TextStyle pacifico20 = TextStyle(
  fontFamily: pacifico,
  fontSize: 20.sp,
  color: Colors.black,
);

final TextStyle pacifico18 = TextStyle(
  fontFamily: pacifico,
  fontSize: 18.sp,
  color: Colors.black,
);

// Text Styles - Dancing Script
final TextStyle dancingScript40 = TextStyle(
  fontFamily: dancingScript,
  fontSize: 40.sp,
  color: Colors.black,
);

final TextStyle dancingScript32 = TextStyle(
  fontFamily: dancingScript,
  fontSize: 32.sp,
  color: Colors.black,
);

final TextStyle dancingScript24 = TextStyle(
  fontFamily: dancingScript,
  fontSize: 24.sp,
  color: Colors.black,
);

// Text Styles - Great Vibes
final TextStyle greatVibes40 = TextStyle(
  fontFamily: greatVibes,
  fontSize: 40.sp,
  color: Colors.black,
);

final TextStyle greatVibes32 = TextStyle(
  fontFamily: greatVibes,
  fontSize: 32.sp,
  color: Colors.black,
);

final TextStyle greatVibes24 = TextStyle(
  fontFamily: greatVibes,
  fontSize: 24.sp,
  color: Colors.black,
);

// Text Styles - Poppins (for body text)
final TextStyle poppins40010 = TextStyle(
  fontFamily: poppins,
  fontWeight: FontWeight.w400,
  fontSize: 10.sp,
  color: Colors.black,
);

final TextStyle poppins40012 = TextStyle(
  fontFamily: poppins,
  fontWeight: FontWeight.w400,
  fontSize: 12.sp,
  color: Colors.black,
);

final TextStyle poppins40014 = TextStyle(
  fontFamily: poppins,
  fontWeight: FontWeight.w400,
  fontSize: 14.sp,
  color: Colors.black,
);

// final TextStyle poppins40015 = TextStyle(
//     fontFamily: poppins, fontWeight: FontWeight.w400, fontSize: 15.sp, color: Colors.black);
// final TextStyle poppins40020 = TextStyle(
//     fontFamily: poppins, fontWeight: FontWeight.w400, fontSize: 20.sp, color: Colors.black);
// final TextStyle poppins40040 = TextStyle(
//     fontFamily: poppins, fontWeight: FontWeight.w400, fontSize: 40.sp, color: Colors.black);

//500
final TextStyle poppins50010 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w500, fontSize: 10.sp, color: Colors.black);
final TextStyle poppins50012 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w500, fontSize: 12.sp, color: Colors.black);
final TextStyle poppins50014 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w500, fontSize: 14.sp, color: Colors.black);
final TextStyle poppins50015 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w500, fontSize: 15.sp, color: Colors.black);
final TextStyle poppins50016 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w500, fontSize: 16.sp, color: Colors.black);
final TextStyle poppins50020 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w500, fontSize: 20.sp, color: Colors.black);
final TextStyle poppins50040 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w500, fontSize: 40.sp, color: Colors.black);

//600
final TextStyle poppins60012 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 12.sp, color: Colors.black);
final TextStyle poppins60014 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 14.sp, color: Colors.black);
final TextStyle poppins60016 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 16.sp, color: Colors.black);
final TextStyle poppins60018 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 18.sp, color: Colors.black);
final TextStyle poppins60020 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 20.sp, color: Colors.black);
final TextStyle poppins60030 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 30.sp, color: Colors.black);
final TextStyle poppins60032 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 32.sp, color: Colors.black);
final TextStyle poppins600150 = TextStyle(
    fontFamily: poppins, fontWeight: FontWeight.w600, fontSize: 150.sp, color: Colors.black);


