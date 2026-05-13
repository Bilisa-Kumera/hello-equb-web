import 'package:flutter/material.dart';
import '../../utils/colors_constant.dart';

Color getEqubTypeColor(String? name) {
  if (name == null) return AppColors.lightGray.withOpacity(0.4);
  switch (name.toLowerCase()) {
    case 'all':
      return AppColors.lightGray.withOpacity(0.4);
    case 'daily':
      return AppColors.blue.withOpacity(0.22);
    case 'weekly':
      return AppColors.orange.withOpacity(0.22);
    case 'monthly':
      return AppColors.green.withOpacity(0.22);
    case 'car equb':
      return AppColors.purple.withOpacity(0.15);
    case 'house equb':
      return AppColors.teal.withOpacity(0.15);
    default:
      return AppColors.primary.withOpacity(0.13);
  }
}

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
