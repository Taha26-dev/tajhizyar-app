import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:tajhizyar/core/constants/api_constants.dart';
import 'package:tajhizyar/core/constants/error_messages.dart';
import 'package:tajhizyar/core/network/api_exception.dart';

/// کلاینت سبک HTTP برای فراخوانی APIهای JSON سرور تجهیزیار.
///
/// مسئولیت‌ها (مشترک بین همه ریپازیتوری‌ها):
/// - هدر `Accept: application/json` و هدر اختیاری `Authorization: Bearer {token}`
/// - مهلت [ApiConstants.requestTimeout]
/// - decode با انکودینگ UTF-8 (حیاتی برای متن فارسی)
/// - نگاشت یک‌جای همه‌ی خطاها به [ApiException] با پیام‌های استاندارد
///   فارسی [ErrorMessages] (قطع اینترنت، مهلت، خطای سرور، ۴۰۱، ۴۰۴)
/// - استخراج `message` فارسی سرور حتی از پاسخ‌های غیر ۲۰۰ (400/401/...)
///   و ثبت کد وضعیت + دسته در [ApiException.statusCode] / [ApiException.kind]
/// - بررسی `success == false` در بدنه (مگر با allowFailure)
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// اجرای درخواست GET و برگرداندن پاسخ decode‌شده.
  ///
  /// - Timeout / قطع ارتباط → [ApiException] با پیام فارسی
  /// - کد وضعیت غیر 2xx → [ApiException] (پیام فارسی سرور اگر موجود باشد)
  /// - `success == false` در بدنه → اگر [allowFailure] باشد همان Map
  ///   برگردانده می‌شود (تا فراخوان خودش تصمیم بگیرد، مثلاً Not Found)،
  ///   وگرنه [ApiException] با پیام سرور پرتاب می‌شود.
  ///
  /// [bearerToken] در صورت ارسال، به‌صورت هدر
  /// `Authorization: Bearer {token}` ضمیمه می‌شود (APIهای پنل فروشنده).
  Future<Object?> getJson(
    Uri uri, {
    bool allowFailure = false,
    String? bearerToken,
  }) =>
      _sendJson(
        () => _client.get(uri, headers: _headers(bearerToken: bearerToken)),
        allowFailure: allowFailure,
      );

  /// اجرای درخواست POST با بدنه JSON
  /// (ورود فروشنده، افزودن محصول و ...).
  Future<Object?> postJson(
    Uri uri, {
    Object? body,
    bool allowFailure = false,
    String? bearerToken,
  }) =>
      _sendJson(
        () => _client.post(
              uri,
              headers: _headers(bearerToken: bearerToken, jsonBody: true),
              body: body == null ? null : jsonEncode(body),
            ),
        allowFailure: allowFailure,
      );

  /// اجرای درخواست PUT با بدنه JSON
  /// (ویرایش محصول در پنل فروشنده).
  Future<Object?> putJson(
    Uri uri, {
    Object? body,
    bool allowFailure = false,
    String? bearerToken,
  }) =>
      _sendJson(
        () => _client.put(
              uri,
              headers: _headers(bearerToken: bearerToken, jsonBody: true),
              body: body == null ? null : jsonEncode(body),
            ),
        allowFailure: allowFailure,
      );

  /// اجرای درخواست DELETE
  /// (حذف محصول در پنل فروشنده).
  Future<Object?> deleteJson(
    Uri uri, {
    bool allowFailure = false,
    String? bearerToken,
  }) =>
      _sendJson(
        () => _client.delete(
              uri,
              headers: _headers(bearerToken: bearerToken),
            ),
        allowFailure: allowFailure,
      );

  /// اجرای درخواست multipart (آپلود فایل) با پاسخ JSON
  /// (آپلود تصویر محصول در پنل فروشنده).
  ///
  /// فایل از [filePath] خوانده و با نام فیلد [fileField] ارسال می‌شود؛
  /// MIME type در صورت نبود [mimeType] از پسوند [fileName] حدس زده می‌شود.
  /// مهلت پیش‌فرض: [ApiConstants.uploadTimeout] (آپلود روی موبایل کندتر است).
  Future<Object?> uploadJson(
    Uri uri, {
    required String fileField,
    required String filePath,
    String? fileName,
    String? mimeType,
    String? bearerToken,
    bool allowFailure = false,
  }) async {
    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          fileField,
          filePath,
          filename: fileName,
          contentType: _fileMediaType(mimeType, fileName),
        ),
      )
      ..headers.addAll(_headers(bearerToken: bearerToken));

    const Duration timeout = ApiConstants.uploadTimeout;
    http.Response response;
    try {
      final http.StreamedResponse streamed =
          await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        ErrorMessages.uploadTimeout,
        kind: ApiErrorKind.timeout,
      );
    } on http.ClientException {
      throw const ApiException(
        ErrorMessages.networkOffline,
        kind: ApiErrorKind.network,
      );
    }
    return _processResponse(response, allowFailure: allowFailure);
  }

  // ─────────── بخش خصوصی ───────────

  /// ساخت هدرهای مشترک درخواست.
  Map<String, String> _headers({String? bearerToken, bool jsonBody = false}) =>
      <String, String>{
        'Accept': 'application/json',
        if (jsonBody) 'Content-Type': 'application/json',
        if (bearerToken != null && bearerToken.trim().isNotEmpty)
          'Authorization': 'Bearer ${bearerToken.trim()}',
      };

  /// MIME type فایل برای هدر multipart —
  /// اولویت: مقدار صریح → حدس از پسوند نام فایل → octet-stream.
  static MediaType _fileMediaType(String? mimeType, String? fileName) {
    final String? resolved =
        (mimeType != null && mimeType.contains('/'))
            ? mimeType
            : _extensionMimeType(fileName);
    if (resolved == null) {
      return MediaType('application', 'octet-stream');
    }
    return MediaType.parse(resolved);
  }

  /// حدس MIME type از پسوند فایل — فرمت‌های مجاز تصویر محصول.
  static String? _extensionMimeType(String? fileName) {
    final String extension =
        (fileName ?? '').split('.').last.trim().toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  /// ارسال درخواست JSON و پردازش پاسخ — با نگاشت خطاهای شبکه/مهلت
  /// به پیام‌های استاندارد [ErrorMessages].
  Future<Object?> _sendJson(
    Future<http.Response> Function() action, {
    required bool allowFailure,
  }) async {
    http.Response response;
    try {
      response = await action().timeout(ApiConstants.requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        ErrorMessages.timeout,
        kind: ApiErrorKind.timeout,
      );
    } on http.ClientException {
      throw const ApiException(
        ErrorMessages.networkOffline,
        kind: ApiErrorKind.network,
      );
    }
    return _processResponse(response, allowFailure: allowFailure);
  }

  /// پردازش مشترک پاسخ‌های JSON (JSON و multipart آپلود) —
  /// نگاشت کدهای وضعیت به دسته و پیام استاندارد:
  ///
  /// - ۴۰۱ → [ApiErrorKind.unauthorized] + پیام «نشست منقضی شده»
  ///   (مگر سرور پیام خاص‌تری بدهد، مثل «نام کاربری یا رمز عبور اشتباه»)
  /// - ۴۰۴ → [ApiErrorKind.notFound] + پیام «یافت نشد»
  /// - سایر غیر ۲xx → [ApiErrorKind.server] + پیام «خطای سرور»
  /// - `success == false` در بدنه → اگر [allowFailure] باشد همان Map
  ///   برگردانده می‌شود (تا فراخوان خودش تصمیم بگیرد، مثلاً Not Found)،
  ///   وگرنه [ApiException] با پیام سرور پرتاب می‌شود.
  static Object? _processResponse(
    http.Response response, {
    required bool allowFailure,
  }) {
    // بدنه حتی در خطاهای 400/401 هم معمولاً JSON معتبر با پیام فارسی دارد.
    final Object? decoded = _tryDecodeBody(response.bodyBytes);

    // ── کد وضعیت غیر موفق ──
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String? serverText =
          decoded is Map<String, dynamic> ? _serverMessage(decoded) : null;

      switch (response.statusCode) {
        case 401:
          throw ApiException(
            serverText ?? ErrorMessages.sessionExpired,
            statusCode: 401,
            kind: ApiErrorKind.unauthorized,
          );
        case 404:
          throw ApiException(
            serverText ?? ErrorMessages.notFound,
            statusCode: 404,
            kind: ApiErrorKind.notFound,
          );
        default:
          throw ApiException(
            serverText ?? ErrorMessages.serverError,
            statusCode: response.statusCode,
            kind: ApiErrorKind.server,
          );
      }
    }

    // ── بدنه با success == false ──
    if (!allowFailure &&
        decoded is Map<String, dynamic> &&
        decoded['success'] == false) {
      throw ApiException(
        _serverMessage(decoded) ?? ErrorMessages.fetchFailed,
        kind: ApiErrorKind.server,
      );
    }

    return decoded;
  }

  /// decode امن بدنه پاسخ — بدنه خالی یا غیر JSON → null.
  static Object? _tryDecodeBody(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }

  /// استخراج پیام متنی سرور از پاسخ خطا — نبود پیام معتبر → null.
  static String? _serverMessage(Map<String, dynamic> body) {
    final Object? message = body['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return null;
  }

  /// آزادسازی منابع کلاینت HTTP.
  void dispose() => _client.close();
}
