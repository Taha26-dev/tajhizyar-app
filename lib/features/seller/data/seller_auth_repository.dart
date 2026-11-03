import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/network/api_client.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/features/seller/data/models/seller_account_model.dart';

/// نتیجه موفق ورود فروشنده — توکن + اطلاعات حساب.
class SellerAuthResult {
  const SellerAuthResult({
    required this.token,
    required this.account,
    this.expiresAt,
  });

  /// توکن نشست — در سیستم جدید سرور توکنی با ساختار اختصاصی صادر
  /// می‌کند (دیگر base64 ساده نیست). اپ توکن را «opaque» در نظر می‌گیرد:
  /// دقیقاً همان‌طور که از login برمی‌گردد ذخیره و در هدر
  /// `Authorization: Bearer {token}` ارسال می‌شود — بدون هرگونه
  /// تفسیر یا decode محلی.
  final String token;

  /// اطلاعات حساب فروشنده (در حدی که سرور ارسال می‌کند)
  final SellerAccountModel account;

  /// زمان اعلامی انقضای توکن از سمت سرور — اختیاری.
  ///
  /// در سیستم جدید اعتبار توکن ۳۰ روز است و «با فعالیت تمدید می‌شود»
  /// (تمدید لغزان سمت سرور)؛ بنابراین این مقدار فقط اطلاعاتی است و
  /// مبنای خروج خودکار محلی نیست — ملاک واقعی اعتبار، پاسخ ۴۰۱ سرور است.
  final DateTime? expiresAt;
}

/// ریپازیتوری احراز هویت فروشنده:
///
/// - `POST /api/seller/login.php`       → ورود (توکن + حساب + انقضا)
/// - `POST /api/seller/logout.php`      → خروج از دستگاه فعلی
/// - `POST /api/seller/logout-all.php`  → خروج از همه دستگاه‌ها
class SellerAuthRepository {
  SellerAuthRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// ورود فروشنده با نام کاربری و رمز عبور.
  ///
  /// - اطلاعات نادرست (401) → [ApiException] با پیام فارسی سرور
  ///   («نام کاربری یا رمز عبور اشتباه است»)
  /// - نبود توکن در پاسخ موفق → [ApiException] («پاسخ سرور معتبر نیست»)
  /// - `expires_at` در صورت وجود در پاسخ، به‌صورت اختیاری برگردانده می‌شود
  Future<SellerAuthResult> login({
    required String username,
    required String password,
  }) async {
    final Object? decoded = await _api.postJson(
      ApiConstants.sellerLoginUri(),
      body: <String, String>{
        'username': username.trim(),
        'password': password,
      },
    );

    final String token = _extractToken(decoded);
    final DateTime? expiresAt = _extractExpiresAt(decoded);
    final SellerAccountModel account = _extractAccount(decoded);
    return SellerAuthResult(
      token: token,
      account: account,
      expiresAt: expiresAt,
    );
  }

  /// خروج از دستگاه فعلی — `POST /api/seller/logout.php` با توکن Bearer؛
  /// فقط توکن همین دستگاه در سرور باطل می‌شود.
  ///
  /// - ۴۰۱ → نشست از قبل در سرور باطل/منقضی است؛ [ApiException] با
  ///   [ApiErrorKind.unauthorized] پرتاب می‌شود و فراخوان می‌تواند آن را
  ///   مثل «قبلاً خارج شده» در نظر بگیرد (خروج محلی همچنان لازم است).
  /// - `success == false` بی‌صدا نادیده گرفته می‌شود ([allowFailure])؛
  ///   تصمیم نهایی درباره ادامه خروج و پیام آن با صفحه UI است.
  Future<void> logout({required String token}) =>
      _api.postJson(
        ApiConstants.sellerLogoutUri(),
        bearerToken: token,
        allowFailure: true,
      );

  /// خروج از همه دستگاه‌ها — `POST /api/seller/logout-all.php` با توکن
  /// Bearer؛ همه توکن‌های فعال حساب (از جمله همین دستگاه) باطل می‌شوند.
  ///
  /// رفتار خطا دقیقاً مثل [logout] است.
  Future<void> logoutAll({required String token}) =>
      _api.postJson(
        ApiConstants.sellerLogoutAllUri(),
        bearerToken: token,
        allowFailure: true,
      );

