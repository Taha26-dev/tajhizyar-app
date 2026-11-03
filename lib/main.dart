import 'package:flutter/material.dart';

import 'package:tajhizyar/core/constants/app_constants.dart';
import 'package:tajhizyar/core/router/app_router.dart';
import 'package:tajhizyar/core/theme/app_theme.dart';
import 'package:tajhizyar/core/utils/app_localizations.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // بارگذاری نشست فروشنده از حافظه محلی، پیش از ساخت روتر — تا گارد
  // مسیرهای ورود/پنل (تب ۳) از همان شروع روی وضعیت واقعی ارزیابی شود.
  await SellerAuthController.instance.loadSession();

  runApp(const TajhizyarApp());
}

/// ویجت ریشه‌ی اپلیکیشن «تجهیزیار».
class TajhizyarApp extends StatelessWidget {
  const TajhizyarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ── تم سراسری (Material 3 + فونت وزیرمتن) ──
      theme: AppTheme.light(),

      // ── مسیریابی ──
      routerConfig: AppRouter.router,

      // ── بومی‌سازی (فارسی) ──
      locale: AppLocalization.locale,
      supportedLocales: AppLocalization.supportedLocales,
      localizationsDelegates: AppLocalization.delegates,

      // ── راست‌چین (RTL) اجباری در سراسر اپلیکیشن ──
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
