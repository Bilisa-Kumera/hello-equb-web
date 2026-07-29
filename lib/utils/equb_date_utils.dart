/// Helpers for deriving equb schedule dates from type interval and rounds.
///
/// Backend intervals: Daily = 1, Weekly = 7, Monthly = 30 (days between rounds).
/// End date = start date + (numberOfRounds - 1) * interval days.
int resolveEqubIntervalDays({
  int? interval,
  String? typeName,
}) {
  if (interval != null && interval > 0) {
    return interval;
  }

  final normalized = (typeName ?? '').trim().toLowerCase();
  if (normalized.contains('daily') || normalized == 'daily') {
    return 1;
  }
  if (normalized.contains('weekly') || normalized == 'weekly') {
    return 7;
  }
  if (normalized.contains('monthly') || normalized == 'monthly') {
    return 30;
  }

  return 1;
}

DateTime? calculateEqubEndDate({
  required DateTime startDate,
  required int numberOfRounds,
  int? intervalDays,
  String? typeName,
}) {
  if (numberOfRounds <= 0) return null;

  final interval = resolveEqubIntervalDays(
    interval: intervalDays,
    typeName: typeName,
  );
  final daysAfterStart = (numberOfRounds - 1) * interval;
  return startDate.toLocal().add(Duration(days: daysAfterStart));
}

/// Ethiopian calendar epoch (1 መስከረም 1 = JDN 1724221).
const int _ethiopianEpoch = 1724221;

const List<String> ethiopianMonthNamesAmharic = [
  "መስከረም",
  "ጥቅምት",
  "ኅዳር",
  "ታኅሣሥ",
  "ጥር",
  "የካቲት",
  "መጋቢት",
  "ሚያዝያ",
  "ግንቦት",
  "ሰኔ",
  "ሐምሌ",
  "ነሐሴ",
  "ጳጉሜን",
];

class EthiopianDateParts {
  final int year;
  final int month;
  final int day;

  const EthiopianDateParts({
    required this.year,
    required this.month,
    required this.day,
  });
}

int _gregorianToJulianDayNumber(int year, int month, int day) {
  final a = ((14 - month) / 12).floor();
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  return day +
      ((153 * m + 2) / 5).floor() +
      365 * y +
      (y / 4).floor() -
      (y / 100).floor() +
      (y / 400).floor() -
      32045;
}

/// Converts a Gregorian [date] to Ethiopian year/month/day.
EthiopianDateParts gregorianToEthiopian(DateTime date) {
  final local = date.toLocal();
  final jdn =
      _gregorianToJulianDayNumber(local.year, local.month, local.day);
  final r = (jdn - _ethiopianEpoch) % 1461;
  final n = (r % 365) + 365 * (r / 1461).floor();
  final year =
      4 * ((jdn - _ethiopianEpoch) / 1461).floor() + (r / 365).floor() + 1;
  final month = (n / 30).floor() + 1;
  final day = (n % 30) + 1;
  return EthiopianDateParts(year: year, month: month, day: day);
}

/// Formats an Ethiopian date string like `2017-09-15` using Amharic months.
String formatEthiopianDateString(String? dateStr) {
  if (dateStr == null || dateStr.trim().isEmpty) return '-';
  try {
    final dateOnly = dateStr.split(' ').first;
    final parts = dateOnly.split(RegExp(r'[-/]'));
    if (parts.length < 3) return dateStr;

    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    final monthName = (month >= 1 && month <= 13)
        ? ethiopianMonthNamesAmharic[month - 1]
        : parts[1];
    return '$monthName $day, $year';
  } catch (_) {
    return dateStr;
  }
}

/// Formats a Gregorian date as Ethiopian display text.
String formatGregorianAsEthiopian(DateTime? date) {
  if (date == null) return '-';
  final eth = gregorianToEthiopian(date);
  final monthName = (eth.month >= 1 && eth.month <= 13)
      ? ethiopianMonthNamesAmharic[eth.month - 1]
      : eth.month.toString();
  return '$monthName ${eth.day}, ${eth.year}';
}

/// Builds `Ethiopian (Gregorian)` when both sides are available.
/// If [ethiopianDate] is missing, converts from the Gregorian date.
String combineEthiopianGregorianDisplay({
  String? ethiopianDate,
  DateTime? gregorianDate,
  String? gregorianDateStr,
  required String Function(DateTime?) formatGregorian,
}) {
  final parts = resolveEthiopianGregorianParts(
    ethiopianDate: ethiopianDate,
    gregorianDate: gregorianDate,
    gregorianDateStr: gregorianDateStr,
    formatGregorian: formatGregorian,
  );
  if (parts.ethiopian == '-' && parts.gregorian == '-') return '-';
  if (parts.ethiopian == '-') return parts.gregorian;
  if (parts.gregorian == '-') return parts.ethiopian;
  return '${parts.ethiopian} (${parts.gregorian})';
}

class EthiopianGregorianParts {
  final String ethiopian;
  final String gregorian;

  const EthiopianGregorianParts({
    required this.ethiopian,
    required this.gregorian,
  });
}

/// Resolves Ethiopian + Gregorian display parts for space-between rows.
EthiopianGregorianParts resolveEthiopianGregorianParts({
  String? ethiopianDate,
  DateTime? gregorianDate,
  String? gregorianDateStr,
  required String Function(DateTime?) formatGregorian,
}) {
  DateTime? resolvedGregorian = gregorianDate;
  if (resolvedGregorian == null &&
      gregorianDateStr != null &&
      gregorianDateStr.isNotEmpty) {
    try {
      resolvedGregorian = DateTime.parse(gregorianDateStr).toLocal();
    } catch (_) {}
  }

  var ethiopian = formatEthiopianDateString(ethiopianDate);
  if (ethiopian == '-' && resolvedGregorian != null) {
    ethiopian = formatGregorianAsEthiopian(resolvedGregorian);
  }

  return EthiopianGregorianParts(
    ethiopian: ethiopian,
    gregorian: formatGregorian(resolvedGregorian),
  );
}
