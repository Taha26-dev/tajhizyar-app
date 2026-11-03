import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:tajhizyar/features/seller/data/models/seller_account_model.dart';

/// سرویس مدیریت نشست فروشنده — ذخیره، خواندن و پاک کردن توکن
/// احراز هویت، زمان انقضای آن و اطلاعات حساب با `shared_preferences`.
///
/// توکن در سیستم جدید یک رشته مات (opaque) است و بدون تفسیر ذخیره
/// می‌شود؛ زمان انقضا (اختیاری، از پاسخ ورود) به‌صورت epoch
/// میلی‌ثانیه نگهداری می‌شود.
///
/// عمداً سبک و بدون وابستگی به UI است تا هم در روتر (گارد مسیرها)
/// و هم در صفحات ورود/پنل قابل استفاده باشد.
class SellerAuthStorage {
  SellerAuthStorage({Future<SharedPreferences>? prefs})
      : _prefsOverride = prefs;

  /// امکان تزریق نمونه آماده SharedPreferences در تست‌ها
  final Future<SharedPreferences>? _prefsOverride;

  /// کلید توکن در حافظه محلی
  static const String _tokenKey = 'seller_auth_token';

  /// کلید زمان انقضای توکن (epoch میلی‌ثانیه) در حافظه محلی
  static const String _expiresAtKey = 'seller_auth_expires_at';

  /// کلید اطلاعات حساب در حافظه محلی
  static const String _accountKey = 'seller_auth_account';

  // ─────────── توکن ───────────

  /// ذخیره توکن احراز هویت پس از ورود موفق.
  Future<void> saveToken(String token) async {
    final SharedPreferences prefs = await _instance;
    await prefs.setString(_tokenKey, token.trim());
  }

  /// خواندن توکن ذخیره‌شده — بدون نشست فعال → null.
  Future<String?> readToken() async {
    final SharedPreferences prefs = await _instance;
    final String? token = prefs.getString(_tokenKey);
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  // ─────────── زمان انقضای توکن ───────────

  /// ذخیره زمان اعلامی انقضای توکن (از پاسخ ورود، اختیاری) —
  /// null یعنی پاک کردن مقدار قبلی.
  Future<void> saveExpiresAt(DateTime? expiresAt) async {
    final SharedPreferences prefs = await _instance;
    if (expiresAt == null) {
      await prefs.remove(_expiresAtKey);
      return;
    }
    await prefs.setInt(_expiresAtKey, expiresAt.millisecondsSinceEpoch);
  }

  /// خواندن زمان انقضای ذخیره‌شده — ذخیره نشده → null.
  Future<DateTime?> readExpiresAt() async {
    final SharedPreferences prefs = await _instance;
    final int? milliseconds = prefs.getInt(_expiresAtKey);
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  // ─────────── اطلاعات حساب ───────────

  /// ذخیره اطلاعات حساب فروشنده (serialize شده به JSON).
  Future<void> saveAccount(SellerAccountModel account) async {
    final SharedPreferences prefs = await _instance;
    await prefs.setString(_accountKey, jsonEncode(account.toJson()));
  }

  /// خواندن اطلاعات حساب فروشنده — بدون نشست → null.
  Future<SellerAccountModel?> readAccount() async {
    final SharedPreferences prefs = await _instance;
    final String? raw = prefs.getString(_accountKey);
    if (raw == null || raw.isEmpty) return null;
    return SellerAccountModel.fromJsonString(raw);
  }

  // ─────────── خروج ───────────

  /// پاک کردن کامل نشست (خروج از حساب — توکن، زمان انقضا و حساب).
  Future<void> clear() async {
    final SharedPreferences prefs = await _instance;
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresAtKey);
    await prefs.remove(_accountKey);
  }

  Future<SharedPreferences> get _instance =>
      _prefsOverride ?? SharedPreferences.getInstance();
}
