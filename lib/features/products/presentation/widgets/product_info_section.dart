import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/core/utils/jalali_date.dart';
import 'package:tajhizyar/features/products/data/models/product_detail_model.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';

/// بخش اطلاعات اصلی محصول: عنوان درشت، چیپ‌های برند/دسته/موجودی،
/// قیمت تقریبی با فرمت فارسی + تاریخ آخرین به‌روزرسانی (شمسی)
/// و باکس هشدار نارنجی «قیمت تقریبی است…».
class ProductInfoSection extends StatelessWidget {
  const ProductInfoSection({super.key, required this.detail});

  final ProductDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ProductModel product = detail.product;
    final String? updatedAt = formatJalaliFromApi(product.priceUpdatedAt);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // در RTL «start» یعنی سمت راست
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── عنوان محصول ──
            Text(
              product.title,
              style: textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),

            // ── چیپ‌ها: برند / دسته‌بندی / موجودی ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                if (product.brand != null)
                  _InfoChip(
                    icon: Icons.sell_outlined,
                    label: 'برند: ${product.brand}',
                  ),
                if (detail.categoryName != null)
                  _InfoChip(
                    icon: Icons.category_outlined,
                    label: detail.categoryName!,
                  ),
                _StockChip(isAvailable: product.isAvailable),
              ],
            ),
            const SizedBox(height: 14),

            // ── قیمت تقریبی ──
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                product.price > 0
                    ? formatToman(product.price)
                    : 'قیمت توافقی',
                style: textTheme.titleLarge?.copyWith(
                  color: product.price > 0
                      ? AppColors.secondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),

            // ── تاریخ آخرین به‌روزرسانی (شمسی) ──
            if (updatedAt != null) ...<Widget>[
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'آخرین به‌روزرسانی قیمت: $updatedAt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            // ── باکس هشدار نارنجی ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: AppColors.accentDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'قیمت تقریبی است. لطفاً قبل از خرید حتماً از فروشنده '
                      'استعلام بگیرید.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w600,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// چیپ اطلاعات (برند / دسته‌بندی) با پس‌زمینه سرمه‌ای روشن.
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// چیپ وضعیت موجودی — سبز «موجود» / قرمز «ناموجود».
class _StockChip extends StatelessWidget {
  const _StockChip({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final Color color = isAvailable ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isAvailable
                ? Icons.check_circle_outline
                : Icons.do_not_disturb_on_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'موجود' : 'ناموجود',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