  // ─────────── بخش خصوصی ───────────

  /// استخراج توکن از پاسخ — پوشش ساختارهای رایج:
  /// `token` / `access_token` / `api_token` در ریشه پاسخ یا داخل `data`.
  static String _extractToken(Object? decoded) {
    final List<Map<String, dynamic>> candidates = <Map<String, dynamic>>[
      if (decoded is Map<String, dynamic>) decoded,
      if (decoded is Map<String, dynamic> && decoded['data'] is Map)
        Map<String, dynamic>.from(decoded['data'] as Map<Object?, Object?>),
    ];
    for (final Map<String, dynamic> map in candidates) {
      for (final String key
          in const <String>['token', 'access_token', 'api_token', 'auth_token']) {
        final Object? value = map[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    throw const ApiException(
      'پاسخ سرور معتبر نیست؛ توکن ورود دریافت نشد.',
    );
  }

  /// استخراج اختیاری زمان انقضای توکن از پاسخ — پوشش ساختارهای رایج:
  /// `expires_at` / `expiresAt` / `expire_at` / `expires` / `expiry` /
  /// `token_expires_at` در ریشه پاسخ یا داخل `data`.
  ///
  /// فیلد اختیاری است؛ نبود یا مقدار غیرقابل تفسیر → null (بدون خطا).
  static DateTime? _extractExpiresAt(Object? decoded) {
    final List<Map<String, dynamic>> candidates = <Map<String, dynamic>>[
      if (decoded is Map<String, dynamic>) decoded,
      if (decoded is Map<String, dynamic> && decoded['data'] is Map)
        Map<String, dynamic>.from(decoded['data'] as Map<Object?, Object?>),
    ];
    for (final Map<String, dynamic> map in candidates) {
      for (final String key in const <String>[
        'expires_at',
        'expiresAt',
        'expire_at',
        'token_expires_at',
        'expires',
        'expiry',
      ]) {
        final DateTime? parsed = _parseDateTime(map[key]);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// تبدیل مقدار زمان انقضا به [DateTime] — پشتیبانی از:
  /// - epoch عددی یا رشته‌ای: ثانیه یا میلی‌ثانیه (تشخیص خودکار)
  /// - رشته ISO 8601 یا فرمت رایج دیتابیس (`2025-01-30 12:00:00`)
  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    if (value is num) {
      return value <= 0 ? null : _fromEpoch(value.toInt());
    }
    if (value is! String) return null;
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    // epoch رشته‌ای («1738256400» یا «1738256400000»)
    final int? epoch = int.tryParse(trimmed);
    if (epoch != null) return _fromEpoch(epoch);

    // ISO 8601 یا «2025-01-30 12:00:00» — DateTime.tryParse هر دو را
    // می‌پذیرد؛ رشته بدون منطقه زمانی به‌عنوان زمان محلی تفسیر می‌شود.
    return DateTime.tryParse(trimmed);
  }

  /// epoch ثانیه یا میلی‌ثانیه → [DateTime] محلی —
  /// مقادیر بزرگ‌تر از ۱۰۰ میلیارد میلی‌ثانیه فرض می‌شوند (ثانیه‌های
  /// فعلی حدود ۱۰ رقماند و میلی‌ثانیه‌ها ۱۳ رقم).
  static DateTime _fromEpoch(int value) {
    final int milliseconds = value > 100000000000 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  /// استخراج اطلاعات حساب از پاسخ — اطلاعات ممکن است مستقیم داخل
  /// `data` باشد یا زیر کلید `seller` / `user`.
  static SellerAccountModel _extractAccount(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      return const SellerAccountModel(id: 0, name: 'فروشنده');
    }
    final Object? data = decoded['data'];
    if (data is Map) {
      final Map<String, dynamic> dataMap =
          Map<String, dynamic>.from(data);
      final Object? nested = dataMap['seller'] ?? dataMap['user'];
      if (nested is Map) {
        return SellerAccountModel.fromJson(
          Map<String, dynamic>.from(nested),
        );
      }
      return SellerAccountModel.fromJson(dataMap);
    }
    // پاسخ بدون `data` — شاید اطلاعات مستقیم در ریشه باشد.
    return SellerAccountModel.fromJson(decoded);
  }

  /// آزادسازی منابع کلاینت HTTP.
  void dispose() => _api.dispose();
}
