import 'package:tajhizyar/core/constants/error_messages.dart';

/// دسته‌ی خطای API — برای نگاشت پیام استاندارد فارسی در [ApiClient]
/// و تصمیم‌گیری برنامه‌ای در UI (مثل هدایت به صفحه ورود هنگام انقضای نشست).
enum ApiErrorKind {
  /// قطع اینترنت / عدم دسترسی به سرور
  network,

  /// مهلت درخواست به پایان رسید
  timeout,

  /// پاسخ ناموفق سرور (خطاهای ۵xx یا `success == false` بدون توضیح)
  server,

  /// توکن نامعتبر / انقضای نشست (۴۰۱)
  unauthorized,

  /// منبع یافت نشد (۴۰۴)
  notFound,

  /// هر خطای دیگر که در لایه شبکه دسته‌بندی نشده
  unknown,
}

/// خطای سطح API با دسته و پیام فارسی قابل نمایش مستقیم به کاربر.
///
/// نگاشت خطاهای خام (Timeout، ClientException، کدهای وضعیت و ...) به
/// این کلاس و پیام‌های استاندارد [ErrorMessages] فقط در [ApiClient]
/// انجام می‌شود؛ صفحات فقط پیام را نمایش می‌دهند.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.kind = ApiErrorKind.unknown,
  });

  /// پیام خطا — در صورت وجود، پیام فارسی ارسالی از سمت سرور
  /// (مثل «نام کاربری یا رمز عبور اشتباه است»)؛ در غیر این صورت
  /// پیام استاندارد متناسب با دسته از [ErrorMessages].
  final String message;

  /// کد وضعیت HTTP خطاهای مبتنی بر پاسخ سرور (مثل `401` یا `404`).
  final int? statusCode;

  /// دسته‌ی خطا — مبنای رفتار UI (مثل [isSessionExpired]).
  final ApiErrorKind kind;

  /// آیا خطا ناشی از انقضای نشست است؟ (کد ۴۰۱)
  ///
  /// UI با این پرچم نشست را پاک و کاربر را به صفحه ورود هدایت می‌کند
  /// (به‌جای چک مستقیم statusCode که شکننده است).
  bool get isSessionExpired =>
      kind == ApiErrorKind.unauthorized || statusCode == 401;

  @override
  String toString() => message;
}

/// پیام فارسی قابل نمایش برای هر خطا — نگاشت یک‌جای خطا به متن.
///
/// ورودی ممکن است [ApiException] باشد (پیام خودش) یا هر خطای دیگر
/// (خطای parse و ...) که پیام استاندارد «خطای ناشناخته» می‌گیرد.
/// در FutureBuilderها و catchهای عمومی استفاده می‌شود تا هر صفحه
/// پیام پیش‌فرض خودش را نسازد (کاهش کد تکراری).
String apiErrorMessage(Object? error) {
  if (error is ApiException) return error.message;
  return ErrorMessages.unknown;
}
