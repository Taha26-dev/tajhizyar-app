import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/utils/json_utils.dart';

/// مدل اطلاعات فروشنده — از پاسخ `GET /api/seller/profile.php`.
///
/// شامل فیلدهای قابل ویرایش پروفایل: نام فروشگاه، توضیحات، شهر،
/// تلفن، واتساپ و لوگو.
///
/// ساختار دقیق پاسخ سرور ممکن است کمی متفاوت باشد (اطلاعات مستقیم
/// داخل ریشه یا زیر کلید `data` / `seller` / `user` / `profile`)؛
/// [SellerProfileModel.fromDecoded] ساختارهای رایج را پوشش می‌دهد.
class SellerProfileModel {
  const SellerProfileModel({
    this.name = '',
    this.description,
    this.phone,
    this.whatsapp,
    this.city,
    this.logoUrl,
  });

  /// نام فروشگاه / فروشنده (خالی = سرور نفرستاده)
  final String name;

  /// توضیحات فروشگاه
  final String? description;

  /// شماره تلفن
  final String? phone;

  /// شماره واتساپ
  final String? whatsapp;

  /// شهر
  final String? city;

  /// لوگوی فروشگاه (آدرس کامل و resolve شده)
  final String? logoUrl;

  /// آیا هیچ داده‌ای از سرور دریافت نشد؟ (پاسخ خالی/فقط پیام)
  bool get isEmpty =>
      name.isEmpty &&
      description == null &&
      phone == null &&
      whatsapp == null &&
      city == null &&
      logoUrl == null;

  /// ساخت مدل از پاسخ decode‌شده سرور — نبود فیلدها قابل تحمل است.
  factory SellerProfileModel.fromDecoded(Object? decoded) {
    Map<String, dynamic>? source;
    if (decoded is Map<String, dynamic>) {
      final Object? nested = decoded['data'] ??
          decoded['seller'] ??
          decoded['user'] ??
          decoded['profile'];
      source = nested is Map<String, dynamic> ? nested : decoded;
    }
    if (source == null) return const SellerProfileModel();

    return SellerProfileModel(
      name: jsonString(
        source['name'] ?? source['seller_name'] ?? source['store_name'],
      ),
      description: jsonStringOrNull(
        source['description'] ?? source['about'] ?? source['bio'],
      ),
      phone: jsonStringOrNull(source['phone'] ?? source['seller_phone']),
      whatsapp: jsonStringOrNull(
        source['whatsapp'] ?? source['seller_whatsapp'],
      ),
      city: jsonStringOrNull(source['city'] ?? source['seller_city']),
      logoUrl: ApiConstants.resolveUrl(
        jsonStringOrNull(
          source['logo_url'] ?? source['logo'] ?? source['image_url'],
        ),
      ),
    );
  }
}
