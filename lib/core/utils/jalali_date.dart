/// تبدیل تاریخ میلادی به شمسی (جلالی) — پیاده‌سازی الگوریتم استاندارد
/// تقویم جلالی بدون نیاز به پکیج خارجی.
///
/// مرجع الگوریتم: github.com/jalaali/jalaali-js
/// صحت‌سنجی شده: ۲۰۲۴-۰۳-۲۰ میلادی → ۱۴۰۳/۰۱/۰۱ شمسی ✓
library;

import 'package:tajhizyar/core/utils/formatters.dart';

int _div(int a, int b) => a ~/ b;

int _mod(int a, int b) => a.remainder(b);

/// سال‌های مرزی الگوریتم جلالی
const List<int> _breaks = <int>[
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, //
  1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
];

/// تبدیل تاریخ میلادی به شمسی.
/// خروجی: رکورد (سال شمسی، ماه شمسی، روز شمسی)
(int, int, int) gregorianToJalali(int gy, int gm, int gd) {
  final int jdn = _g2d(gy, gm, gd);
  return _d2j(jdn);
}

/// محاسبه سال کبیسه و روز شروع فروردین برای سال شمسی داده‌شده.
/// خروجی: رکورد (کبیسه؟، سال میلادی معادل، روز ۱ فروردین در ماه مارس)
(int, int, int) _jalCal(int jy) {
  int leapJ = -14;
  int jp = _breaks[0];
  int jump = 0;

  for (int i = 1; i < _breaks.length; i++) {
    final int jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }

  int n = jy - jp;
  leapJ += _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;

  final int gy = jy + 621;
  final int leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
  final int march = 20 + leapJ - leapG;

  if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
  int leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;

  return (leap, gy, march);
}

/// تبدیل تاریخ میلادی به شماره روز ژولینی (Julian Day Number)
int _g2d(int gy, int gm, int gd) {
  int d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
      _div(153 * _mod(gm + 9, 12) + 2, 5) +
      gd -
      34840408;
  d = d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
  return d;
}

/// تبدیل شماره روز ژولینی به تاریخ میلادی
(int, int, int) _d2g(int jdn) {
  int j = 4 * jdn + 139361631;
  j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  final int i = _div(_mod(j, 1461), 4) * 5 + 308;
  final int gd = _div(_mod(i, 153), 5) + 1;
  final int gm = _mod(_div(i, 153), 12) + 1;
  final int gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
  return (gy, gm, gd);
}

/// تبدیل شماره روز ژولینی به تاریخ شمسی
(int, int, int) _d2j(int jdn) {
  int jy = _d2g(jdn).$1 - 621;
  final (int leap, int _, int march) = _jalCal(jy);
  final int jdn1f = _g2d(jy + 621, 3, march);

  int k = jdn - jdn1f;
  if (k >= 0) {
    if (k <= 185) {
      // ۶ ماه اول (۳۱ روزه)
      return (jy, 1 + _div(k, 31), _mod(k, 31) + 1);
    }
    k -= 186;
  } else {
    // سال شمسی قبل
    jy -= 1;
    k += 179;
    if (leap == 1) k += 1;
  }
  return (jy, 7 + _div(k, 30), _mod(k, 30) + 1);
}

/// تاریخ شمسی با قالب «۱۴۰۳/۰۲/۲۴» و ارقام فارسی.
String formatJalali(DateTime dateTime) {
  final (int jy, int jm, int jd) =
      gregorianToJalali(dateTime.year, dateTime.month, dateTime.day);
  final String mm = jm.toString().padLeft(2, '0');
  final String dd = jd.toString().padLeft(2, '0');
  return toPersianDigits('$jy/$mm/$dd');
}

/// تبدیل رشته تاریخ خام API (مثل «2026-10-19 11:54:59») به تاریخ شمسی.
/// در صورت نبود یا نامعتبر بودن مقدار، null برمی‌گرداند.
String? formatJalaliFromApi(String? raw) {
  if (raw == null) return null;
  final DateTime? parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return null;
  return formatJalali(parsed);
}
