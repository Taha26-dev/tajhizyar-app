import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/features/home/data/models/category_model.dart';
import 'package:tajhizyar/features/home/data/models/product_model.dart';

/// خطای سطح API با پیام قابل نمایش مستقیم به کاربر.
class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// منبع داده صفحه اصلی (دسته‌بندی‌ها و محصولات جدید).
class HomeRepository {
  HomeRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// `GET https://cr8v.ir/api/categories.php`
  Future<List<CategoryModel>> fetchCategories() async {
    final String body = await _get(ApiConstants.categoriesUri());
    return CategoryModel.listFromJson(body);
  }

  /// `GET https://cr8v.ir/api/products.php?limit={limit}`
  Future<List<ProductModel>> fetchNewProducts({
    int limit = 8,
    int? categoryId,
  }) async {
    final String body = await _get(
      ApiConstants.productsUri(limit: limit, categoryId: categoryId),
    );
    return ProductModel.listFromJson(body);
  }

  /// آزادسازی منابع کلاینت HTTP.
  void dispose() => _client.close();

  // ─────────── بخش داخلی ───────────

  /// اجرای درخواست GET با هدر JSON، timeout و مدیریت خطاها.
  /// بدنه پاسخ را با انکودینگ UTF-8 برمی‌گرداند (حیاتی برای متن فارسی).
  Future<String> _get(Uri uri) async {
    http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'زمان دریافت اطلاعات به پایان رسید؛ دوباره تلاش کنید.',
      );
    } on http.ClientException {
      throw const ApiException(
        'ارتباط با سرور برقرار نشد؛ اتصال اینترنت را بررسی کنید.',
      );
    }

    if (response.statusCode != 200) {
      throw ApiException('خطای سرور (کد ${response.statusCode})');
    }

    final String body = utf8.decode(response.bodyBytes);
    final Object? decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded['success'] == false) {
      final Object? message = decoded['message'];
      throw ApiException(
        message is String && message.trim().isNotEmpty
            ? message.trim()
            : 'دریافت اطلاعات از سرور ناموفق بود.',
      );
    }

    return body;
  }
}
