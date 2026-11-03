import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/widgets/contact_buttons_row.dart';
import 'package:tajhizyar/features/seller/data/models/seller_model.dart';

/// هدر سرمه‌ای صفحه فروشنده: لوگو/آیکون بزرگ، نام، شهر، نشان «تأییدشده»،
/// توضیحات کوتاه و دکمه‌های «تماس تلفنی» و «واتساپ».
///
/// گرادیان از راست (RTL) — هماهنگ با بنر صفحه اصلی.
class SellerHeader extends StatelessWidget {
  const SellerHeader({super.key, required this.seller});

  final SellerModel seller;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // در RTL گرادیان از راست به چپ کشیده می‌شود
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: <Color>[AppColors.primary, AppColors.primaryLight],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: <Widget>[
          _SellerAvatar(logoUrl: seller.logoUrl),
          const SizedBox(height: 14),

          // ── نام فروشنده ──
          Text(
            seller.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),

          // ── شهر + نشان تأییدشده ──
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 6,
            children: <Widget>[
              if (seller.city != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      seller.city!,
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              if (seller.isVerified)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'فروشنده تأییدشده',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── توضیحات کوتاه ──
          if (seller.description != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              seller.description!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                height: 1.8,
              ),
            ),
          ],
          const SizedBox(height: 18),

          // ── دکمه‌های تماس (مشترک با صفحه جزئیات محصول) ──
          ContactButtonsRow(
            phone: seller.phone,
            whatsapp: seller.whatsapp,
            whatsappMessage: 'سلام، از طریق اپ تجهیزیار پیام می‌دهم؛ '
                'در مورد محصولات «${seller.name}» سؤال داشتم.',
          ),
        ],
      ),
    );
  }
}

/// آواتار دایره‌ای بزرگ با حلقه سفید — لوگوی فروشگاه یا آیکون پیش‌فرض.
class _SellerAvatar extends StatelessWidget {
  const _SellerAvatar({required this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    const double size = 76;

    const Widget placeholder = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.storefront, size: 34, color: AppColors.primary),
      ),
    );

    return Container(
      // حلقه سفید دور آواتار
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white70, width: 2),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: logoUrl == null
              ? placeholder
              : Image.network(
                  logoUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? progress,
                  ) {
                    if (progress == null) return child;
                    return Container(
                      width: size,
                      height: size,
                      color: AppColors.background,
                      child: const Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
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
      ),
    );
  }
}
