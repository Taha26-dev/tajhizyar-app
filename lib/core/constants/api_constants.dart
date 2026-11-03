/// آدرس‌ها و تنظیمات مشترک API سرور تجهیزیار.
abstract final class ApiConstants {
  ApiConstants._();

  /// هاست اصلی سرور
  static const String _host = 'cr8v.ir';

  /// مهلت مجاز هر درخواست شبکه
  static const Duration requestTimeout = Duration(seconds: 15);

  /// مهلت آپلود فایل (تصویر محصول) — روی اینترنت موبایل طولانی‌تر از
  /// درخواست‌های معمول است؛ پس مهلت جداگانه دارد.
  static const Duration uploadTimeout = Duration(seconds: 60);

  /// `GET /api/categories.php` — فهرست دسته‌بندی‌ها
  static Uri categoriesUri() => Uri.https(_host, '/api/categories.php');

  /// `GET /api/product.php?id={id}` — جزئیات کامل یک محصول
  static Uri productUri(int productId) => Uri.https(
        _host,
        '/api/product.php',
        <String, String>{'id': productId.toString()},
      );

  /// `GET /api/seller.php?id={id}` — پروفایل فروشنده + محصولاتش
  static Uri sellerUri(int sellerId) => Uri.https(
        _host,
        '/api/seller.php',
        <String, String>{'id': sellerId.toString()},
      );

  // ─────────── APIهای احراز هویت‌شده پنل فروشنده ───────────

  /// `POST /api/seller/login.php` — ورود فروشنده
  /// (بدنه JSON: `{"username": "...", "password": "..."}`)
  static Uri sellerLoginUri() => Uri.https(_host, '/api/seller/login.php');

  /// `/api/seller/products.php` — مجموعه محصولات فروشنده
  /// (نیازمند هدر `Authorization: Bearer {token}`):
  /// - `GET`  → فهرست محصولات فروشنده لاگین‌شده
  /// - `POST` → افزودن محصول جدید — بدون هیچ id (نه در URL و نه در بدنه)
  static Uri sellerProductsUri() => Uri.https(
        _host,
        '/api/seller/products.php',
      );

  /// `PUT    /api/seller/product.php?id={id}` — ویرایش محصول (نیازمند توکن)
  /// `DELETE /api/seller/product.php?id={id}` — حذف محصول (نیازمند توکن)
  ///
  /// ⚠️ افزودن محصول جدید از این endpoint استفاده «نمی‌کند»؛ افزودن
  /// حتماً POST به `/api/seller/products.php` (جمع) است. POST به این
  /// endpoint (مفرد) بدون id → خطای «شناسه محصول نامعتبر است».
  static Uri sellerProductUri({int? productId}) => Uri.https(
        _host,
        '/api/seller/product.php',
        <String, String>{
          if (productId != null) 'id': productId.toString(),
        },
      );

  /// `POST /api/seller/upload.php` — آپلود تصویر محصول (multipart)
  /// (نیازمند توکن؛ فیلد فایل: `image`)
  static Uri sellerUploadUri() => Uri.https(_host, '/api/seller/upload.php');

  /// `GET /api/seller/profile.php` — اطلاعات فروشنده لاگین‌شده
  /// `PUT /api/seller/profile.php` — ویرایش اطلاعات فروشنده
  ///
  /// بدنه PUT (JSON): name، description، phone، whatsapp، city،
  /// logo_url (اختیاری). هر دو متد نیازمند هدر
  /// `Authorization: Bearer {token}` هستند.
  static Uri sellerProfileUri() => Uri.https(_host, '/api/seller/profile.php');

  /// `POST /api/seller/logout.php` — خروج از دستگاه فعلی
  /// (نیازمند هدر `Authorization: Bearer {token}`؛ فقط توکن فعلی باطل می‌شود)
  static Uri sellerLogoutUri() => Uri.https(_host, '/api/seller/logout.php');

  /// `POST /api/seller/logout-all.php` — خروج از همه دستگاه‌ها
  /// (نیازمند هدر `Authorization: Bearer {token}`؛ همه توکن‌های فعال
  /// حساب — از جمله توکن همین دستگاه — باطل می‌شوند)
  static Uri sellerLogoutAllUri() =>
      Uri.https(_host, '/api/seller/logout-all.php');

  /// `GET /api/products.php` — فهرست محصولات (با پارامترهای اختیاری)
  static Uri productsUri({
    int? limit,
    int? categoryId,
    int? page,
    String? search,
  }) =>
      Uri.https(
        _host,
        '/api/products.php',
        <String, String>{
          if (limit != null) 'limit': limit.toString(),
          if (categoryId != null) 'category_id': categoryId.toString(),
          if (page != null) 'page': page.toString(),
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

  /// تبدیل مسیر نسبی تصاویر به آدرس کامل قابل استفاده در `Image.network`.
  ///
  /// - `null` یا خالی → `null`
  /// - آدرس کامل (`http(s)://...`) → بدون تغییر
  /// - مسیر نسبی (`/uploads/x.jpg`) → اتصال به هاست اصلی
  static String? resolveUrl(String? url) {
    if (url == null) return null;
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$_host${trimmed.startsWith('/') ? '' : '/'}$trimmed';
  }
}
