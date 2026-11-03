import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';

/// عنوان بخش با نوار تأکید نارنجی — هماهنگ با SectionHeader صفحه اصلی،
/// برای بخش‌های داخل کارت (توضیحات، اطلاعات فروشنده و ...).
class AccentSectionTitle extends StatelessWidget {
  const AccentSectionTitle({super.key, required this.title});

  /// متن عنوان بخش
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
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
      ],
    );
  }
}
