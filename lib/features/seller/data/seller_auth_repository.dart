import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/network/api_client.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/features/seller/data/models/seller_account_model.dart';

/// نتیجه موفق ورود فروشنده — توکن + اطلاعات حساب.
class SellerAuthResult {
  const SellerAuthResult({required this.token, required this.account});

  /// توکن Bearer برای فراخوانی APIهای پنل فروشنده
  final String token;

  /// اطلاعات حساب فروشنده (در حدی که سرور ارسال می‌کند)
  final SellerAccountModel account;
}

/// ریپازیتوری احراز هویت فروشنده — `POST /api/seller/login.php`.
class SellerAuthRepository {
  SellerAuthRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// ورود فروشنده با نام کاربری و رمز عبور.
  ///
  /// - اطلاعات نادرست (401) → [ApiException] با پیام فارسی سرور
  ///   («نام کاربری یا رمز عبور اشتباه است»)
  /// - نبود توکن در پاسخ موفق → [ApiException] («پاسخ سرور معتبر نیست»)
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
    final SellerAccountModel account = _extractAccount(decoded);
    return SellerAuthResult(token: token, account: account);
  }

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
