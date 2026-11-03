import 'package:tajhizyar/core/utils/formatters.dart';

/// ابزارهای کمکی تبدیل امن مقادیر JSON.
///
/// API ممکن است اعداد را به‌صورت رشته («2450000») یا عدد برگرداند و
/// متن‌ها ممکن است خالی یا null باشند؛ این توابع همه حالات را پوشش می‌دهند.
int jsonToInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final String cleaned = normalizeDigits(value).trim();
    // ۱) عدد صحیح ساده
    final int? asInt = int.tryParse(cleaned);
    if (asInt != null) return asInt;
    // ۲) عدد اعشاری («2450000.0»)
    final double? asDouble = double.tryParse(cleaned);
    if (asDouble != null) return asDouble.toInt();
    // ۳) رشته با جداکننده («2,450,000 تومان»)
    final String digitsOnly = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isNotEmpty) return int.tryParse(digitsOnly) ?? fallback;
  }
  return fallback;
}

/// تبدیل امن مقدار JSON به رشته غیرخالی.
String jsonString(Object? value, [String fallback = '']) {
  if (value == null) return fallback;
  final String result = value.toString().trim();
  return result.isEmpty ? fallback : result;
}

/// تبدیل امن مقدار JSON به رشته اختیاری (خالی/null → null).
String? jsonStringOrNull(Object? value) {
  final String result = value?.toString().trim() ?? '';
  return result.isEmpty ? null : result;
}

/// تبدیل امن مقدار JSON به bool.
///
/// سرور مقادیر بولی را به شکل‌های مختلف («1»، «true»، 1، true) می‌فرستد؛
/// همه حالات پوشش داده می‌شود. مقدار ناشناخته → [fallback].
bool jsonToBool(Object? value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final String v = normalizeDigits(value).trim().toLowerCase();
    if (v == '1' || v == 'true' || v == 'yes') return true;
    if (v == '0' || v == 'false' || v == 'no') return false;
  }
  return fallback;
}

/// استخراج فهرست از پاسخ JSON که ممکن است
/// مستقیم یک آرایه باشد یا داخل کلیدهایی مثل `data` / `items` قرار گرفته باشد.
List<dynamic> jsonExtractList(Object? decoded, List<String> keys) {
  if (decoded is List) return decoded;
  if (decoded is Map<String, dynamic>) {
    for (final String key in keys) {
      final Object? value = decoded[key];
      if (value is List) return value;
    }
    // حالت تودرتو: {"data": {"data": [...]}}
    final Object? nested = decoded['data'];
    if (nested is Map<String, dynamic>) {
      for (final String key in keys) {
        final Object? value = nested[key];
        if (value is List) return value;
      }
    }
  }
  return const <dynamic>[];
}
