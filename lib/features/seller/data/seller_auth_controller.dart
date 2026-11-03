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

  /// وضعیت نشست برای شنوندگان UI — true یعنی فروشنده لاگین است.
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);

  /// آیا نشست فعال وجود دارد؟ (خواندن همگام از کش حافظه)
  bool get isLoggedIn => _token != null;

  /// توکن نشست فعال — بدون نشست → null
  String? get token => _token;

  /// اطلاعات حساب فروشنده لاگین‌شده — بدون نشست → null
  SellerAccountModel? get account => _account;

  /// بارگذاری نشست ذخیره‌شده از حافظه محلی.
  ///
  /// باید یک‌بار در `main()` و پیش از `runApp` فراخوانی شود تا اولین
  /// ارزیابی گارد مسیرها روی وضعیت واقعی انجام شود.
  Future<void> loadSession() async {
    _token = await _storage.readToken();
    _account = await _storage.readAccount();
    isLoggedInNotifier.value = _token != null;
  }

  /// ثبت نشست پس از ورود موفق (ذخیره دائمی + به‌روزرسانی کش حافظه).
  Future<void> signIn({
    required String token,
    required SellerAccountModel account,
  }) async {
    await _storage.saveToken(token);
    await _storage.saveAccount(account);
    _token = token;
    _account = account;
    isLoggedInNotifier.value = true;
  }

  /// به‌روزرسانی اطلاعات حساب فروشنده لاگین‌شده — پس از ویرایش موفق
  /// پروفایل: هم کش حافظه و هم ذخیره‌سازی دائمی تازه می‌شود
  /// (وضعیت لاگین تغییری نمی‌کند).
  Future<void> updateAccount(SellerAccountModel account) async {
    await _storage.saveAccount(account);
    _account = account;
  }

  /// خروج از حساب — پاک کردن کامل نشست از حافظه دائمی و کش.
  Future<void> signOut() async {
    await _storage.clear();
    _token = null;
    _account = null;
    isLoggedInNotifier.value = false;
  }
}
