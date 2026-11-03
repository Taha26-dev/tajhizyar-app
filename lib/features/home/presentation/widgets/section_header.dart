import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';

/// سرتیتر بخش‌های صفحه اصلی با خط تأکید نارنجی و دکمه «مشاهده همه».
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onViewAll});

  /// عنوان بخش
  final String title;

  /// رویداد کلیک روی «مشاهده همه» (در صورت null، دکمه نمایش داده نمی‌شود)
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (onViewAll != null)
            TextButton.icon(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('مشاهده همه'),
            ),
        ],
      ),
    );
  }
}
