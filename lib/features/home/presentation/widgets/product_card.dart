import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';

/// کارت محصول در گرید صفحه اصلی.
///
/// شامل: تصویر (با placeholder)، عنوان (حداکثر ۲ خط)، نام فروشنده
/// و قیمت فرمت‌شده با ارقام فارسی.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: _buildImage()),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                // در RTL «start» یعنی سمت راست
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ── عنوان (حداکثر ۲ خط) ──
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // ── نام فروشنده ──
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.storefront,
                        size: 14,
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
                  const Spacer(),
                  // ── قیمت ──
                  Text(
                    product.price > 0
                        ? formatToman(product.price)
                        : 'قیمت توافقی',
                    style: textTheme.titleSmall?.copyWith(
                      color: product.price > 0
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

  /// تصویر محصول با placeholder هوشمند (حالت لودینگ / خطا / نبود تصویر).
  Widget _buildImage() {
    final Widget placeholder = Container(
      color: AppColors.primarySoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 32,
        color: AppColors.textSecondary,
      ),
    );

    final String? url = product.imageUrl;
    if (url == null) return placeholder;

    return Container(
      color: AppColors.background,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          );
        },
        errorBuilder: (_, Object __, StackTrace? ___) => placeholder,
      ),
    );
  }
}
