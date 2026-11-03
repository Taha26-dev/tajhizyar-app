import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';

/// پوسته اصلی ناوبری اپلیکیشن — Scaffold با نوار پایین سه‌تبی
/// و مدیریت دکمه Back سیستم (اندروید).
///
/// با `StatefulShellRoute.indexedStack` استفاده می‌شود؛ هر تب ناوبر
/// مستقل خود را دارد و با جابه‌جایی بین تب‌ها، وضعیت صفحات (اسکرول،
/// متن جستجو، داده‌های بارگذاری‌شده) حفظ می‌شود.
///
/// ترتیب تب‌ها (در RTL از راست):
///  ۱. خانه → `/`
///  ۲. محصولات → `/products`
///  ۳. پنل فروشنده → `/seller/panel` (بدون نشست → ردایرکت به ورود)
///
/// ## رفتار دکمه Back سیستم
///
/// [PopScope] در سطح این پوسته قرار دارد؛ یعنی فقط وقتی دخالت می‌کند
/// که هیچ مسیر داخلی‌ای برای pop باقی نمانده باشد:
///
/// - صفحات داخلی (جزئیات محصول، صفحه فروشنده، شیت‌ها، دیالوگ‌ها و ...)
///   قبل از رسیدن Back به اینجا به‌صورت طبیعی pop می‌شوند.
/// - تب‌های غیر خانه: یک ضربه → برگشت به تب خانه (با حفظ state تب‌ها).
/// - تب خانه: ضربه اول پیام «برای خروج دوباره ضربه بزنید» را نشان
///   می‌دهد و ضربه دوم در بازه [_exitWindow] اپ را می‌بندد
///   ([SystemNavigator.pop]).
/// - صفحه ورود فروشنده مستثناست: Back اپ را می‌بندد (رفتار طبیعی
///   قبلی). صفحه Splash اصلاً خارج از این پوسته است و رفتار طبیعی
///   خود را دارد.
///
/// استایل (رنگ نشانگر، آیکون و متن) از `navigationBarTheme` تم سراسری
/// خوانده می‌شود.
class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  /// پوسته ناوبری حالت‌دار که شاخه‌های (تب‌های) فعال را نگه می‌دارد.
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// بازه‌ای که دو ضربه Back پشت‌سرهم «تأیید خروج» حساب می‌شوند.
  static const Duration _exitWindow = Duration(seconds: 2);

  /// مدت نمایش پیام راهنمای خروج — هماهنگ با بازه تأیید.
  static const Duration _exitNoticeDuration = Duration(seconds: 2);

  /// پیام کوتاه راهنمای خروج (فارسی)
  static const String _exitNotice = 'برای خروج دوباره ضربه بزنید';

  /// زمان آخرین ضربه Back در تب خانه — برای تشخیص دوبار ضربه پشت‌سرهم.
  DateTime? _lastBackPress;

  /// آیا کاربر فعلاً در صفحه ورود فروشنده است؟ (مستثنا از منطق Back)
  ///
  /// با مسیر فعلی روتر چک می‌شود تا این ویجت هسته (core) به ماژول
  /// فروشنده وابسته نماند. تب ۳ بدون نشست همیشه همین صفحه را نشان
  /// می‌دهد (گارد روتر)، پس چک مسیر کافی و قطعی است.
  bool _isOnSellerLogin() {
    final String location = GoRouter.of(context)
        .routeInformationProvider
        .value
        .uri
        .toString();
    return location.startsWith(AppRoutes.sellerLogin);
  }

  /// مدیریت Back سیستم — تصمیم‌گیری نهایی طبق قواعد کلاس.
  void _handleBack(bool didPop, Object? result) {
    // مسیر داخلی واقعاً pop شد (شیت/دایالوگ/صفحه روی پوسته) — کاری نیست.
    if (didPop) return;

    // ۱) صفحه ورود فروشنده — رفتار طبیعی (مستثنا): بستن اپ.
    if (_isOnSellerLogin()) {
      SystemNavigator.pop();
      return;
    }

    // ۲) تب‌های غیر خانه — یک ضربه: برگشت به تب خانه (state حفظ می‌شود).
    final int currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != 0) {
      _lastBackPress = null;
      widget.navigationShell.goBranch(0, initialLocation: false);
      return;
    }

    // ۳) تب خانه — دوبار ضربه پشت‌سرهم برای خروج.
    final DateTime now = DateTime.now();
    final DateTime? last = _lastBackPress;
    final bool inExitWindow =
        last != null && now.difference(last) <= _exitWindow;
    if (inExitWindow) {
      SystemNavigator.pop(); // تأیید شد → خروج از اپ
      return;
    }

    // ضربه اول — پیام راهنما و شروع بازه تأیید.
    _lastBackPress = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(_exitNotice),
          duration: _exitNoticeDuration,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // canPop همیشه false است و تصمیم نهایی در [_handleBack] گرفته
    // می‌شود تا رفتار Back مستقل از بازسازی‌های مسیر قطعی بماند.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handleBack,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (int index) {
            // شمارنده «خروج با دوبار ضربه» با هر جابه‌جایی دستی تب صفر
            // می‌شود تا ضربه قدیمی تأیید حساب نشود.
            _lastBackPress = null;
            widget.navigationShell.goBranch(
              index,
              // لمس دوباره تب فعال → بازگشت به مسیر ابتدایی همان تب
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'محصولات',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store_rounded),
              label: 'پنل فروشنده',
            ),
          ],
        ),
      ),
    );
  }
}
