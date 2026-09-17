import 'package:flutter/foundation.dart';

/// Money, stored as a whole number of kobo.
///
/// Naira never exists as a `double` anywhere in the app: ₦1,250.50 is
/// `Kobo(125050)`. Every sum, comparison and display goes through this type, so
/// there is no floating-point drift to reason about.
@immutable
final class Kobo implements Comparable<Kobo> {
  const Kobo(this.value);

  static const zero = Kobo(0);

  /// `Kobo.fromNaira(1250, 50)` is ₦1,250.50.
  factory Kobo.fromNaira(int naira, [int kobo = 0]) => Kobo(naira * 100 + kobo);

  /// The whole number of kobo. This is what gets stored and sent.
  final int value;

  /// Whole naira part, for display only.
  int get naira => value.abs() ~/ 100;

  /// Remaining kobo part (0-99), for display only.
  int get kobo => value.abs() % 100;

  bool get isZero => value == 0;
  bool get isNegative => value < 0;

  Kobo operator +(Kobo other) => Kobo(value + other.value);
  Kobo operator -(Kobo other) => Kobo(value - other.value);
  Kobo operator *(int factor) => Kobo(value * factor);
  Kobo operator -() => Kobo(-value);

  bool operator <(Kobo other) => value < other.value;
  bool operator <=(Kobo other) => value <= other.value;
  bool operator >(Kobo other) => value > other.value;
  bool operator >=(Kobo other) => value >= other.value;

  @override
  int compareTo(Kobo other) => value.compareTo(other.value);

  /// Percentage of [total], rounded down, clamped to 0-100. Integer maths only,
  /// so a savings goal can never show 101% from a rounding error.
  int percentOf(Kobo total) {
    if (total.value <= 0) return 0;
    final percent = value * 100 ~/ total.value;
    return percent.clamp(0, 100);
  }

  /// `₦248,350.75`. Set [symbol] false for a bare `248,350.75`.
  String format({bool symbol = true}) {
    final sign = isNegative ? '-' : '';
    final koboText = kobo.toString().padLeft(2, '0');
    return '$sign${symbol ? '₦' : ''}${_group(naira)}.$koboText';
  }

  static String _group(int naira) {
    final digits = naira.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static final _digitsOnly = RegExp(r'^\d+$');

  /// Reads what a user typed — `12,500.5`, `₦12,500.50`, `1000` — into whole
  /// kobo. Returns null for anything invalid, so callers can show a field error
  /// instead of catching. Never uses `double.parse`.
  ///
  /// Rejects: empty input, letters, a negative sign, more than one decimal
  /// point, more than two decimal places, and a missing whole part ('.50').
  static Kobo? tryParse(String input) {
    final cleaned = input
        .trim()
        .replaceAll('₦', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    final parts = cleaned.split('.');
    if (parts.length > 2) return null;

    final whole = parts[0];
    final fraction = parts.length == 2 ? parts[1] : '';
    if (!_digitsOnly.hasMatch(whole)) return null;
    if (fraction.length > 2) return null;
    if (fraction.isNotEmpty && !_digitsOnly.hasMatch(fraction)) return null;

    return Kobo(int.parse(whole) * 100 + int.parse(fraction.padRight(2, '0')));
  }

  /// Like [tryParse], but throws [FormatException] instead of returning null.
  static Kobo parse(String input) {
    final parsed = tryParse(input);
    if (parsed == null) {
      throw FormatException('Not a valid amount', input);
    }
    return parsed;
  }

  @override
  bool operator ==(Object other) => other is Kobo && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => format();
}
