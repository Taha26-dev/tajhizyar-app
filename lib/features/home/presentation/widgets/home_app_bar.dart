import 'package:flutter/material.dart';

import 'package:tajhizyar/core/constants/app_constants.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';

/// نوار بالای صفحه اصلی: لوگو + نام اپ + زیرعنوان + آیکون‌های پنل فروشنده
/// و جستجو (سمت چپ در RTL).
///
/// آیکون فروشنده بر اساس وضعیت نشست تغییر می‌کند:
///  - لاگین‌نشده → Icons.login_rounded («ورود فروشنده»)
///  - لاگین‌شده → Icons.person_rounded («پنل فروشنده»)
/// هر دو به تب ۳ (پنل/ورود) هدایت می‌کنند.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key, this.onSearchTap, this.onSellerPanelTap});

  /// رویداد کلیک روی آیکون جستجو
  final VoidCallback? onSearchTap;

  /// رویداد کلیک روی آیکون ورود/پنل فروشنده
  final VoidCallback? onSellerPanelTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // ── لوگوی اپ (گلیف TY روی نشان کم‌رنگ) ──
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              'assets/icons/logo.png',
              fit: BoxFit.contain,
              semanticLabel: 'لوگوی تجهیزیار',
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                AppConstants.homeSubtitle,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ],
      ),
      // در RTL، actions سمت چپ قرار می‌گیرد
      actions: <Widget>[
        // ── ورود / پنل فروشنده (آیکون بر اساس وضعیت نشست) ──
        ValueListenableBuilder<bool>(
          valueListenable: SellerAuthController.instance.isLoggedInNotifier,
          builder: (BuildContext context, bool isLoggedIn, _) => IconButton(
            tooltip: isLoggedIn ? 'پنل فروشنده' : 'ورود فروشنده',
            onPressed: onSellerPanelTap,
            icon: Icon(
              isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
              size: 24,
            ),
          ),
        ),
        IconButton(
          tooltip: 'جستجو',
          onPressed: onSearchTap,
          icon: const Icon(Icons.search, size: 26),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
