import 'package:http/http.dart' as http;

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/network/api_client.dart';
import 'package:tajhizyar/features/seller/data/models/seller_model.dart';

/// منبع داده فروشندگان — صفحه فروشنده (پروفایل عمومی فروشگاه).
class SellerRepository {
  SellerRepository({http.Client? client}) : _api = ApiClient(client: client);

  final ApiClient _api;

  /// `GET https://cr8v.ir/api/seller.php?id={id}` — پروفایل فروشنده
  /// به‌همراه فهرست محصولاتش.
  ///
  /// اگر فروشنده وجود نداشته باشد (`success == false` از سمت سرور)،
  /// null برمی‌گردد تا صفحه فروشنده حالت «یافت نشد» نشان دهد؛
  /// خطاهای شبکه/سرور به‌صورت [ApiException] پرتاب می‌شوند.
  Future<SellerModel?> fetchSeller(int sellerId) async {
    final Object? decoded = await _api.getJson(
      ApiConstants.sellerUri(sellerId),
      allowFailure: true,
    );
    return SellerModel.fromDecoded(decoded);
  }

  /// آزادسازی منابع کلاینت HTTP.
  void dispose() => _api.dispose();
}
