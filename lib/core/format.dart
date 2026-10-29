import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String rupees(num v) => _inr.format(v);

/// ₹12.4 L / ₹1.25 Cr style for big numbers.
String rupeesCompact(num v) {
  if (v.abs() >= 1e7) return '₹${(v / 1e7).toStringAsFixed(2)} Cr';
  if (v.abs() >= 1e5) return '₹${(v / 1e5).toStringAsFixed(2)} L';
  return rupees(v);
}

String pct(double? v, {int digits = 1, bool sign = true}) {
  if (v == null) return '—';
  final s = v.toStringAsFixed(digits);
  return sign && v > 0 ? '+$s%' : '$s%';
}

Color changeColor(double? v, ColorScheme cs) {
  if (v == null || v == 0) return cs.onSurfaceVariant;
  return v > 0 ? Colors.green.shade600 : cs.error;
}
