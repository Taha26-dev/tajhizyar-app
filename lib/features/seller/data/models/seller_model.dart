import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/utils/json_utils.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';

/// مدل پروفایل فروشنده — پاسخ `GET /api/seller.php?id={id}`.
///
/// شامل اطلاعات فروشگاه (نام، لوگو، شهر، وضعیت تأیید، توضیحات، تماس)
/// و فهرست محصولات همین فروشنده (مدل مشترک [ProductModel]).
class SellerModel {
  const SellerModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
    this.phone,
    this.whatsapp,
    this.city,
    this.isVerified = false,
    this.products = const <ProductModel>[],
    this.productsCount = 0,
  });

  /// شناسه یکتای فروشنده
  final int id;

  /// نام فروشگاه / فروشنده
  final String name;

  /// لوگوی فروشگاه (آدرس کامل و resolve شده)
  final String? logoUrl;

  /// توضیحات کوتاه فروشنده
  final String? description;

  /// شماره تماس فروشنده
  final String? phone;

  /// شماره واتساپ فروشنده (خام — برای لینک از `normalizeWhatsappNumber`)
  final String? whatsapp;

  /// شهر فروشنده
  final String? city;

  /// آیا فروشنده تأییدشده است؟ (`is_verified`)
  final bool isVerified;

  /// محصولات فروشنده
  final List<ProductModel> products;

  /// تعداد محصولات اعلامی سرور (`products_count`) — برای نمایش ممکن است
  /// با طول [products] متفاوت باشد؛ نمایش بر اساس [products] است.
  final int productsCount;

  /// ساخت مدل از پاسخ از قبل decode‌شده API.
  ///
  /// اگر ساختار پاسخ معتبر نباشد یا سرور «فروشنده یافت نشد» برگرداند
  /// (`success == false` یا نبود `data` معتبر)، مقدار null برمی‌گردد
  /// تا صفحه فروشنده حالت Not Found نشان دهد.
  static SellerModel? fromDecoded(Object? decoded) {
    if (decoded is! Map) return null;
    if (decoded['success'] == false) return null;
    final Object? data = decoded['data'];
    if (data is! Map || data.isEmpty) return null;
    return SellerModel.fromJson(Map<String, dynamic>.from(data));
  }

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      id: jsonToInt(json['id'] ?? json['seller_id']),
      name: jsonString(
        json['name'] ?? json['title'] ?? json['seller_name'],
        'فروشنده',
      ),
      logoUrl: ApiConstants.resolveUrl(
        jsonStringOrNull(
          json['logo_url'] ?? json['logo'] ?? json['image_url'],
        ),
      ),
      description: jsonStringOrNull(
        json['description'] ?? json['seller_description'],
      ),
      phone: jsonStringOrNull(json['phone'] ?? json['seller_phone']),
      whatsapp: jsonStringOrNull(json['whatsapp'] ?? json['seller_whatsapp']),
      city: jsonStringOrNull(json['city'] ?? json['seller_city']),
      isVerified: jsonToBool(json['is_verified'] ?? json['seller_verified']),
      products: _productsFrom(json['products'] ?? json['items']),
      productsCount: jsonToInt(json['products_count']),
    );
  }

  /// تبدیل آرایه محصولات پاسخ فروشنده به فهرست مدل مشترک محصول.
  static List<ProductModel> _productsFrom(Object? value) {
    if (value is! List) return const <ProductModel>[];
    return <ProductModel>[
      for (final Object? item in value)
        if (item is Map) ProductModel.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}
