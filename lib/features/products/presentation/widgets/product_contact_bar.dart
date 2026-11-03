import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/widgets/contact_buttons_row.dart';
import 'package:tajhizyar/features/products/data/models/product_detail_model.dart';

/// نوار دکمه‌های تماس ثابت پایین صفحه جزئیات محصول.
///
/// چیدمان: حاشیه بالا + فاصله امن پایین + [ContactButtonsRow] مشترک
/// («تماس تلفنی» نارنجی و «واتساپ» سبز با پیام پیش‌پرشده محصول).
class ProductContactBar extends StatelessWidget {
  const ProductContactBar({super.key, required this.detail});

  final ProductDetailModel detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      // فاصله امن پایین برای دستگاه‌های ناچ‌دار
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: ContactButtonsRow(
        phone: detail.sellerPhone,
        whatsapp: detail.sellerWhatsapp,
        whatsappMessage: 'سلام، در مورد محصول «${detail.product.title}» '
            'در تجهیزیار سؤال داشتم.',
      ),
    );
  }
}
