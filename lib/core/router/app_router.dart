import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/widgets/main_shell.dart';
import 'package:tajhizyar/features/home/presentation/pages/home_screen.dart';
import 'package:tajhizyar/features/products/presentation/pages/product_detail_screen.dart';
import 'package:tajhizyar/features/products/presentation/pages/product_list_screen.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_controller.dart';
import 'package:tajhizyar/features/seller/presentation/pages/seller_login_screen.dart';
import 'package:tajhizyar/features/seller/presentation/pages/seller_panel_screen.dart';
import 'package:tajhizyar/features/seller/presentation/pages/seller_screen.dart';
import 'package:tajhizyar/features/splash/presentation/pages/splash_screen.dart';

/// پیکربندی مرکزی مسیریابی اپلیکیشن با go_router.
///
/// ساختار مسیرها:
/// ```
/// /splash                → SplashScreen (پیش‌بارگذاری — مسیر ابتدایی)
///
/// StatefulShellRoute (پوسته با نوار پایین — state تب‌ها حفظ می‌شود)
/// ├── تب ۱:  /                → HomeScreen
/// ├── تب ۲:  /products        → ProductListScreen (همه محصولات)
/// └── تب ۳:  /seller/panel    → SellerPanelScreen (بدون توکن → ورود)
///            /seller/login    → SellerLoginScreen (با توکن → پنل)
///
/// مسیرهای تمام‌صفحه (خارج از پوسته — بدون نوار پایین):
/// /products/:productId  → ProductDetailScreen
/// /sellers/:sellerId    → SellerScreen
/// ```
///
/// گارد تب ۳ «همگام» است: وضعیت نشست در [SellerAuthController] (کش
/// حافظه‌ی shared_preferences، بارگذاری‌شده در `main()`) خوانده می‌شود؛
/// پنل بدون نشست به صفحه ورود و صفحه ورود با نشست فعال به پنل هدایت
/// می‌شود — بدون خروج از تب سوم.
abstract final class AppRouter {
  AppRouter._();

  /// پیکربند مسیریاب سراسری اپلیکیشن.
  static final GoRouter router = GoRouter(
    // شروع اپ با Splash — پس از ~۲.۵ ثانیه خودش به `/` می‌رود؛
    // دیپ‌لینک مستقیم (مثل /products/5) از Splash عبور می‌کند.
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      // ═══════════ صفحه پیش‌بارگذاری (خارج از پوسته) ═══════════
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),

      // ═══════════ پوسته ناوبری (۳ تب) ═══════════
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          // ── تب ۱: صفحه اصلی ──
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.home,
                name: AppRoutes.homeName,
                builder: (BuildContext context, GoRouterState state) =>
                    const HomeScreen(),
              ),
            ],
          ),

          // ── تب ۲: لیست محصولات (همه محصولات) ──
          //
          // ⚠️ pageBuilder با کلیدِ «URI کامل»: کلید پیش‌فرض go_router فقط
          // از الگوی مسیر (/products) ساخته می‌شود و شامل query نیست؛ نتیجه:
          // با تغییر category_id صفحه‌ی موجود (IndexedStack تب) State قدیمی
          // را نگه می‌داشت و فیلتر اعمال نمی‌شد. با کلید URI-محور، هر
          // فیلتر/جستجوی جدید صفحه‌ی تازه‌ای می‌سازد (بدون انیمیشن اضافی).
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.productList,
                name: AppRoutes.productListName,
                pageBuilder: (
                  BuildContext context,
                  GoRouterState state,
                ) => NoTransitionPage<void>(
                  key: ValueKey<String>(state.uri.toString()),
                  child: ProductListScreen(
                    categoryId: int.tryParse(
                      state.uri.queryParameters['category_id'] ?? '',
                    ),
                    initialSearch: _cleanSearchParam(
                      state.uri.queryParameters['search'],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── تب ۳: پنل فروشنده / ورود ──
          StatefulShellBranch(
            routes: <RouteBase>[
              // پنل فروشنده (گارد: بدون نشست → ورود)
              GoRoute(
                path: AppRoutes.sellerPanel,
                name: AppRoutes.sellerPanelName,
                redirect: _sellerPanelGuard,
                builder: (BuildContext context, GoRouterState state) =>
                    const SellerPanelScreen(),
              ),
              // ورود فروشنده (گارد: با نشست فعال → پنل)
              GoRoute(
                path: AppRoutes.sellerLogin,
                name: AppRoutes.sellerLoginName,
                redirect: _sellerLoginGuard,
                builder: (BuildContext context, GoRouterState state) =>
                    const SellerLoginScreen(),
              ),
            ],
          ),
        ],
      ),

      // ═══════════ مسیرهای تمام‌صفحه (بدون نوار پایین) ═══════════

      // ── جزئیات محصول ──
      GoRoute(
        path: AppRoutes.productDetail,
        name: AppRoutes.productDetailName,
        builder: (BuildContext context, GoRouterState state) {
          final String productId = state.pathParameters['productId'] ?? '';
          return ProductDetailScreen(productId: productId);
        },
      ),

      // ── صفحه فروشنده ──
      GoRoute(
        path: AppRoutes.seller,
        name: AppRoutes.sellerName,
        builder: (BuildContext context, GoRouterState state) {
          final String sellerId = state.pathParameters['sellerId'] ?? '';
          return SellerScreen(sellerId: sellerId);
        },
      ),
    ],
  );

  // ─────────── گاردهای نشست فروشنده (همگام) ───────────

  /// پاکسازی پارامتر جستجوی query — خالی/فقط فاصله → null.
  static String? _cleanSearchParam(String? raw) {
    final String trimmed = (raw ?? '').trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// پنل فقط برای فروشنده لاگین‌شده — بدون نشست → صفحه ورود.
  static String? _sellerPanelGuard(
    BuildContext context,
    GoRouterState state,
  ) =>
      SellerAuthController.instance.isLoggedIn
          ? null
          : AppRoutes.sellerLogin;

  /// صفحه ورود فقط برای فروشنده لاگین‌نشده — نشست فعال → پنل.
  static String? _sellerLoginGuard(
    BuildContext context,
    GoRouterState state,
  ) =>
      SellerAuthController.instance.isLoggedIn
          ? AppRoutes.sellerPanel
          : null;
}
