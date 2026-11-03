import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';

/// باکس پیام خطای فرم (قرمز کم‌رنگ) — بالای فیلدها.
///
/// ویجت مشترک فرم‌های پنل فروشنده (افزودن/ویرایش محصول،
/// ویرایش اطلاعات فروشگاه).
class FormErrorBox extends StatelessWidget {
  const FormErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
