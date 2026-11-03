import 'package:http/http.dart' as http;

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/network/api_client.dart';
import 'package:tajhizyar/features/products/data/models/category_model.dart';
import 'package:tajhizyar/features/products/data/models/product_detail_model.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';

/// نتیجه یک صفحه از لیست محصولات (برای صفحه‌بندی).
class ProductsPage {
  const ProductsPage({required this.items, required this.hasMore});

  /// آیتم‌های همین صفحه
  final List<ProductModel> items;

  /// آیا احتمالاً صفحه بعدی وجود دارد؟
  /// (سرور فیلد total ندارد؛ پس ملاک، پر بودن صفحه فعلی است)
  final bool hasMore;
}

/// منبع داده محصولات و دسته‌بندی‌ها — مشترک بین صفحات اصلی، لیست و جزئیات.
class ProductsRepository {
  ProductsRepository({http.Client? client}) : _api = ApiClient(client: client);

  final ApiClient _api;

  /// `GET https://cr8v.ir/api/categories.php`
  Future<List<CategoryModel>> fetchCategories() async {
    final Object? decoded = await _api.getJson(ApiConstants.categoriesUri());
    return CategoryModel.listFromDecoded(decoded);
  }

  /// `GET https://cr8v.ir/api/products.php` — یک صفحه از محصولات
  /// با فیلترهای اختیاری دسته‌بندی و جستجو.
  ///
  /// [page] از ۱ شروع می‌شود و [limit] تعداد آیتم هر صفحه است.
  Future<ProductsPage> fetchProducts({
    int? categoryId,
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    final Object? decoded = await _api.getJson(
      ApiConstants.productsUri(
        limit: limit,
        categoryId: categoryId,
        page: page,
        search: search,
      ),
    );
    final List<ProductModel> items = ProductModel.listFromDecoded(decoded);
    return ProductsPage(
      items: items,
      hasMore: items.length == limit,
    );
  }

  /// `GET https://cr8v.ir/api/product.php?id={id}` — جزئیات کامل محصول.
  ///
  /// اگر محصول وجود نداشته باشد (`success == false` از سمت سرور)،
  /// null برمی‌گردد تا صفحه جزئیات حالت «یافت نشد» نشان دهد؛
  /// خطاهای شبکه/سرور به‌صورت [ApiException] پرتاب می‌شوند.
  Future<ProductDetailModel?> fetchProductDetail(int productId) async {
    final Object? decoded = await _api.getJson(
      ApiConstants.productUri(productId),
      allowFailure: true,
    );
    return ProductDetailModel.fromDecoded(decoded);
  }

  /// آزادسازی منابع کلاینت HTTP.
  void dispose() => _api.dispose();
}
