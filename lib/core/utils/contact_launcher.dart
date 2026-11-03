import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:tajhizyar/core/utils/phone_utils.dart';

/// ابزار مشترک بازکردن تماس تلفنی و واتساپ با `url_launcher`.
///
/// همه صفحه‌هایی که دکمه تماس دارند (جزئیات محصول، هدر فروشنده و ...)
/// از همین‌جا استفاده می‌کنند تا رفتار (LaunchMode، پیام خطا، نبود شماره)
/// یکدست بماند.
///
/// نکته: `ScaffoldMessengerState` را فراخوان (قبل از هر `await`) می‌سازد
/// و پاس می‌دهد تا هرگز از `context` پس از async gap استفاده نشود.
abstract final class ContactLauncher {
  ContactLauncher._();

  /// بازکردن شماره‌گیر تلفن با `tel:`.
  ///
  /// اگر [phone] ثبت نشده باشد، SnackBar اطلاع‌رسانی می‌شود.
  static Future<void> call(
    ScaffoldMessengerState messenger, {
    required String? phone,
  }) async {
    if (phone == null) {
      _showInfo(messenger, 'شماره تماسی برای این فروشنده ثبت نشده است.');
      return;
    }
    await _launchExternal(
      messenger,
      Uri(scheme: 'tel', path: phone),
      fallbackMessage: 'امکان برقراری تماس تلفنی وجود ندارد.',
    );
  }

  /// بازکردن گفتگوی واتساپ با لینک `https://wa.me/…` و پیام [messageText].
  ///
  /// شماره با [normalizeWhatsappNumber] به قالب بین‌المللی تبدیل می‌شود؛
  /// اگر ثبت نشده یا نامعتبر باشد، SnackBar اطلاع‌رسانی می‌شود.
  static Future<void> whatsapp(
    ScaffoldMessengerState messenger, {
    required String? number,
    required String messageText,
  }) async {
    final String? international = normalizeWhatsappNumber(number);
    if (international == null) {
      _showInfo(messenger, 'شماره واتساپی برای این فروشنده ثبت نشده است.');
      return;
    }
    final Uri uri = Uri.https(
      'wa.me',
      '/$international',
      <String, String>{'text': messageText},
    );
    await _launchExternal(
      messenger,
      uri,
      fallbackMessage: 'امکان بازکردن واتساپ وجود ندارد.',
    );
  }

  // ─────────── بخش داخلی ───────────

  static Future<void> _launchExternal(
    ScaffoldMessengerState messenger,
    Uri uri, {
    required String fallbackMessage,
  }) async {
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showSnack(messenger, fallbackMessage);
      }
    } on Exception {
      _showSnack(messenger, fallbackMessage);
    }
  }

  static void _showInfo(ScaffoldMessengerState messenger, String message) {
    _showSnack(messenger, message, icon: Icons.info_outline_rounded);
  }

  static void _showSnack(
    ScaffoldMessengerState messenger,
    String message, {
    IconData? icon,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
