import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/constants/error_messages.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';

/// خروج اجباری از نشست نامعتبر — رفتار واحد کل اپلیکیشن برای خطای ۴۰۱.
///
/// هر جا فراخوانی API پنل فروشنده [ApiException.isSessionExpired] برگرداند
/// (پنل، شیت افزودن/ویرایش محصول، شیت ویرایش فروشگاه، آپلود تصویر و ...)
/// از همین تابع استفاده می‌شود تا رفتار همیشه یکسان باشد:
///
///  ۱. پاک کردن کامل نشست ([SellerAuthController.signOut] — توکن،
///     زمان انقضا و حساب)
///  ۲. نمایش پیام فارسی استاندارد [ErrorMessages.sessionExpired]
///  ۳. هدایت به صفحه ورود فروشنده (`/seller/login`)
///
/// در سیستم جدید توکن ۳۰ روزه است و با فعالیت تمدید می‌شود؛ ۴۰۱ یعنی
/// توکن منقضی شده یا باطل شده (مثلاً با «خروج از همه دستگاه‌ها» در
/// دستگاهی دیگر) — در هر دو حالت همین مسیر اجرا می‌شود. فراخوانی
/// logout/logout-all سرور در اینجا لازم نیست چون سرور خودش توکن را
/// نامعتبر اعلام کرده است.
Future<void> forceRelogin(BuildContext context) async {
  await SellerAuthController.instance.signOut();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text(ErrorMessages.sessionExpired)),
    );
  context.go(AppRoutes.sellerLogin);
}
