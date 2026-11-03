import 'dart:convert';

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/utils/json_utils.dart';

/// مدل محصول — در صفحه اصلی (کارت گرید) و صفحه لیست محصولات (آیتم افقی)
/// به‌صورت مشترک استفاده می‌شود.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
    this.imageUrls = const <String>[],
    this.sellerName,
    this.brand,
    this.priceUpdatedAt,
    this.categoryId,
    this.isAvailable = true,
  });

  /// شناسه یکتای محصول
  final int id;

  /// عنوان محصول
  final String title;

  /// قیمت به تومان — مقدار صفر یعنی «قیمت توافقی»
  final int price;

  /// تصویر شاخص محصول (اولین تصویر از `image_urls`)
  final String? imageUrl;

  /// همه تصاویر محصول — آدرس مطلق (resolve شده) به ترتیب آپلود.
  /// برای پیش‌نمایش تصاویر در فرم ویرایش پنل فروشنده استفاده می‌شود.
  final List<String> imageUrls;

  /// نام فروشنده
  final String? sellerName;

  /// برند محصول (مثل «بونش»)
  final String? brand;

  /// تاریخ آخرین به‌روزرسانی قیمت — رشته خام از API
  /// (مثل «2026-10-19 11:54:59»؛ نمایش شمسی با `formatJalaliFromApi`)
  final String? priceUpdatedAt;

  /// شناسه دسته‌بندی محصول
  final int? categoryId;

  /// آیا محصول موجود است؟
  final bool isAvailable;

  /// تبدیل بدنه پاسخ API به فهرست مدل.
  static List<ProductModel> listFromJson(String body) =>
      listFromDecoded(jsonDecode(body));

  /// تبدیل JSON از قبل decode‌شده به فهرست مدل
  /// (برای جلوگیری از decode دوباره در repository).
  static List<ProductModel> listFromDecoded(Object? decoded) {
    final List<dynamic> items = jsonExtractList(
      decoded,
      const <String>['products', 'data', 'items', 'results'],
    );
    return <ProductModel>[
      for (final Object? item in items)
        if (item is Map) ProductModel.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final List<String> images =
        _allImageUrls(json['image_urls'] ?? json['images']);
    return ProductModel(
      id: jsonToInt(json['id'] ?? json['product_id']),
      title: jsonString(json['title'] ?? json['name']),
      price: jsonToInt(
        json['price'] ?? json['final_price'] ?? json['amount'],
      ),
      imageUrl: images.isNotEmpty
          ? images.first
          : ApiConstants.resolveUrl(
              jsonStringOrNull(
                json['image'] ?? json['image_url'] ?? json['thumbnail'],
              ),
            ),
      imageUrls: images,
      sellerName: _sellerName(json),
      brand: jsonStringOrNull(json['brand']),
      priceUpdatedAt: jsonStringOrNull(
        json['price_updated_at'] ?? json['updated_at'],
      ),
      categoryId: json['category_id'] == null
          ? null
          : jsonToInt(json['category_id']),
      isAvailable: jsonToBool(
        json['is_available'] ?? json['available'],
        true,
      ),
    );
  }

  /// استخراج همه تصاویر معتبر — `image_urls` می‌تواند آرایه یا رشته باشد؛
  /// هر آدرس با [ApiConstants.resolveUrl] به آدرس مطلق تبدیل می‌شود.
  static List<String> _allImageUrls(Object? value) {
    if (value is! List) return const <String>[];
    final List<String> urls = <String>[];
    for (final Object? item in value) {
      final String? resolved = ApiConstants.resolveUrl(item?.toString());
      if (resolved != null) urls.add(resolved);
    }
    return urls;
  }

  /// استخراج نام فروشنده — `seller` ممکن است رشته یا آبجکت باشد.
  static String? _sellerName(Map<String, dynamic> json) {
    final Object? value =
        json['seller_name'] ?? json['seller'] ?? json['store_name'];
    if (value is Map) {
      return jsonStringOrNull(value['name'] ?? value['title']);
    }
    return jsonStringOrNull(value);
  }
}
