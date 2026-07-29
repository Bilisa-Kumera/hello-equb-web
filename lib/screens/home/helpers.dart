import 'package:flutter/material.dart';
import '../../utils/colors_constant.dart';
import '../../utils/equb_type_localization.dart';

Color getEqubTypeColor(String? name, {int? interval}) =>
    equbTypeColor(name: name, interval: interval);

String getEqubIcon(String? name) {
  switch (name) {
    case "Car Equb":
      return "assets/care.png";
    case "House Equb":
      return "assets/home.png";
    default:
      return "assets/equb.png";
  }
}
