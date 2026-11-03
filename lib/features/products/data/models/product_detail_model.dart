import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/utils/json_utils.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';

/// مدل کامل جزئیات محصول — پاسخ `GET /api/product.php?id={id}`.
///
/// فیلدهای اصلی محصول در [product] (مدل مشترک [ProductModel]) نگهداری
/// می‌شوند و فیلدهای مخصوص صفحه جزئیات — توضیحات، همه تصاویر گالری و
/// اطلاعات کامل فروشنده — مستقیم همین کلاس هستند.
class ProductDetailModel {
  const ProductDetailModel({
    required this.product,
    this.description,
    this.imageUrls = const <String>[],
    this.sellerId,
    this.sellerLogoUrl,
    this.sellerPhone,
    this.sellerWhatsapp,
    this.sellerCity,
    this.sellerVerified = false,
    this.sellerDescription,
    this.categoryName,
  });

  /// فیلدهای اصلی محصول (عنوان، قیمت، برند، تصویر شاخص، ...)
  final ProductModel product;

  /// توضیحات کامل محصول
  final String? description;

  /// همه تصاویر محصول برای گالری (آدرس کامل و resolve شده)
  final List<String> imageUrls;

  /// شناسه فروشنده — برای ناوبری به صفحه فروشنده
  /// (اگر نامعتبر یا صفر باشد null است)
  final int? sellerId;

  /// لوگوی فروشنده (آدرس کامل)
  final String? sellerLogoUrl;

  /// شماره تماس فروشنده
  final String? sellerPhone;

  /// شماره واتساپ فروشنده (به همان شکلی که سرور فرستاده؛
  /// برای ساخت لینک wa.me از `normalizeWhatsappNumber` استفاده کنید)
  final String? sellerWhatsapp;

  /// شهر فروشنده
  final String? sellerCity;

  /// آیا فروشنده تأییدشده است؟ (`seller_verified`)
  final bool sellerVerified;

  /// معرفی کوتاه فروشنده
  final String? sellerDescription;

  /// نام دسته‌بندی محصول
  final String? categoryName;

  /// ساخت مدل از پاسخ از قبل decode‌شده API.
  ///
  /// اگر ساختار پاسخ معتبر نباشد یا سرور «محصول یافت نشد» برگرداند
  /// (`success == false` یا نبود `data` معتبر)، مقدار null برمی‌گردد
  /// تا صفحه جزئیات حالت Not Found نشان دهد.
  static ProductDetailModel? fromDecoded(Object? decoded) {
    if (decoded is! Map) return null;
    if (decoded['success'] == false) return null;
    final Object? data = decoded['data'];
    if (data is! Map || data.isEmpty) return null;
    return ProductDetailModel.fromJson(Map<String, dynamic>.from(data));
  }

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final int rawSellerId = jsonToInt(json['seller_id']);
    return ProductDetailModel(
      product: ProductModel.fromJson(json),
      description: jsonStringOrNull(json['description']),
      imageUrls: _resolveImageUrls(
        json['image_urls'] ?? json['images'] ?? json['gallery'],
      ),
      sellerId: rawSellerId > 0 ? rawSellerId : null,
      sellerLogoUrl: ApiConstants.resolveUrl(
        jsonStringOrNull(json['seller_logo'] ?? json['seller_logo_url']),
      ),
      sellerPhone: jsonStringOrNull(
        json['seller_phone'] ?? json['phone'],
      ),
      sellerWhatsapp: jsonStringOrNull(
        json['seller_whatsapp'] ?? json['whatsapp'],
      ),
      sellerCity: jsonStringOrNull(json['seller_city'] ?? json['city']),
      sellerVerified: jsonToBool(
        json['seller_verified'] ?? json['is_verified'],
      ),
      sellerDescription: jsonStringOrNull(json['seller_description']),
      categoryName: jsonStringOrNull(json['category_name']),
    );
  }

  /// تبدیل `image_urls` (آرایه یا رشته تکی) به فهرست آدرس‌های کامل.
  static List<String> _resolveImageUrls(Object? value) {
    final List<String> urls = <String>[];
    if (value is List) {
      for (final Object? item in value) {
        final String? resolved = ApiConstants.resolveUrl(item?.toString());
        if (resolved != null) urls.add(resolved);
      }
      return urls;
    }
    final String? resolved = ApiConstants.resolveUrl(jsonStringOrNull(value));
    if (resolved != null) urls.add(resolved);
    return urls;
  }
}
