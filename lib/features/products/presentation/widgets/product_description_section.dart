import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/widgets/accent_section_title.dart';

/// بخش «توضیحات» محصول — عنوان + متن توضیحات.
/// اگر توضیحی ثبت نشده باشد، پیام جایگزین نمایش داده می‌شود.
class ProductDescriptionSection extends StatelessWidget {
  const ProductDescriptionSection({super.key, required this.description});

  /// متن توضیحات محصول (ممکن است null یا خالی باشد)
  final String? description;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasDescription =
        description != null && description!.trim().isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // در RTL «start» یعنی سمت راست
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AccentSectionTitle(title: 'توضیحات'),
            const SizedBox(height: 8),
            Text(
              hasDescription ? description!.trim() : 'توضیحی ثبت نشده است.',
              style: textTheme.bodyMedium?.copyWith(
                height: 1.9,
                fontSize: 13.5,
                color: hasDescription
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
