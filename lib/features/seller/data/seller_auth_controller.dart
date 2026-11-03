import 'package:flutter/foundation.dart';

import 'package:tajhizyar/features/seller/data/models/seller_account_model.dart';
import 'package:tajhizyar/features/seller/data/seller_auth_storage.dart';

/// کنترلر نشست فروشنده — منبع واحد وضعیت «لاگین بودن» در کل اپلیکیشن.
///
/// گارد مسیرهای ورود/پنل در روتر به ارزیابی «همگام» (sync) نیاز دارد؛
/// به همین دلیل وضعیت پس از [loadSession] (یک‌بار در شروع اپ، پیش از
/// `runApp`) در حافظه کش می‌شود. ذخیره‌سازی دائمی همچنان با
/// [SellerAuthStorage] (shared_preferences) انجام می‌شود.
///
/// [isLoggedInNotifier] برای بخش‌های UI است که باید بی‌درنگ با تغییر
/// نشست به‌روز شوند (مثل آیکون پنل فروشنده در نوار بالای صفحه اصلی).
class SellerAuthController {
  SellerAuthController._();

  /// نمونه مشترک سراسری
  static final SellerAuthController instance = SellerAuthController._();

  final SellerAuthStorage _storage = SellerAuthStorage();

  String? _token;
  SellerAccountModel? _account;
  DateTime? _expiresAt;

  /// وضعیت نشست برای شنوندگان UI — true یعنی فروشنده لاگین است.
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);

  /// آیا نشست فعال وجود دارد؟ (خواندن همگام از کش حافظه)
  bool get isLoggedIn => _token != null;

  /// توکن نشست فعال — بدون نشست → null
  String? get token => _token;

  /// اطلاعات حساب فروشنده لاگین‌شده — بدون نشست → null
  SellerAccountModel? get account => _account;

  /// زمان اعلامی انقضای توکن از سمت سرور — ممکن است null باشد
  /// (سرور همیشه این فیلد را نمی‌فرستد).
  ///
  /// ⚠️ صرفاً اطلاعاتی است و مبنای خروج خودکار محلی «نیست»: در سیستم
  /// جدید توکن ۳۰ روزه است و «با فعالیت تمدید می‌شود»، پس مقدار محلی
  /// ممکن است قدیمی باشد؛ ملاک واقعی اعتبار، پاسخ ۴۰۱ سرور است
  /// (مدیریت یک‌جا با `forceRelogin` در session_utils).
  DateTime? get expiresAt => _expiresAt;

  /// بارگذاری نشست ذخیره‌شده از حافظه محلی.
  ///
  /// باید یک‌بار در `main()` و پیش از `runApp` فراخوانی شود تا اولین
  /// ارزیابی گارد مسیرها روی وضعیت واقعی انجام شود.
  Future<void> loadSession() async {
    _token = await _storage.readToken();
    _account = await _storage.readAccount();
    _expiresAt = await _storage.readExpiresAt();
    isLoggedInNotifier.value = _token != null;
  }

  /// ثبت نشست پس از ورود موفق (ذخیره دائمی + به‌روزرسانی کش حافظه).
  ///
  /// [expiresAt] زمان اعلامی انقضای توکن از پاسخ ورود است — اختیاری؛
  /// توکن خودش عیناً و بدون تغییر ذخیره می‌شود.
  Future<void> signIn({
    required String token,
    required SellerAccountModel account,
    DateTime? expiresAt,
  }) async {
    await _storage.saveToken(token);
    await _storage.saveAccount(account);
    await _storage.saveExpiresAt(expiresAt);
    _token = token;
    _account = account;
    _expiresAt = expiresAt;
    isLoggedInNotifier.value = true;
  }

  /// به‌روزرسانی اطلاعات حساب فروشنده لاگین‌شده — پس از ویرایش موفق
  /// پروفایل: هم کش حافظه و هم ذخیره‌سازی دائمی تازه می‌شود
  /// (وضعیت لاگین تغییری نمی‌کند).
  Future<void> updateAccount(SellerAccountModel account) async {
    await _storage.saveAccount(account);
    _account = account;
  }

  /// خروج از حساب — پاک کردن کامل نشست (توکن، انقضا و حساب) از
  /// حافظه دائمی و کش.
  ///
  /// ⚠️ این متد فقط «خروج محلی» است؛ باطل کردن توکن در سرور با
  /// فراخوانی logout / logout-all (در [SellerAuthRepository]) انجام
  /// می‌شود و صفحه پنل مسئول فراخوانی آن پیش از این متد است.
  Future<void> signOut() async {
    await _storage.clear();
    _token = null;
    _account = null;
    _expiresAt = null;
    isLoggedInNotifier.value = false;
  }
}
