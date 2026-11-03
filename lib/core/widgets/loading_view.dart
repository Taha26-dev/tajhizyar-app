import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';

/// نمایشگر حالت بارگذاری (اسپینر در مرکز ناحیه).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.height, this.label});

  /// ارتفاع ناحیه بارگذاری — مناسب بخش‌های صفحه اصلی
  final double? height;

  /// متن اختیاری زیر اسپینر
  final String? label;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const CircularProgressIndicator(color: AppColors.primary),
        if (label != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );

    if (height != null) {
      return SizedBox(height: height, child: Center(child: content));
    }
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: content),
    );
  }
}
