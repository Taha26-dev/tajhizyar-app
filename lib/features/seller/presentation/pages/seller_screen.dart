import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/core/widgets/accent_section_title.dart';
import 'package:tajhizyar/core/widgets/empty_view.dart';
import 'package:tajhizyar/core/widgets/error_view.dart';
import 'package:tajhizyar/core/widgets/loading_view.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';
import 'package:tajhizyar/features/products/presentation/widgets/product_list_item.dart';
import 'package:tajhizyar/features/seller/data/models/seller_model.dart';
import 'package:tajhizyar/features/seller/data/seller_repository.dart';
import 'package:tajhizyar/features/seller/presentation/widgets/seller_header.dart';

/// صفحه فروشنده (پروفایل عمومی فروشگاه) — مسیر `/sellers/:sellerId`.
///
/// بخش‌ها:
///  ۱. هدر سرمه‌ای: لوگو، نام، شهر، نشان تأییدشده، توضیحات + دکمه‌های تماس
///  ۲. «محصولات این فروشنده»: لیست عمودی با آیتم مشترک [ProductListItem]
///     (کلیک روی هر محصول → صفحه جزئیات محصول)
///
/// حالت‌ها: Loading / Error (با تلاش مجدد) / Not Found /
/// Empty (فروشنده بدون محصول) / محتوا.
class SellerScreen extends StatefulWidget {
  const SellerScreen({super.key, required this.sellerId});

  /// شناسه فروشنده دریافتی از پارامتر مسیر (`:sellerId`)
  final String sellerId;

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  SellerRepository? _repository;
  late Future<SellerModel?> _sellerFuture;

  /// شناسه عددی فروشنده — اگر پارامتر مسیر عدد معتبر نباشد null است و
  /// به‌جای درخواست شبکه، مستقیماً حالت «یافت نشد» نمایش داده می‌شود.
  late final int? _parsedSellerId;

  @override
  void initState() {
    super.initState();
    _parsedSellerId = int.tryParse(widget.sellerId.trim());
    _sellerFuture = _loadSeller();
  }

  @override
  void dispose() {
    _repository?.dispose();
    super.dispose();
  }

  /// ساخت تنبل ریپازیتوری — فقط وقتی درخواست واقعی داریم ساخته می‌شود.
  SellerRepository get _repositoryLazy => _repository ??= SellerRepository();

  Future<SellerModel?> _loadSeller() {
    final int? id = _parsedSellerId;
    if (id == null) return Future<SellerModel?>.value(null);
    return _repositoryLazy.fetchSeller(id);
  }

  void _reload() {
    setState(() => _sellerFuture = _loadSeller());
  }

  // ─────────── UI ───────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar ساده با دکمه بازگشت (خودکار در سمت راست RTL)
      appBar: AppBar(title: const Text('فروشنده')),
      body: FutureBuilder<SellerModel?>(
        future: _sellerFuture,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<SellerModel?> snapshot,
            ) {
          // ── حالت بارگذاری ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(label: 'در حال دریافت اطلاعات فروشنده…');
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
          final SellerModel? seller = snapshot.data;
          if (seller == null) {
            return _SellerNotFoundView(
              onBrowse: () => context.go(AppRoutes.home),
            );
          }

          // ── محتوا ──
          return _buildContent(seller);
        },
      ),
    );
  }

  Widget _buildContent(SellerModel seller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ۱) هدر سرمه‌ای فروشنده
          SellerHeader(seller: seller),
          const SizedBox(height: 16),

          // ۲) سرتیتر بخش محصولات + شمارنده
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProductsSectionHeader(count: seller.products.length),
          ),
          const SizedBox(height: 8),

          // لیست محصولات (یا حالت خالی)
          if (seller.products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: EmptyView(
                  height: 180,
                  icon: Icons.storefront_outlined,
                  message: 'این فروشنده هنوز محصولی ثبت نکرده است.',
                ),
              ),
            )
          else
            ...<Widget>[
              for (final ProductModel product in seller.products)
                ProductListItem(
                  product: product,
                  onTap: () => context.push(
                    AppRoutes.productDetailPath('${product.id}'),
                  ),
                  onQuoteTap: () => _showQuoteSnackBar(product),
                ),
            ],
        ],
      ),
    );
  }

  /// اسنک‌بار استعلام قیمت — هماهنگ با صفحه لیست محصولات
  /// (پیاده‌سازی واقعی در فازهای بعد).
  void _showQuoteSnackBar(ProductModel product) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('استعلام قیمت «${product.title}» به‌زودی فعال می‌شود.'),
        ),
      );
  }
}

/// سرتیتر بخش محصولات با شمارنده فارسی.
class _ProductsSectionHeader extends StatelessWidget {
  const _ProductsSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: AccentSectionTitle(title: 'محصولات این فروشنده'),
        ),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${toPersianDigits(count.toString())} محصول',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accentDark,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
      ],
    );
  }
}

/// حالت «فروشنده یافت نشد» — پیام واضح + دکمه هدایت به صفحه اصلی.
class _SellerNotFoundView extends StatelessWidget {
  const _SellerNotFoundView({required this.onBrowse});

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
              Icons.storefront,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'فروشنده یافت نشد',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'این فروشنده حذف شده یا در دسترس نیست.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.home_outlined, size: 18),
              label: const Text('بازگشت به صفحه اصلی'),
            ),
          ],
        ),
      ),
    );
  }
}
