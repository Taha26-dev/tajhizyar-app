import 'package:flutter/material.dart';

import 'package:tajhizyar/core/constants/error_messages.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';

/// نمایشگر مشترک حالت خطا — آیکون + پیام فارسی واضح + دکمه «تلاش مجدد».
///
/// پیام ورودی معمولاً از [apiErrorMessage] می‌آید (پیام استاندارد از
/// [ErrorMessages])؛ اگر داده نشود، پیام پیش‌فرض «خطای ناشناخته»
/// نمایش داده می‌شود.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.height,
    this.icon = Icons.error_outline_rounded,
  });

  /// پیام خطا (در صورت ندادن، پیام استاندارد «خطای ناشناخته» نمایش
  /// داده می‌شود)
  final String? message;

  /// callback تلاش مجدد
  final VoidCallback? onRetry;

  /// ارتفاع ناحیه — مناسب بخش‌های صفحه اصلی
  final double? height;

  /// آیکون خطا (قابل تغییر برای خطاهای خاص، مثل قطع اینترنت)
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          color: AppColors.error,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          message ?? ErrorMessages.unknown,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text(ErrorMessages.retry),
        ),
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: Center(child: content));
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: content),
    );
  }
}
