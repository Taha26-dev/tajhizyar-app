import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';

/// نمایشگر حالت خالی بودن داده‌ها.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    this.message,
    this.height,
    this.icon = Icons.inventory_2_outlined,
  });

  /// پیام حالت خالی
  final String? message;

  /// ارتفاع ناحیه — مناسب بخش‌های صفحه اصلی
  final double? height;

  /// آیکون حالت خالی
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 40, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          message ?? 'موردی یافت نشد.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
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
