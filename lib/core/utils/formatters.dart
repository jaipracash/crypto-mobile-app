import 'dart:math' as math;

import 'package:intl/intl.dart';

abstract final class Formatters {
  static String currency(double? value, String currencyCode) {
    if (value == null) return '—';
    final absolute = value.abs();
    final decimals = absolute >= 1 || absolute == 0
        ? 2
        : (6 - (math.log(absolute) / math.ln10).floor() - 1)
              .clamp(2, 14)
              .toInt();
    final format = NumberFormat.currency(
      name: currencyCode.toUpperCase(),
      symbol: currencyCode.toLowerCase() == 'inr' ? '₹' : r'$',
      decimalDigits: decimals,
    );
    return format.format(value);
  }

  static String compact(double? value, {String currencyCode = 'usd'}) {
    if (value == null) return '—';
    final format = NumberFormat.compact(locale: 'en');
    final prefix = currencyCode.toLowerCase() == 'inr' ? '₹' : r'$';
    return '$prefix${format.format(value)}';
  }

  static String percent(double? value) {
    if (value == null) return '—';
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String supply(double? value) {
    if (value == null) return '∞';
    return NumberFormat.compact(locale: 'en').format(value);
  }

  static String date(DateTime? value) {
    if (value == null) return '—';
    return DateFormat('MMM d, yyyy').format(value.toLocal());
  }

  static String dateTime(DateTime value) =>
      DateFormat('MMM d, h:mm a').format(value.toLocal());
}
