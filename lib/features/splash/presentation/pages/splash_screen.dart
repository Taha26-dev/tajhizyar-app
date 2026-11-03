import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_constants.dart';
import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';

/// صفحه پیش‌بارگذاری (Splash / Pre-loader) — اولین صفحه‌ی اپ.
///
/// طراحی مینیمال با هویت برند: پس‌زمینه سرمه‌ای [AppColors.primary]،
/// لوگوی اپ در نشان سفید گرد، نام و شعار اپ، و اسپینر با رنگ لهجه
/// [AppColors.secondary].
///
/// پس از ~۲.۵ ثانیه به‌طور خودکار به صفحه اصلی (`/`) می‌رود؛
/// (نشست فروشنده پیش از `runApp` در `main()` لود شده است، پس چیزی
/// برای انتظار اضافی نیست — این مکث فقط برای تجربه بصری برند است.)
///
/// ناوبری با `context.go` انجام می‌شود تا Splash از استک حذف شود
/// (دکمه بازگشت کاربر را به Splash برنمی‌گرداند).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// مدت نمایش Splash — بین ۲ تا ۳ ثانیه (تجربه‌ی برند)
  static const Duration _splashDuration = Duration(milliseconds: 2500);

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_splashDuration, _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// رفتن به صفحه اصلی — با go تا Splash از استک برداشته شود.
  void _goHome() {
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // نوار وضعیت روی پس‌زمینه تیره → آیکون‌های روشن
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const _AnimatedLogoBadge(),
                const SizedBox(height: 20),

                // ── نام اپ ──
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                ),
                const SizedBox(height: 6),

                // ── شعار اپ ──
                Text(
                  AppConstants.appTagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.65),
                        height: 1.6,
                      ),
                ),
                const SizedBox(height: 48),

                // ── اسپینر برند + متن کوتاه ──
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    strokeCap: StrokeCap.round,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'در حال بارگذاری...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.65),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// نشان لوگو با انیمیشن ورودی ملایم (fade + scale) —
/// با [TweenAnimationBuilder] بدون نیاز به Controller.
class _AnimatedLogoBadge extends StatelessWidget {
  const _AnimatedLogoBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double t, Widget? child) {
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.90 + 0.10 * t, child: child),
        );
      },
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Image.asset(
          'assets/icons/logo.png',
          fit: BoxFit.contain,
          // لوگو از پیش در باندل است؛ excludeFromSemantics چون
          // نام اپ جداگانه به‌عنوان متن خوانده می‌شود.
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
