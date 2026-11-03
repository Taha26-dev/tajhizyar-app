/// مسیرها و نام‌های صفحه‌های اپلیکیشن.
///
/// این کلاس «منبع حقیقت» (Single Source of Truth) مسیریابی است؛
/// هر دو لایه [GoRoute] و فراخوانی‌های `context.go` / `context.push`
/// باید از همین‌جا استفاده کنند.
abstract final class AppRoutes {
  // ─────────── مسیرها (Paths) ───────────

  /// صفحه پیش‌بارگذاری (Splash) — مسیر ابتدایی اپ
  static const String splash = '/splash';

  /// صفحه اصلی
  static const String home = '/';

  /// لیست محصولات (با قابلیت فیلتر دسته‌بندی)
  static const String productList = '/products';

  /// جزئیات محصول — پارامتر مسیر: productId
  static const String productDetail = '/products/:productId';

  /// صفحه فروشنده — پارامتر مسیر: sellerId
  static const String seller = '/sellers/:sellerId';

  /// ورود فروشنده
  static const String sellerLogin = '/seller/login';

  /// پنل فروشنده
  static const String sellerPanel = '/seller/panel';

  // ─────────── نام‌ها (Names) — برای ناوبری نام‌محور ───────────

  static const String homeName = 'home';
  static const String splashName = 'splash';
  static const String productListName = 'product-list';
  static const String productDetailName = 'product-detail';
  static const String sellerName = 'seller';
  static const String sellerLoginName = 'seller-login';
  static const String sellerPanelName = 'seller-panel';

  // ─────────── سازنده‌های مسیر پارامتری ───────────

  /// ساخت مسیر جزئیات محصول از روی شناسه آن.
  static String productDetailPath(String productId) =>
      '/products/$productId';

  /// ساخت مسیر لیست محصولات با فیلتر اختیاری دسته‌بندی و/یا جستجو.
  ///
  /// مثال:
  ///  - `productListPath()` → «/products»
  ///  - `productListPath(categoryId: 3)` → «/products?category_id=3»
  ///  - `productListPath(search: 'دریل')` → «/products?search=دریل»
  static String productListPath({int? categoryId, String? search}) {
    final Map<String, String> query = <String, String>{
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    if (query.isEmpty) return productList;
    return Uri(path: productList, queryParameters: query).toString();
  }

  /// ساخت مسیر صفحه فروشنده از روی شناسه آن.
  static String sellerPath(String sellerId) => '/sellers/$sellerId';
}
