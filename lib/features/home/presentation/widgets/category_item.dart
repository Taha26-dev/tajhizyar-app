import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/features/products/data/models/category_model.dart';

/// آیکون‌های جایگزین برای دسته‌بندی‌هایی که سرور آیکون برایشان ارسال نمی‌کند.
const List<IconData> _fallbackIcons = <IconData>[
  Icons.construction,
  Icons.electrical_services,
  Icons.bolt,
  Icons.plumbing,
  Icons.handyman,
  Icons.precision_manufacturing,
  Icons.hardware,
  Icons.format_paint,
  Icons.local_shipping,
  Icons.settings,
];

/// یک آیتم دسته‌بندی: آیکون دایره‌ای + نام دسته.
class CategoryItem extends StatelessWidget {
  const CategoryItem({super.key, required this.category, required this.onTap});

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildIcon(),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// آیکون دایره‌ای: تصویر شبکه‌ای در صورت وجود، در غیر این‌صورت آیکون جایگزین.
  Widget _buildIcon() {
    final String? iconUrl = category.iconUrl;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: iconUrl == null
          ? _fallbackIcon()
          : ClipOval(
              child: Image.network(
                iconUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, Object __, StackTrace? ___) =>
                    _fallbackIcon(),
              ),
            ),
    );
  }

  Widget _fallbackIcon() {
    final IconData icon = _fallbackIcons[category.id % _fallbackIcons.length];
    return Center(
      child: Icon(icon, size: 26, color: AppColors.primary),
    );
  }
}
