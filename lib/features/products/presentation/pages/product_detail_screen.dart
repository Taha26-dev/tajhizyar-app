import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/widgets/error_view.dart';
import 'package:tajhizyar/core/widgets/loading_view.dart';
import 'package:tajhizyar/features/products/data/models/product_detail_model.dart';
import 'package:tajhizyar/features/products/data/products_repository.dart';
import 'package:tajhizyar/features/products/presentation/widgets/product_contact_bar.dart';
import 'package:tajhizyar/features/products/presentation/widgets/product_description_section.dart';
import 'package:tajhizyar/features/products/presentation/widgets/product_image_gallery.dart';
import 'package:tajhizyar/features/products/presentation/widgets/product_info_section.dart';
import 'package:tajhizyar/features/products/presentation/widgets/seller_info_card.dart';

/// صفحه جزئیات محصول — مسیر `/products/:productId`.
///
/// بخش‌ها (از بالا به پایین):
///  ۱. گالری تصاویر با نشانگر نقطه‌ای
///  ۲. اطلاعات اصلی: عنوان، برند، قیمت تقریبی + تاریخ شمسی، باکس هشدار
///  ۳. توضیحات محصول
///  ۴. کارت اطلاعات فروشنده (کلیک → صفحه فروشنده)
///  ۵. نوار ثابت دکمه‌های «تماس تلفنی» و «واتساپ» (url_launcher)
///
/// حالت‌ها: Loading / Error (با تلاش مجدد) / Not Found / محتوا.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  /// شناسه محصول دریافتی از پارامتر مسیر (`:productId`)
  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductsRepository? _repository;
  late Future<ProductDetailModel?> _detailFuture;

  /// شناسه عددی محصول — اگر پارامتر مسیر عدد معتبر نباشد null است و
  /// به‌جای درخواست شبکه، مستقیماً حالت «یافت نشد» نمایش داده می‌شود.
  late final int? _parsedProductId;

  @override
  void initState() {
    super.initState();
    _parsedProductId = int.tryParse(widget.productId.trim());
    _detailFuture = _loadDetail();
  }

  @override
  void dispose() {
    _repository?.dispose();
    super.dispose();
  }

  /// ساخت تنبل ریپازیتوری — فقط وقتی درخواست واقعی داریم ساخته می‌شود.
  ProductsRepository get _repositoryLazy =>
      _repository ??= ProductsRepository();

  Future<ProductDetailModel?> _loadDetail() {
    final int? id = _parsedProductId;
    if (id == null) return Future<ProductDetailModel?>.value(null);
    return _repositoryLazy.fetchProductDetail(id);
  }

  void _reload() {
    setState(() => _detailFuture = _loadDetail());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar ساده با دکمه بازگشت (خودکار در سمت راست RTL)
      appBar: AppBar(title: const Text('جزئیات محصول')),
      body: FutureBuilder<ProductDetailModel?>(
        future: _detailFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<ProductDetailModel?> snapshot,
            ) {
          // ── حالت بارگذاری ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'در حال دریافت اطلاعات محصول…');
          }

          // ── حالت خطا (شبکه / سرور) با تلاش مجدد ──
          if (snapshot.hasError) {
            final Object? error = snapshot.error;
            // پیام استاندارد فارسی از لایه شبکه (قطع اینترنت / خطای سرور / ...)
            return ErrorView(
              message: apiErrorMessage(error),
              onRetry: _reload,
            );
          }

          // ── حالت یافت نشد (success == false یا شناسه نامعتبر) ──
          final ProductDetailModel? detail = snapshot.data;
          if (detail == null) {
            return _ProductNotFoundView(
              onBrowse: () =>
                  context.push(AppRoutes.productListPath()),
            );
          }

          // ── محتوا ──
          return _buildContent(detail);
        },
      ),
    );
  }

  Widget _buildContent(ProductDetailModel detail) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // ۱) گالری تصاویر (تمام‌عرض)
                ProductImageGallery(imageUrls: detail.imageUrls),
                const SizedBox(height: 12),

                // ۲ تا ۴) بخش‌های کارتی با فاصله افقی استاندارد
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      ProductInfoSection(detail: detail),
                      const SizedBox(height: 12),
                      ProductDescriptionSection(
                        description: detail.description,
                      ),
                      const SizedBox(height: 12),
                      SellerInfoCard(detail: detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ۵) نوار ثابت دکمه‌های تماس — همیشه پایین صفحه
        ProductContactBar(detail: detail),
      ],
    );
  }
}

/// حالت «محصول یافت نشد» — پیام واضح + دکمه هدایت به لیست محصولات.
class _ProductNotFoundView extends StatelessWidget {
  const _ProductNotFoundView({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'محصول یافت نشد',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'این محصول حذف شده یا در دسترس نیست؛\nمی‌توانید محصولات مشابه را ببینید.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.storefront, size: 18),
              label: const Text('مشاهده همه محصولات'),
            ),
          ],
        ),
      ),
    );
  }
}
