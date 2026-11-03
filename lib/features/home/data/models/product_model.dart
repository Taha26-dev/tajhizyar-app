import 'dart:convert';

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/utils/formatters.dart';
import 'package:tajhizyar/core/utils/json_utils.dart';

/// مدل محصول نمایش‌داده‌شده در صفحه اصلی.
class ProductModel {
  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.imageUrl,
    this.sellerName,
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

  /// نام فروشنده
  final String? sellerName;

  /// آیا محصول موجود است؟
  final bool isAvailable;

  /// تبدیل بدنه پاسخ API به فهرست مدل — مقاوم در برابر تغییر جزئی ساختار.
  static List<ProductModel> listFromJson(String body) {
    final List<dynamic> items = jsonExtractList(
      jsonDecode(body),
      const <String>['products', 'data', 'items', 'results'],
    );
    return <ProductModel>[
      for (final Object? item in items)
        if (item is Map) ProductModel.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: jsonToInt(json['id'] ?? json['product_id']),
        title: jsonString(json['title'] ?? json['name']),
        price: jsonToInt(
          json['price'] ?? json['final_price'] ?? json['amount'],
        ),
        imageUrl: _firstImageUrl(
          json['image_urls'] ??
              json['image'] ??
              json['image_url'] ??
              json['thumbnail'],
        ),
        sellerName: _sellerName(json),
        isAvailable: _asBool(json['is_available'] ?? json['available'] ?? true),
      );

  /// استخراج اولین تصویر معتبر — `image_urls` می‌تواند آرایه یا رشته باشد.
  static String? _firstImageUrl(Object? value) {
    if (value is List) {
      for (final Object? item in value) {
        final String? resolved = ApiConstants.resolveUrl(item?.toString());
        if (resolved != null) return resolved;
      }
      return null;
    }
    return ApiConstants.resolveUrl(jsonStringOrNull(value));
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

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final String v = normalizeDigits(value).trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes';
    }
    return true;
  }
}
