/// Formatting helpers for money and dates.
///
/// Money is stored as an integer number of paise (1 rupee = 100 paise) so that
/// arithmetic never accumulates floating point error. All display formatting
/// happens here so the rest of the app never manipulates raw doubles.
library;

const List<String> _monthShort = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> _monthLong = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _weekdayLong = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Groups digits using the Indian numbering system: 12,34,56,789.
String _groupIndian(int value) {
  final String digits = value.toString();
  if (digits.length <= 3) return digits;
  final String last3 = digits.substring(digits.length - 3);
  String rest = digits.substring(0, digits.length - 3);
  final List<String> groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${groups.join(',')},$last3';
}

/// Formats an amount in paise as e.g. `₹1,23,456.78`.
String formatCurrency(
  int minorUnits, {
  bool withSymbol = true,
  bool decimals = true,
}) {
  final bool negative = minorUnits < 0;
  final int abs = minorUnits.abs();
  final int rupees = abs ~/ 100;
  final int paise = abs % 100;
  final String body = decimals
      ? '${_groupIndian(rupees)}.${paise.toString().padLeft(2, '0')}'
      : _groupIndian(rupees);
  final String symbol = withSymbol ? '₹' : '';
  return '${negative ? '-' : ''}$symbol$body';
}

/// Short form for tight spaces, e.g. `₹2.5k`, `₹1.5L`, `₹1.20Cr`.
String formatCurrencyCompact(int minorUnits) {
  final String sign = minorUnits < 0 ? '-' : '';
  final double rupees = minorUnits.abs() / 100;
  if (rupees >= 10000000) {
    return '$sign₹${(rupees / 10000000).toStringAsFixed(2)}Cr';
  }
  if (rupees >= 100000) {
    return '$sign₹${(rupees / 100000).toStringAsFixed(1)}L';
  }
  if (rupees >= 1000) {
    return '$sign₹${(rupees / 1000).toStringAsFixed(1)}k';
  }
  return formatCurrency(minorUnits, decimals: false);
}

/// `3 Nov 2026`
String formatDateShort(DateTime date) =>
    '${date.day} ${_monthShort[date.month - 1]} ${date.year}';

/// `Tuesday, 3 November 2026`
String formatDateFull(DateTime date) =>
    '${_weekdayLong[date.weekday - 1]}, ${date.day} ${_monthLong[date.month - 1]} ${date.year}';

/// `10:30 AM`
String formatTime(DateTime date) {
  final int hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final String minute = date.minute.toString().padLeft(2, '0');
  return '$hour12:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
}

/// `November 2026`
String formatMonthYear(DateTime date) =>
    '${_monthLong[date.month - 1]} ${date.year}';

/// `Today`, `Yesterday` or `3 Nov 2026` - used for list section headers.
String formatDayHeader(DateTime date, DateTime now) {
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(date.year, date.month, date.day);
  final int diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return formatDateShort(date);
}

/// Greeting based on the hour of day.
String greetingFor(DateTime now) {
  if (now.hour < 5) return 'Good night';
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  if (now.hour < 21) return 'Good evening';
  return 'Good night';
}

/// Parses user input into paise. Returns `null` for anything that is not a
/// strictly positive, finite amount.
///
/// Accepts `1234.50`, `1,234.50` and `1234,50` (comma as decimal separator).
int? parseAmountToMinor(String input) {
  String cleaned = input.trim().replaceAll(RegExp(r'[₹\s_]'), '');
  if (cleaned.isEmpty) return null;

  final bool hasDot = cleaned.contains('.');
  final bool hasComma = cleaned.contains(',');
  if (hasDot && hasComma) {
    // `1,234.50` - comma is a thousands separator.
    cleaned = cleaned.replaceAll(',', '');
  } else if (!hasDot && hasComma) {
    // `1234,50` - comma is the decimal separator.
    cleaned = cleaned.replaceAll(',', '.');
  }

  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(cleaned)) return null;

  // Money has at most two decimal places; anything finer is a typo.
  final int dotIndex = cleaned.indexOf('.');
  if (dotIndex >= 0 && cleaned.length - dotIndex - 1 > 2) return null;

  final double? value = double.tryParse(cleaned);
  if (value == null || !value.isFinite || value <= 0) return null;

  final int minor = (value * 100).round();
  // Guard the upper bound so the UI and arithmetic stay sane (₹10 crore).
  if (minor <= 0 || minor > 100000000000) return null;
  return minor;
}
