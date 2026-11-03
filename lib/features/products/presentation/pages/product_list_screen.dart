import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tajhizyar/core/constants/app_routes.dart';
import 'package:tajhizyar/core/constants/error_messages.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/widgets/empty_view.dart';
import 'package:tajhizyar/core/widgets/error_view.dart';
import 'package:tajhizyar/core/widgets/loading_view.dart';
import 'package:tajhizyar/features/products/data/models/category_model.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';
import 'package:tajhizyar/features/products/data/products_repository.dart';
import 'package:tajhizyar/features/products/presentation/widgets/product_list_item.dart';
import 'package:tajhizyar/features/products/presentation/widgets/product_list_promo_banner.dart';

/// صفحه لیست محصولات.
///
/// دو حالت ورودی دارد:
///  ۱. از دسته‌بندی: [categoryId] (عنوان = نام دسته)
///  ۲. از جستجو: [initialSearch] (عنوان = «نتایج جستجو»)
///
/// امکانات: نوار جستجوی زنده (تغییر متن با debounce + دکمه جستجو)،
/// صفحه‌بندی (اسکرول بی‌نهایت + دکمه «بارگذاری بیشتر»)، بنر تبلیغاتی
/// بعد از هر ۵ محصول، Pull-to-Refresh و حالت‌های Loading / Error / Empty.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, this.categoryId, this.initialSearch});

  /// شناسه دسته‌بندی (null یعنی همه محصولات)
  final int? categoryId;

  /// عبارت جستجوی اولیه (از مسیر `?search=`)
  final String? initialSearch;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  /// تعداد آیتم هر صفحه از API
  static const int _pageLimit = 10;

  /// فاصله نمایش بنر تبلیغاتی (بعد از هر ۵ محصول)
  static const int _bannerInterval = 5;

  final ProductsRepository _repository = ProductsRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  List<ProductModel> _products = <ProductModel>[];
  int _page = 1;
  bool _hasMore = false;

  bool _isInitialLoading = true;
  String? _errorMessage;
  bool _isLoadingMore = false;
  bool _loadMoreError = false;

  /// عبارت جستجوی «ثبت‌شده» که درخواست‌ها با آن اجرا می‌شوند
  String _activeSearch = '';

  /// نام دسته‌بندی (برای عنوان، در صورت ورود از دسته‌بندی)
  String? _categoryName;

  @override
  void initState() {
    super.initState();
    _activeSearch = (widget.initialSearch ?? '').trim();
    _searchController.text = _activeSearch;
    _searchController.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
    _reload();
    _loadCategoryName();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // لایه محافظ: اگر فیلتر دسته‌بندی یا جستجوی ورودی عوض شود (مثلاً با
    // تغییر query مسیر)، صفحه برای فیلتر جدید بازنشانی و دوباره بارگذاری
    // می‌شود — حتی اگر State صفحه به‌هر دلیلی بین ناوبری‌ها حفظ شده باشد.
    final String incomingSearch = (widget.initialSearch ?? '').trim();
    final bool paramsChanged = widget.categoryId != oldWidget.categoryId ||
        incomingSearch != (oldWidget.initialSearch ?? '').trim();
    if (!paramsChanged) return;

    _activeSearch = incomingSearch;
    _searchController.text = _activeSearch;
    _categoryName = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _reload();
    _loadCategoryName();
  }

  // ─────────── بارگذاری داده‌ها ───────────

  /// بارگذاری صفحه اول (اولین ورود، جستجو و Pull-to-Refresh)
  Future<void> _reload() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _loadMoreError = false;
    });
    try {
      final ProductsPage result = await _repository.fetchProducts(
        categoryId: widget.categoryId,
        search: _activeSearch.isEmpty ? null : _activeSearch,
        page: 1,
        limit: _pageLimit,
      );
      if (!mounted) return;
      setState(() {
        _products = result.items;
        _hasMore = result.hasMore;
        _page = 1;
        _isInitialLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        // پیام استاندارد فارسی از لایه شبکه (قطع اینترنت / خطای سرور / ...)
        _errorMessage = e.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _errorMessage = ErrorMessages.unknown;
      });
    }
  }

  /// بارگذاری صفحه بعدی (اسکرول به انتها یا دکمه «بارگذاری بیشتر»)
  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _isInitialLoading) return;
    setState(() {
      _isLoadingMore = true;
      _loadMoreError = false;
    });
    try {
      final ProductsPage result = await _repository.fetchProducts(
        categoryId: widget.categoryId,
        search: _activeSearch.isEmpty ? null : _activeSearch,
        page: _page + 1,
        limit: _pageLimit,
      );
      if (!mounted) return;
      setState(() {
        // جلوگیری از تکرار آیتم در صورت رفتار ناسازگار سرور
        final Set<int> existingIds =
            _products.map((ProductModel p) => p.id).toSet();
        final List<ProductModel> newItems = result.items
            .where((ProductModel p) => !existingIds.contains(p.id))
            .toList();
        _products.addAll(newItems);
        _page += 1;
        _hasMore = result.hasMore && newItems.isNotEmpty;
        _isLoadingMore = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = true;
      });
    }
  }

  /// دریافت نام دسته‌بندی برای عنوان صفحه (در صورت ورود از دسته‌بندی).
  /// در صورت خطا، عنوان پیش‌فرض «محصولات» باقی می‌ماند.
  Future<void> _loadCategoryName() async {
    if (widget.categoryId == null) return;
    try {
      final List<CategoryModel> categories =
          await _repository.fetchCategories();
      CategoryModel? match;
      for (final CategoryModel category in categories) {
        if (category.id == widget.categoryId) {
          match = category;
          break;
        }
      }
      if (match != null && mounted) {
        final String name = match.name;
        setState(() => _categoryName = name);
      }
    } on Object {
      // خطای غیرحیاتی است — عنوان پیش‌فرض کافی است
    }
  }

  // ─────────── جستجو ───────────

  /// فقط برای نمایش/مخفی کردن دکمه پاک کردن (rebuild سبک روی هر کلید)
  void _onSearchTextChanged() {
    if (mounted) setState(() {});
  }

  /// تغییر متن → جستجو با تاخیر ۵۰۰ میلی‌ثانیه (debounce)
  void _onSearchQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _applySearch(value);
    });
  }

  /// اجرای جستجو (از debounce، دکمه جستجوی کیبورد یا پاک کردن)
  void _applySearch(String value) {
    final String term = value.trim();
    if (term == _activeSearch) return;
    setState(() => _activeSearch = term);
    _reload();
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _applySearch('');
  }

  /// اسکرول بی‌نهایت: نزدیک به انتها → بارگذاری صفحه بعد
  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      _loadMore();
    }
  }

  // ─────────── UI ───────────

  String get _appBarTitle {
    if (widget.categoryId != null) {
      return _categoryName ?? 'محصولات';
    }
    if (_activeSearch.isNotEmpty) {
      return 'نتایج جستجو';
    }
    return 'همه محصولات';
  }

  String _emptyMessage() {
    if (_activeSearch.isNotEmpty) {
      return 'محصولی برای «$_activeSearch» یافت نشد.';
    }
    if (widget.categoryId != null) {
      return 'محصولی در این دسته‌بندی یافت نشد.';
    }
    return 'محصولی برای نمایش وجود ندارد.';
  }

  void _showFilterSoon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('فیلترهای پیشرفته به‌زودی اضافه می‌شوند')),
      );
  }

  void _showQuoteSnackBar(ProductModel product) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('استعلام قیمت «${product.title}» به‌زودی فعال می‌شود.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: <Widget>[
          // فعلاً فقط ظاهر دارد — TODO: شیت فیلتر (قیمت، شهر، ...)
          IconButton(
            tooltip: 'فیلترها',
            onPressed: _showFilterSoon,
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: <Widget>[
          _buildSearchField(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: _applySearch,
        onChanged: _onSearchQueryChanged,
        decoration: InputDecoration(
          hintText: 'جستجو در محصولات...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'پاک کردن',
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close, size: 20),
                ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const LoadingView(label: 'در حال دریافت محصولات...');
    }
    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage, onRetry: _reload);
    }
    if (_products.isEmpty) {
      return EmptyView(
        message: _emptyMessage(),
        icon: _activeSearch.isNotEmpty
            ? Icons.search_off
            : Icons.inventory_2_outlined,
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: _reload,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < _products.length; i++) {
      final ProductModel product = _products[i];
      rows.add(ProductListItem(
        product: product,
        onTap: () =>
            context.push(AppRoutes.productDetailPath('${product.id}')),
        onQuoteTap: () => _showQuoteSnackBar(product),
      ));
      // بنر تبلیغاتی بعد از هر ۵ محصول (به‌جز انتهای مطلق لیست)
      if ((i + 1) % _bannerInterval == 0 && i + 1 < _products.length) {
        rows.add(ProductListPromoBanner(
          // بازگشت به لیست بدون فیلتر (همان تب — بدون افزودن لایه جدید)
          onTap: () => context.go(AppRoutes.productList),
        ));
      }
    }
    rows.add(_buildListFooter());

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: rows,
    );
  }

  Widget _buildListFooter() {
    if (_loadMoreError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('خطا در بارگذاری — تلاش مجدد'),
          ),
        ),
      );
    }
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.expand_more, size: 18),
            label: const Text('بارگذاری بیشتر'),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '— پایان لیست —',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
