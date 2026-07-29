import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:helloequb/utils/colors_constant.dart';

/// Font family names used across the app.
abstract class AppFonts {
  static const String poppins = 'Poppins';
}

/// Central text style definitions.
///
/// Use semantic getters (e.g. [bodyMedium], [screenTitle]) where they fit.
/// Use weight + size getters (e.g. [poppins60014]) for specific cases.
/// Apply colors with `.copyWith(color: ...)`.
abstract class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required String family,
    required FontWeight weight,
    required double size,
    Color color = Colors.black,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: family,
      fontWeight: weight,
      fontSize: size.sp,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  // ---------------------------------------------------------------------------
  // Poppins — weight 400
  // ---------------------------------------------------------------------------
  static TextStyle get poppins4008 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 8);
  static TextStyle get poppins40010 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 10);
  static TextStyle get poppins40011 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 11);
  static TextStyle get poppins40012 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 12);
  static TextStyle get poppins40013 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 13);
  static TextStyle get poppins40014 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 14);
  static TextStyle get poppins40015 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 15);
  static TextStyle get poppins40016 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 16);
  static TextStyle get poppins40018 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 18);
  static TextStyle get poppins40020 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 20);
  static TextStyle get poppins40022 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 22);
  static TextStyle get poppins40024 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 24);
  static TextStyle get poppins40028 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w400, size: 28);

  // ---------------------------------------------------------------------------
  // Poppins — weight 500
  // ---------------------------------------------------------------------------
  static TextStyle get poppins5008 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 8);
  static TextStyle get poppins50010 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 10);
  static TextStyle get poppins50011 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 11);
  static TextStyle get poppins50012 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 12);
  static TextStyle get poppins50013 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 13);
  static TextStyle get poppins50014 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 14);
  static TextStyle get poppins50015 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 15);
  static TextStyle get poppins50016 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 16);
  static TextStyle get poppins50018 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 18);
  static TextStyle get poppins50020 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 20);
  static TextStyle get poppins50022 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 22);
  static TextStyle get poppins50024 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 24);
  static TextStyle get poppins50028 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 28);
  static TextStyle get poppins50040 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w500, size: 40);

  // ---------------------------------------------------------------------------
  // Poppins — weight 600
  // ---------------------------------------------------------------------------
  static TextStyle get poppins60010 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 10);
  static TextStyle get poppins60011 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 11);
  static TextStyle get poppins60012 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 12);
  static TextStyle get poppins60013 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 13);
  static TextStyle get poppins60014 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 14);
  static TextStyle get poppins60015 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 15);
  static TextStyle get poppins60016 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 16);
  static TextStyle get poppins60017 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 17);
  static TextStyle get poppins60018 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 18);
  static TextStyle get poppins60020 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 20);
  static TextStyle get poppins60022 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 22);
  static TextStyle get poppins60024 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 24);
  static TextStyle get poppins60026 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 26);
  static TextStyle get poppins60028 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 28);
  static TextStyle get poppins60030 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 30);
  static TextStyle get poppins60032 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 32);
  static TextStyle get poppins60036 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 36);
  static TextStyle get poppins600150 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w600, size: 150);

  // ---------------------------------------------------------------------------
  // Poppins — weight 700
  // ---------------------------------------------------------------------------
  static TextStyle get poppins70014 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 14);
  static TextStyle get poppins70015 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 15);
  static TextStyle get poppins70016 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 16);
  static TextStyle get poppins70017 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 17);
  static TextStyle get poppins70018 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 18);
  static TextStyle get poppins70020 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 20);
  static TextStyle get poppins70022 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 22);
  static TextStyle get poppins70024 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 24);
  static TextStyle get poppins70028 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 28);
  static TextStyle get poppins70032 =>
      _base(family: AppFonts.poppins, weight: FontWeight.w700, size: 32);

  // ---------------------------------------------------------------------------
  // Semantic roles — prefer these for new code
  // ---------------------------------------------------------------------------
  static TextStyle get navLabel => poppins4008;
  static TextStyle get appBarTitle => poppins70032;
  static TextStyle get appBarSubtitle => poppins40016;
  static TextStyle get screenTitle => poppins60024;
  static TextStyle get screenTitleLarge => poppins60028;
  static TextStyle get screenTitleHero => poppins60032;
  static TextStyle get sectionTitle => poppins60018;
  static TextStyle get sectionTitleLarge => poppins60020;
  static TextStyle get cardTitle => poppins60015;
  static TextStyle get cardTitleBold => poppins70017;
  static TextStyle get cardSubtitle => poppins40013;
  static TextStyle get bodyLarge => poppins40016;
  static TextStyle get bodyMedium => poppins40014;
  static TextStyle get bodySmall => poppins40013;
  static TextStyle get labelMedium => poppins50014;
  static TextStyle get labelSmall => poppins50012;
  static TextStyle get caption => poppins40012;
  static TextStyle get captionSmall => poppins40010;
  static TextStyle get captionMuted => poppins40011;
  static TextStyle get badge => poppins60010;
  static TextStyle get chip => poppins50013;
  static TextStyle get chipSelected => poppins60013;
  static TextStyle get button => poppins60012;
  static TextStyle get buttonMedium => poppins60014;
  static TextStyle get buttonLarge => poppins60016;
  static TextStyle get input => poppins40014;
  static TextStyle get inputLabel => poppins50014;
  static TextStyle get link => poppins50014;
  static TextStyle get error => poppins40012;
  static TextStyle get hint => poppins40013.copyWith(color: Colors.grey);
  static TextStyle get hintMuted => poppins40012.copyWith(color: Colors.black38);
  static TextStyle get subtitleMuted =>
      poppins40013.copyWith(color: Colors.black54);
  static TextStyle get onPrimary => poppins60012.copyWith(color: Colors.white);
  static TextStyle get onPrimaryMedium =>
      poppins60014.copyWith(color: Colors.white);
  static TextStyle get onPrimaryBold =>
      poppins60016.copyWith(color: Colors.white);
  static TextStyle get primaryLabel => poppins60014.copyWith(color: AppColors.primary);
  static TextStyle get primaryBody => poppins40014.copyWith(color: AppColors.primary);
  static TextStyle get primaryTitle => poppins60015.copyWith(color: AppColors.primary);
  static TextStyle get greyBody => poppins40014.copyWith(color: Colors.grey);
  static TextStyle get greyBodySmall =>
      poppins40013.copyWith(color: Colors.grey);
  static TextStyle get greyLabel =>
      poppins40014.copyWith(color: Colors.grey.shade600);
  static TextStyle get greyCaption =>
      poppins40012.copyWith(color: Colors.grey);
  static TextStyle get amountLarge => poppins60032;
  static TextStyle get amountHero => poppins60036;
  static TextStyle get displayHuge => poppins600150;
  static TextStyle get dialogTitle => poppins60022;
  static TextStyle get dialogBody => poppins40014;
  static TextStyle get listTitle => poppins60016;
  static TextStyle get listSubtitle => poppins40014;
  static TextStyle get tabLabel => poppins50013;
  static TextStyle get tabLabelSelected => poppins60013;
  static TextStyle get statusBadge => poppins60010;
  static TextStyle get detailButton => poppins60012;
  static TextStyle get splashTitle => poppins60026;
}
