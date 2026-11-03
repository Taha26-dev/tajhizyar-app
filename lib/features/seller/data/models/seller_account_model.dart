import 'dart:convert';

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/utils/json_utils.dart';

/// مدل حساب فروشنده لاگین‌شده — از پاسخ موفق `POST /api/seller/login.php`.
///
/// ساختار دقیق پاسخ سرور ممکن است کمی متفاوت باشد (اطلاعات فروشنده
/// مستقیم داخل `data` یا زیر کلید `seller` / `user`)؛ این مدل
/// ساختارهای رایج را پوشش می‌دهد و برای ذخیره در `shared_preferences`
/// متدهای [toJson] / [fromJsonString] دارد.
class SellerAccountModel {
  const SellerAccountModel({
    required this.id,
    required this.name,
    this.username,
    this.logoUrl,
    this.city,
    this.phone,
    this.whatsapp,
    this.isVerified = false,
  });

  /// شناسه یکتای فروشنده
  final int id;

  /// نام فروشگاه / فروشنده
  final String name;

  /// نام کاربری ورود
  final String? username;

  /// لوگوی فروشگاه (آدرس کامل و resolve شده)
  final String? logoUrl;

  /// شهر فروشنده
  final String? city;

  /// شماره تماس فروشنده
  final String? phone;

  /// شماره واتساپ فروشنده (خام)
  final String? whatsapp;

  /// آیا فروشنده تأییدشده است؟
  final bool isVerified;

  /// ساخت مدل از یک Map اطلاعات فروشنده — نبود فیلدها قابل تحمل است
  /// (فقط «نام» اهمیت دارد و با fallback پر می‌شود).
  factory SellerAccountModel.fromJson(Map<String, dynamic> json) {
    return SellerAccountModel(
      id: jsonToInt(json['id'] ?? json['seller_id']),
      name: jsonString(
        json['name'] ??
            json['seller_name'] ??
            json['store_name'] ??
            json['title'],
        'فروشنده',
      ),
      username: jsonStringOrNull(json['username']),
      logoUrl: ApiConstants.resolveUrl(
        jsonStringOrNull(
          json['logo_url'] ?? json['logo'] ?? json['image_url'],
        ),
      ),
      city: jsonStringOrNull(json['city'] ?? json['seller_city']),
      phone: jsonStringOrNull(json['phone'] ?? json['seller_phone']),
      whatsapp: jsonStringOrNull(json['whatsapp'] ?? json['seller_whatsapp']),
      isVerified: jsonToBool(json['is_verified'] ?? json['seller_verified']),
    );
  }

  // ─────────── سریال‌سازی برای shared_preferences ───────────

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'username': username,
        'logo_url': logoUrl,
        'city': city,
        'phone': phone,
        'whatsapp': whatsapp,
        'is_verified': isVerified,
      };

  /// بازخوانی مدل از رشته JSON ذخیره‌شده — داده خراب → نسخه حداقلی.
  factory SellerAccountModel.fromJsonString(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return SellerAccountModel.fromJson(decoded);
      }
    } on FormatException {
      // داده ذخیره‌شده خراب است → نسخه حداقلی برمی‌گردد.
    }
    return const SellerAccountModel(id: 0, name: 'فروشنده');
  }
}
