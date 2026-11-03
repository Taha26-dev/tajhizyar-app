import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/theme/app_theme.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';

/// کارت مدیریت محصول در پنل فروشنده — نمایش محصول خود فروشنده
/// به‌همراه دکمه‌های ویرایش و حذف.
///
/// تفاوت با [ProductListItem]: این کارت برای «مدیریت» است، نه خرید؛
/// پس به‌جای دکمه «استعلام قیمت»، وضعیت موجودی و اکشن‌های
/// ویرایش/حذف دارد.
class PanelProductCard extends StatelessWidget {
  const PanelProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final ProductModel product;

  /// کلیک روی کارت → مشاهده صفحه عمومی جزئیات محصول
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// در حال انجام عملیات حذف این آیتم → دکمه‌ها غیرفعال + اسپینر
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: isDeleting ? null : onTap,
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
                    const SizedBox(height: 6),
                    // ── قیمت ──
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        product.price > 0
                            ? formatToman(product.price)
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
                    const SizedBox(height: 8),
                    // ── وضعیت موجودی ──
                    _AvailabilityChip(isAvailable: product.isAvailable),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // ── اکشن‌های مدیریت ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    onPressed: isDeleting ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    color: AppColors.primary,
                    tooltip: 'ویرایش محصول',
                  ),
                  const SizedBox(height: 4),
                  isDeleting
                      ? const SizedBox(
                          width: 48,
                          height: 48,
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.error,
                            ),
                          ),
                        )
                      : IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: AppColors.error,
                          tooltip: 'حذف محصول',
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// تصویر مربعی ۷۶×۷۶ با placeholder هوشمند (لودینگ / خطا / نبود تصویر).
  Widget _buildImage() {
    final Widget placeholder = Container(
      width: 76,
      height: 76,
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
        width: 76,
        height: 76,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return Container(
              width: 76,
              height: 76,
              color: AppColors.background,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 16,
                height: 16,
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

/// چیپ وضعیت موجودی محصول — «موجود» سبز / «ناموجود» خاکستری-قرمز.
class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable
            ? AppColors.success.withValues(alpha: 0.10)
            : AppColors.border.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isAvailable ? Icons.check_circle_outline : Icons.do_not_disturb_on,
            size: 13,
            color: isAvailable ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isAvailable ? 'موجود' : 'ناموجود',
            style: textTheme.labelSmall?.copyWith(
              color:
                  isAvailable ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
