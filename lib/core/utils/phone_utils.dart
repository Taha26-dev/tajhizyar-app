import 'package:tajhizyar/core/utils/formatters.dart';

/// تبدیل شماره موبایل به قالب بین‌المللی موردنیاز لینک واتساپ (`wa.me`).
///
/// واتساپ شماره را فقط در قالب بین‌المللی بدون «+» می‌پذیرد؛ این تابع
/// قالب‌های رایج ایران را پوشش می‌دهد:
///
/// - «09121234567»     → «989121234567»
/// - «+98 912 123 4567» → «989121234567»
/// - «00989121234567»  → «989121234567»
/// - «9121234567»      → «989121234567»
///
/// در صورت خالی بودن یا نبود رقم، null برمی‌گرداند.
String? normalizeWhatsappNumber(String? raw) {
  if (raw == null) return null;

  // ارقام فارسی/عربی → لاتین و حذف همه کاراکترهای غیر عددی (فاصله، - و ...)
  String digits = normalizeDigits(raw).replaceAll(RegExp(r'[^0-9+]'), '');

  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('0')) digits = '98${digits.substring(1)}';
  // شماره بدون کد کشور ولی کامل (۱۰ رقم، مثل 9121234567)
  if (!digits.startsWith('98') && digits.length == 10) {
    digits = '98$digits';
  }

  return digits.isEmpty ? null : digits;
}
