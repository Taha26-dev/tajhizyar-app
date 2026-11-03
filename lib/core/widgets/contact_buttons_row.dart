import 'package:flutter/material.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';
import 'package:tajhizyar/core/utils/contact_launcher.dart';

/// ردیف دو دکمه «تماس تلفنی» (نارنجی) و «واتساپ» (سبز) — مشترک بین
/// نوار پایین صفحه جزئیات محصول و هدر صفحه فروشنده.
///
/// منطق بازکردن تماس/واتساپ و SnackBarهای خطا در [ContactLauncher] است؛
/// این ویجت فقط چیدمان دکمه‌ها را مسئولیت دارد.
class ContactButtonsRow extends StatelessWidget {
  const ContactButtonsRow({
    super.key,
    required this.phone,
    required this.whatsapp,
    this.whatsappMessage = 'سلام، در تجهیزیار سؤال داشتم.',
  });

  /// شماره تماس (خام از API — ممکن است null باشد)
  final String? phone;

  /// شماره واتساپ (خام از API — ممکن است null باشد)
  final String? whatsapp;

  /// متن پیش‌پرشده گفتگوی واتساپ
  final String whatsappMessage;

  @override
  Widget build(BuildContext context) {
    // قبل از هر async عملیاتی گرفته می‌شود (الگوی امن ContactLauncher)
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    return Row(
      children: <Widget>[
        // ── دکمه تماس تلفنی (نارنجی — تم پیش‌فرض) ──
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => ContactLauncher.call(messenger, phone: phone),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 48),
            ),
            icon: const Icon(Icons.phone_rounded, size: 20),
            label: const Text('تماس تلفنی'),
          ),
        ),
        const SizedBox(width: 12),
        // ── دکمه واتساپ (سبز) ──
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => ContactLauncher.whatsapp(
              messenger,
              number: whatsapp,
              messageText: whatsappMessage,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            icon: const Icon(Icons.chat_rounded, size: 20),
            label: const Text('واتساپ'),
          ),
        ),
      ],
    );
  }
}
