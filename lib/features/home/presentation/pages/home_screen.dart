import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/widgets/empty_view.dart';
import 'package:tajhizyar/core/widgets/error_view.dart';
import 'package:tajhizyar/core/widgets/loading_view.dart';
import 'package:tajhizyar/features/products/data/models/category_model.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';
import 'package:tajhizyar/features/products/data/products_repository.dart';
import 'package:tajhizyar/features/home/presentation/widgets/category_strip.dart';
import 'package:tajhizyar/features/home/presentation/widgets/home_app_bar.dart';
import 'package:tajhizyar/features/home/presentation/widgets/product_card.dart';
import 'package:tajhizyar/features/home/presentation/widgets/promo_banner.dart';
import 'package:tajhizyar/features/home/presentation/widgets/section_header.dart';
import 'package:tajhizyar/features/home/presentation/widgets/why_tajhizyar_section.dart';

/// صفحه اصلی اپلیکیشن «تجهیزیار».
///
/// ساختار (از بالا به پایین):
///  ۱. دسته‌بندی‌ها — نوار افقی، داده از `GET /api/categories.php`
///  ۲. بنر تبلیغاتی «پیشنهاد ویژه این هفته» (استاتیک فعلاً)
///  ۳. بخش اعتمادسازی «چرا تجهیزیار؟» — سه مزیت کلیدی
///  ۴. محصولات جدید — گرید ۲ ستونه، داده از `GET /api/products.php?limit=12`
///
/// هر بخش دارای حالت‌های Loading / Error (با تلاش مجدد) / Empty است و
/// صفحه با Pull-to-Refresh قابل به‌روزرسانی است.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// تعداد محصولات جدید نمایش‌داده‌شده در صفحه اصلی
  static const int _productsLimit = 12;

  final ProductsRepository _repository = ProductsRepository();

  late Future<List<CategoryModel>> _categoriesFuture;
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  /// بارگذاری مجدد هر دو بخش (اولین لود و Pull-to-Refresh)
  void _reloadAll() {
    _categoriesFuture = _repository.fetchCategories();
    _productsFuture = _repository
        .fetchProducts(limit: _productsLimit)
        .then((ProductsPage page) => page.items);
  }

  /// تازه‌سازی کامل با کشیدن صفحه به پایین
  Future<void> _refresh() async {
    final Future<List<CategoryModel>> categories =
        _repository.fetchCategories();
    final Future<List<ProductModel>> products = _repository
        .fetchProducts(limit: _productsLimit)
        .then((ProductsPage page) => page.items);
    setState(() {
      _categoriesFuture = categories;
      _productsFuture = products;
    });
    // خطاها در FutureBuilder هر بخش مدیریت می‌شوند؛ اینجا فقط اتمام را منتظر می‌مانیم
    await Future.wait(<Future<void>>[
      categories.then<void>((List<CategoryModel> _) {}, onError: (Object _) {}),
      products.then<void>((List<ProductModel> _) {}, onError: (Object _) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(
        onSearchTap: () => context.go(AppRoutes.productList),
        onSellerPanelTap: () => context.go(AppRoutes.sellerPanel),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildCategoriesSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: PromoBanner(
                onTap: () => context.go(AppRoutes.productList),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── بخش اعتمادسازی «چرا تجهیزیار؟» ──
            const SliverToBoxAdapter(child: WhyTajhizyarSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'محصولات جدید',
                onViewAll: () => context.go(AppRoutes.productList),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildProductsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ─────────── بخش دسته‌بندی‌ها ───────────

  Widget _buildCategoriesSection() {
    return FutureBuilder<List<CategoryModel>>(
      future: _categoriesFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<CategoryModel>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(height: 96);
        }
        if (snapshot.hasError) {
          // پیام استاندارد فارسی (قطع اینترنت / خطای سرور / ...) از لایه شبکه
          return ErrorView(
            message: apiErrorMessage(snapshot.error),
            height: 96,
            onRetry: () => setState(() {
              _categoriesFuture = _repository.fetchCategories();
            }),
          );
        }
        final List<CategoryModel> categories =
            snapshot.data ?? <CategoryModel>[];
        if (categories.isEmpty) {
          return const EmptyView(
            message: 'دسته‌بندی‌ای یافت نشد.',
            height: 96,
            icon: Icons.category_outlined,
          );
        }
        return CategoryStrip(categories: categories);
      },
    );
  }

  // ─────────── بخش محصولات جدید ───────────

  Widget _buildProductsSection() {
    return FutureBuilder<List<ProductModel>>(
      future: _productsFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<ProductModel>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingView(height: 320, label: 'در حال دریافت محصولات...');
        }
        if (snapshot.hasError) {
          // پیام استاندارد فارسی (قطع اینترنت / خطای سرور / ...) از لایه شبکه
          return ErrorView(
            message: apiErrorMessage(snapshot.error),
            height: 220,
            onRetry: () => setState(() {
              _productsFuture = _repository
                  .fetchProducts(limit: _productsLimit)
                  .then((ProductsPage page) => page.items);
            }),
          );
        }
        final List<ProductModel> products = snapshot.data ?? <ProductModel>[];
        if (products.isEmpty) {
          return const EmptyView(
            message: 'محصولی برای نمایش وجود ندارد.',
            height: 180,
          );
        }
        return _buildProductsGrid(products);
      },
    );
  }

  Widget _buildProductsGrid(List<ProductModel> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        final ProductModel product = products[index];
        return ProductCard(
          product: product,
          onTap: () =>
              context.push(AppRoutes.productDetailPath('${product.id}')),
        );
      },
    );
  }
}
