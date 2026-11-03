import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/theme/app_theme.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/core/utils/jalali_date.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';

/// آیتم افقی محصول در لیست عمودی — قابل استفاده مجدد.
///
/// چیدمان (RTL): تصویر سمت راست، اطلاعات در ادامه؛ شامل عنوان، برند،
/// قیمت تقریبی + تاریخ به‌روزرسانی (شمسی)، نام فروشنده و دکمه «استعلام قیمت».
class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.onQuoteTap,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onQuoteTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? updatedAt = formatJalaliFromApi(product.priceUpdatedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildImage(), // در RTL اولین فرزندِ Row سمت راست است
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  // در RTL «start» یعنی سمت راست
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── عنوان ──
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    // ── برند ──
                    if (product.brand != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.sell_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'برند: ${product.brand}',
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
                    const SizedBox(height: 4),
                    // ── قیمت تقریبی ──
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        product.price > 0
                            ? 'قیمت تقریبی: ${formatToman(product.price)}'
                            : 'قیمت توافقی',
                        style: textTheme.titleSmall?.copyWith(
                          color: product.price > 0
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // ── تاریخ به‌روزرسانی (شمسی) ──
                    if (updatedAt != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.history_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '(به‌روزرسانی: $updatedAt)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    // ── فروشنده ──
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.storefront,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.sellerName ?? 'فروشنده نامشخص',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // ── دکمه استعلام قیمت ──
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: onQuoteTap,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          textStyle: textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.receipt_long_outlined, size: 16),
                        label: const Text('استعلام قیمت'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تصویر مربعی ۹۲×۹۲ با placeholder هوشمند (لودینگ / خطا / نبود تصویر).
  Widget _buildImage() {
    final Widget placeholder = Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
    );

    final String? url = product.imageUrl;
    if (url == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 92,
        height: 92,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return Container(
              width: 92,
              height: 92,
              color: AppColors.background,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            );
          },
          errorBuilder: (_, Object __, StackTrace? ___) => placeholder,
        ),
      ),
    );
  }
}
