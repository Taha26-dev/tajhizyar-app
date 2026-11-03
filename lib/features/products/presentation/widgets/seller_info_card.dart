import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/theme/app_theme.dart';
import 'package:tajhizyar/core/widgets/accent_section_title.dart';
import 'package:tajhizyar/features/products/data/models/product_detail_model.dart';

/// کارت اطلاعات فروشنده در صفحه جزئیات محصول: لوگو/آیکون، نام، شهر و
/// نشان «تأییدشده» — با کلیک به صفحه فروشنده (SellerScreen) می‌رود.
///
/// اگر فروشنده‌ای ثبت نشده باشد، کارت کاملاً حذف می‌شود؛ اگر نام باشد ولی
/// شناسه نباشد، کارت نمایش داده می‌شود اما قابل کلیک نیست.
class SellerInfoCard extends StatelessWidget {
  const SellerInfoCard({super.key, required this.detail});

  final ProductDetailModel detail;

  /// آیا اطلاعات فروشنده‌ای برای نمایش وجود دارد؟
  bool get _hasSeller =>
      detail.product.sellerName != null || detail.sellerId != null;

  /// آیا کارت به صفحه فروشنده لینک می‌شود؟
  bool get _tappable => detail.sellerId != null;

  void _openSellerPage(BuildContext context) {
    final int? sellerId = detail.sellerId;
    if (sellerId == null) return;
    context.push(AppRoutes.sellerPath(sellerId.toString()));
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSeller) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: _tappable ? () => _openSellerPage(context) : null,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AccentSectionTitle(title: 'اطلاعات فروشنده'),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  _SellerAvatar(logoUrl: detail.sellerLogoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // ── نام فروشنده ──
                        Text(
                          detail.product.sellerName ?? 'فروشنده نامشخص',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        // ── شهر ──
                        if (detail.sellerCity != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  detail.sellerCity!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        // ── نشان تأییدشده ──
                        if (detail.sellerVerified) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'فروشنده تأییدشده',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // در RTL آخرین فرزندِ Row سمت چپ است — فلش «ادامه»
                  if (_tappable)
                    const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// آواتار دایره‌ای فروشنده — لوگو یا آیکون پیش‌فرض فروشگاه.
class _SellerAvatar extends StatelessWidget {
  const _SellerAvatar({required this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    const Widget placeholder = SizedBox(
      width: 52,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.storefront, color: AppColors.primary),
      ),
    );

    final String? url = logoUrl;
    if (url == null) return placeholder;

    return ClipOval(
      child: SizedBox(
        width: 52,
        height: 52,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder:
              (BuildContext context, Widget child, ImageChunkEvent? progress) {
            if (progress == null) return child;
            return Container(
              width: 52,
              height: 52,
              color: AppColors.background,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
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
