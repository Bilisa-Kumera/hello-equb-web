import 'package:flutter/material.dart';
import 'package:helloequb/utils/app_localizations.dart';
import 'package:helloequb/utils/colors_constant.dart';
import 'package:helloequb/utils/lang_constants.dart';

enum EqubTypeKind { all, daily, weekly, monthly, other }

/// Known API / DB labels (English seed values and Amharic production names).
const _allNames = {'all', 'ሁሉም'};
const _dailyNames = {'daily', 'በየቀኑ', 'ዕለታዊ'};
const _weeklyNames = {'weekly', 'ሳምንታዊ'};
const _monthlyNames = {'monthly', 'ወርሃዊ'};

bool _nameIn(Set<String> aliases, String trimmed, String lower) =>
    aliases.contains(trimmed) || aliases.contains(lower);

/// Resolve equb type from [interval] (preferred) or [name] from the API.
EqubTypeKind resolveEqubTypeKind({String? name, int? interval}) {
  switch (interval) {
    case 1:
      return EqubTypeKind.daily;
    case 7:
      return EqubTypeKind.weekly;
    case 30:
      return EqubTypeKind.monthly;
  }

  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return EqubTypeKind.other;

  final lower = trimmed.toLowerCase();
  if (_nameIn(_allNames, trimmed, lower)) return EqubTypeKind.all;
  if (_nameIn(_dailyNames, trimmed, lower)) return EqubTypeKind.daily;
  if (_nameIn(_weeklyNames, trimmed, lower)) return EqubTypeKind.weekly;
  if (_nameIn(_monthlyNames, trimmed, lower)) return EqubTypeKind.monthly;

  return EqubTypeKind.other;
}

/// Localized tab label. [name] stays as returned by the API for filtering/logic.
String translateEqubTypeName(
  BuildContext context,
  String? name, {
  int? interval,
}) {
  switch (resolveEqubTypeKind(name: name, interval: interval)) {
    case EqubTypeKind.all:
      return AppKeys.all.tr(context);
    case EqubTypeKind.daily:
      return AppKeys.daily.tr(context);
    case EqubTypeKind.weekly:
      return AppKeys.weekly.tr(context);
    case EqubTypeKind.monthly:
      return AppKeys.monthly.tr(context);
    case EqubTypeKind.other:
      return name?.trim() ?? '';
  }
}

Color equbTypeColor({String? name, int? interval}) {
  switch (resolveEqubTypeKind(name: name, interval: interval)) {
    case EqubTypeKind.all:
      return AppColors.lightGray.withOpacity(0.4);
    case EqubTypeKind.daily:
      return AppColors.blue.withOpacity(0.22);
    case EqubTypeKind.weekly:
      return AppColors.orange.withOpacity(0.22);
    case EqubTypeKind.monthly:
      return AppColors.green.withOpacity(0.22);
    case EqubTypeKind.other:
      final lower = name?.trim().toLowerCase() ?? '';
      if (lower == 'car equb') {
        return AppColors.purple.withOpacity(0.15);
      }
      if (lower == 'house equb') {
        return AppColors.teal.withOpacity(0.15);
      }
      return AppColors.primary.withOpacity(0.13);
  }
}
