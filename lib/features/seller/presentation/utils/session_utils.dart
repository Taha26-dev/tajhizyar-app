import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/constants/error_messages.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';

/// خروج اجباری از نشست منقضی‌شده — رفتار واحد کل اپلیکیشن برای خطای ۴۰۱.
///
/// هر جا فراخوانی API پنل فروشنده [ApiException.isSessionExpired] برگرداند
/// (پنل، شیت افزودن/ویرایش محصول، شیت ویرایش فروشگاه، آپلود تصویر و ...)
/// از همین تابع استفاده می‌شود تا رفتار همیشه یکسان باشد:
///
///  ۱. پاک کردن کامل نشست ([SellerAuthController.signOut])
///  ۲. نمایش پیام فارسی استاندارد [ErrorMessages.sessionExpired]
///  ۳. هدایت به صفحه ورود فروشنده (`/seller/login`)
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
