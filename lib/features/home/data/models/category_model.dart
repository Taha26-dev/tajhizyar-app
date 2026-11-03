import 'dart:convert';

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/utils/json_utils.dart';

/// مدل دسته‌بندی محصولات.
class CategoryModel {
  const CategoryModel({required this.id, required this.name, this.iconUrl});

  /// شناسه یکتای دسته‌بندی
  final int id;

  /// نام دسته‌بندی
  final String name;

  /// آدرس آیکون دسته‌بندی (در صورت ارائه توسط سرور)
  final String? iconUrl;

  /// تبدیل بدنه پاسخ API به فهرست مدل — مقاوم در برابر تغییر جزئی ساختار.
  static List<CategoryModel> listFromJson(String body) {
    final List<dynamic> items = jsonExtractList(
      jsonDecode(body),
      const <String>['categories', 'data', 'items', 'results'],
    );
    return <CategoryModel>[
      for (final Object? item in items)
        if (item is Map) CategoryModel.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: jsonToInt(json['id'] ?? json['category_id']),
        name: jsonString(json['name'] ?? json['title']),
        iconUrl: ApiConstants.resolveUrl(
          jsonStringOrNull(
            json['icon_url'] ?? json['icon'] ?? json['image_url'],
          ),
        ),
      );
}
