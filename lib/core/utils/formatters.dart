import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  static String currency(double amount) => _currencyFormat.format(amount);

  static String date(DateTime date) => DateFormat('dd MMM yyyy').format(date);

  static String dateShort(DateTime date) => DateFormat('dd MMM').format(date);

  static String monthYear(DateTime date) =>
      DateFormat('MMMM yyyy').format(date);

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return Formatters.date(date);
  }
}
