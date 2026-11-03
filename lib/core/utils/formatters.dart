/// ابزارهای قالب‌بندی اعداد و قیمت برای رابط کاربری فارسی.
const Map<String, String> _persianDigits = <String, String>{
  '0': '۰',
  '1': '۱',
  '2': '۲',
  '3': '۳',
  '4': '۴',
  '5': '۵',
  '6': '۶',
  '7': '۷',
  '8': '۸',
  '9': '۹',
};

/// ارقام لاتین متن ورودی را به ارقام فارسی تبدیل می‌کند.
///
/// مثال: `toPersianDigits('1403/02/24')` → «۱۴۰۳/۰۲/۲۴»
String toPersianDigits(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final String char in input.split('')) {
    buffer.write(_persianDigits[char] ?? char);
  }
  return buffer.toString();
}

/// مبلغ (تومان) را با جداکننده هزارگان و ارقام فارسی قالب‌بندی می‌کند.
///
/// مثال: `formatToman(4850000)` → «۴,۸۵۰,۰۰۰ تومان»
String formatToman(int amount) {
  final String grouped = amount
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match m) => ',');
  return '${toPersianDigits(grouped)} تومان';
}

/// نگاشت ارقام فارسی و عربی به لاتین (برای parse اعداد دریافتی از API)
const Map<String, String> _latinDigitMap = <String, String>{
  '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
  '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
  '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
};

/// ارقام فارسی/عربی متن ورودی را به ارقام لاتین تبدیل می‌کند.
///
/// مثال: `normalizeDigits('۲,۴۵۰,۰۰۰')` → «2,450,000»
String normalizeDigits(String input) {
  final StringBuffer buffer = StringBuffer();
  for (final String char in input.split('')) {
    buffer.write(_latinDigitMap[char] ?? char);
  }
  return buffer.toString();
}
