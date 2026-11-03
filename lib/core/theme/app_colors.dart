import 'package:flutter/material.dart';

/// پالت رنگی سراسری اپلیکیشن «تجهیزیار».
///
/// تمام رنگ‌های استفاده‌شده در اپ باید از همین کلاس خوانده شوند
/// تا هویت بصری در سراسر اپلیکیشن یکدست بماند.
abstract final class AppColors {
  // ─────────── رنگ‌های هویتی برند ───────────

  /// آبی نفتی تیره — رنگ اصلی برند
  /// (نوار بالای صفحه، عناوین، ناوبری انتخاب‌شده و ...)
  static const Color primary = Color(0xFF1E3A5F);

  /// تن روشن‌تر آبی نفتی — برای گرادیان‌ها و سطوح برند
  static const Color primaryLight = Color(0xFF2B5278);

  /// نارنجی گرم — رنگ تأکیدی
  /// (دکمه‌های اصلی، برچسب قیمت، نشان‌ها و ...)
  static const Color secondary = Color(0xFFF59E0B);

  // ─────────── پس‌زمینه و سطوح ───────────

  /// پس‌زمینه کلی صفحه‌ها
  static const Color background = Color(0xFFF8FAFC);

  /// سطح کارت‌ها و کانتینرها
  static const Color surface = Color(0xFFFFFFFF);

  // ─────────── متن ───────────

  /// رنگ متن اصلی (عنوان‌ها و محتوای مهم)
  static const Color textPrimary = Color(0xFF1E293B);

  /// رنگ متن فرعی (توضیحات، زیرنویس‌ها و ...)
  static const Color textSecondary = Color(0xFF64748B);

  // ─────────── رنگ‌های مکمل ───────────

  /// خطوط جداکننده و حاشیه‌ها
  static const Color border = Color(0xFFE2E8F0);

  /// حالت خطا
  static const Color error = Color(0xFFDC2626);

  /// حالت موفقیت
  static const Color success = Color(0xFF16A34A);

  // ─────────── نسخه‌های کم‌رنگ (Soft Tints) ───────────

  /// تینت روشن آبی — پس‌زمینه نشانگر (Indicator) و آواتارها
  static const Color primarySoft = Color(0xFFE8EEF5);

  /// تینت روشن نارنجی — پس‌زمینه هشدارها و برچسب‌های تخفیف
  static const Color accentSoft = Color(0xFFFEF3C7);

  /// نارنجی تیره — متن روی سطوح نارنجی کم‌رنگ
  static const Color accentDark = Color(0xFF92400E);
}
