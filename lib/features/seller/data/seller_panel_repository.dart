import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/network/api_client.dart';
import 'package:tajhizyar/core/network/api_exception.dart';
import 'package:tajhizyar/features/products/data/models/product_model.dart';
import 'package:tajhizyar/features/seller/data/models/seller_profile_model.dart';

/// ریپازیتوری پنل فروشنده — عملیات نیازمند توکن:
/// فهرست محصولات خودم، حذف محصول، افزودن و ویرایش محصول،
/// آپلود تصویر محصول، و دریافت/ویرایش اطلاعات فروشگاه.
///
/// همه متدها `Authorization: Bearer {token}` را از طریق [ApiClient]
/// ضمیمه می‌کنند. خطای 401 (انقضای نشست) به‌صورت [ApiException] با
/// `statusCode == 401` به فراخوان منتقل می‌شود تا صفحه پنل کاربر را
/// به صفحه ورود هدایت کند.
class SellerPanelRepository {
  SellerPanelRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// `GET /api/seller/products.php` — محصولات فروشنده لاگین‌شده.
  Future<List<ProductModel>> fetchMyProducts(String token) async {
    final Object? decoded = await _api.getJson(
      ApiConstants.sellerProductsUri(),
      bearerToken: token,
    );
    return ProductModel.listFromDecoded(decoded);
  }

  /// `DELETE /api/seller/product.php?id={id}` — حذف محصول خودم.
  Future<void> deleteProduct(
    String token, {
    required int productId,
  }) async {
    await _api.deleteJson(
      ApiConstants.sellerProductUri(productId: productId),
      bearerToken: token,
    );
  }

  /// `POST /api/seller/products.php` — افزودن محصول جدید (بدون id).
  ///
  /// درخواست افزودن «هرگز» id ندارد — نه در URL و نه در بدنه — چون
  /// endpoint مفرد (`product.php`) فقط برای ویرایش/حذف با id است و
  /// POST بدون id به آن → خطای «شناسه محصول نامعتبر است». امضای این
  /// متد عمداً پارامتر id ندارد تا ارسال id از سمت کلاینت ناممکن باشد.
  ///
  /// قیمت `0` یعنی «قیمت توافقی» (مطابق قرارداد مدل [ProductModel]).
  /// [imageUrls] آدرس‌های تصاویر آپلودشده (از [uploadProductImage]).
  Future<void> addProduct(
    String token, {
    required String title,
    int? categoryId,
    required int price,
    String? brand,
    String? description,
    List<String> imageUrls = const <String>[],
  }) async {
    await _api.postJson(
      ApiConstants.sellerProductsUri(), // POST به مجموعه (products جمع)
      bearerToken: token,
      body: _productBody(
        title: title,
        categoryId: categoryId,
        price: price,
        brand: brand,
        description: description,
        imageUrls: imageUrls,
      ),
    );
  }

  /// `PUT /api/seller/product.php?id={id}` — ویرایش محصول موجود.
  /// (جدا و مستقل از افزودن — id فقط و فقط در همین مسیر URL ویرایش می‌رود)
  Future<void> updateProduct(
    String token, {
    required int productId,
    required String title,
    int? categoryId,
    required int price,
    String? brand,
    String? description,
    List<String> imageUrls = const <String>[],
  }) async {
    await _api.putJson(
      ApiConstants.sellerProductUri(productId: productId),
      bearerToken: token,
      body: _productBody(
        title: title,
        categoryId: categoryId,
        price: price,
        brand: brand,
        description: description,
        imageUrls: imageUrls,
      ),
    );
  }

  /// `POST /api/seller/upload.php` — آپلود یک تصویر محصول (multipart).
  ///
  /// فایل با فیلد `image` و هدر Bearer ارسال می‌شود؛
  /// آدرس تصویر آپلودشده (resolve شده به آدرس مطلق) برگردانده می‌شود.
  /// ساختار پاسخ سرور انعطاف‌پذیر پارس می‌شود (url در ریشه یا data).
  Future<String> uploadProductImage(
    String token, {
    required String filePath,
    String? fileName,
    String? mimeType,
  }) async {
    final Object? decoded = await _api.uploadJson(
      ApiConstants.sellerUploadUri(),
      fileField: 'image',
      filePath: filePath,
      fileName: fileName,
      mimeType: mimeType,
      bearerToken: token,
    );
    final String? url = _extractUploadedUrl(decoded);
    if (url == null) {
      throw const ApiException(
        'آدرس تصویر آپلودشده از سرور دریافت نشد؛ دوباره تلاش کنید.',
      );
    }
    return url;
  }

  // ─────────── اطلاعات فروشگاه (پروفایل) ───────────

  /// `GET /api/seller/profile.php` — اطلاعات فعلی فروشنده لاگین‌شده
  /// (نام، توضیحات، شهر، تلفن، واتساپ، لوگو).
  Future<SellerProfileModel> fetchProfile(String token) async {
    final Object? decoded = await _api.getJson(
      ApiConstants.sellerProfileUri(),
      bearerToken: token,
    );
    return SellerProfileModel.fromDecoded(decoded);
  }

  /// `PUT /api/seller/profile.php` — ویرایش اطلاعات فروشنده لاگین‌شده.
  ///
  /// مطابق قرارداد سرور، هر ۶ فیلد در بدنه ارسال می‌شوند؛ پاک کردن
  /// یک فیلد در فرم یعنی ارسال رشته خالی (حذف مقدار قبلی).
  Future<void> updateProfile(
    String token, {
    required String name,
    required String description,
    required String phone,
    required String whatsapp,
    required String city,
    required String logoUrl,
  }) async {
    await _api.putJson(
      ApiConstants.sellerProfileUri(),
      bearerToken: token,
      body: <String, dynamic>{
        'name': name.trim(),
        'description': description.trim(),
        'phone': phone.trim(),
        'whatsapp': whatsapp.trim(),
        'city': city.trim(),
        'logo_url': logoUrl.trim(),
      },
    );
  }

  // ─────────── بخش خصوصی ───────────

  /// ساخت بدنه مشترک افزودن/ویرایش محصول — فیلدهای خالی حذف می‌شوند.
  /// ⚠️ هیچ فیلد id در بدنه ساخته نمی‌شود؛ شناسه فقط در URL ویرایش/حذف می‌رود.
  static Map<String, dynamic> _productBody({
    required String title,
    required int? categoryId,
    required int price,
    required String? brand,
    required String? description,
    required List<String> imageUrls,
  }) {
    return <String, dynamic>{
      'title': title.trim(),
      'price': price,
      if (categoryId != null && categoryId > 0) 'category_id': categoryId,
      if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
    };
  }

  /// استخراج انعطاف‌پذیر آدرس تصویر از پاسخ آپلود —
  /// ساختارهای رایج: `data.url`، `data.image_url`، `data.path`،
  /// `url` در ریشه، یا خود `data` به‌صورت رشته.
  static String? _extractUploadedUrl(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;

    // `data` رشته‌ای → همان آدرس است
    final Object? data = decoded['data'];
    if (data is String && data.trim().isNotEmpty) {
      return ApiConstants.resolveUrl(data);
    }

    final Map<String, dynamic> source =
        data is Map<String, dynamic> ? data : decoded;
    for (final String key in const <String>[
      'url',
      'image_url',
      'file_url',
      'path',
      'link',
      'file',
    ]) {
      final Object? value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return ApiConstants.resolveUrl(value);
      }
    }
    return null;
  }

  /// آزادسازی منابع کلاینت HTTP.
  void dispose() => _api.dispose();
}
