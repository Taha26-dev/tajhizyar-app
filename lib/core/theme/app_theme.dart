import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tajhizyar/core/theme/app_colors.dart';

/// تم اصلی (روشن) اپلیکیشن «تجهیزیار» بر پایه Material 3.
///
/// تمام استایل‌های پایه (رنگ، فونت فارسی، شکل ویجت‌ها) از همین‌جا
/// کنترل می‌شود تا هویت بصری در سراسر اپلیکیشن یکدست بماند.
abstract final class AppTheme {
  AppTheme._();

  /// شعاع گوشه‌های استاندارد برای کارت‌ها، فیلدها و کانتینرها.
  static const double radius = 14.0;

  /// شعاع گوشه‌های دکمه‌ها.
  static const double _buttonRadius = 12.0;

  /// ساخت حاشیه فیلدهای ورودی.
  static OutlineInputBorder _inputBorder(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(radius)),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData light() {
    // ── فونت فارسی وزیرمتن ──
    final String fontFamily = GoogleFonts.vazirmatn().fontFamily ?? 'Vazirmatn';

    final TextTheme vazirmatn = GoogleFonts.vazirmatnTextTheme();
    final TextTheme textTheme = vazirmatn
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          titleLarge:
              vazirmatn.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium:
              vazirmatn.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall:
              vazirmatn.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          labelLarge:
              vazirmatn.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        );

    // ── طرح رنگ Material 3 ──
    final ColorScheme colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ).copyWith(
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      surfaceContainerHighest: AppColors.background,
      primaryContainer: AppColors.primarySoft,
      onPrimaryContainer: AppColors.primary,
      secondaryContainer: AppColors.accentSoft,
      onSecondaryContainer: AppColors.accentDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashFactory: InkRipple.splashFactory,

      // ── نوار بالای صفحه (سفارشی: سرمه‌ای با متن سفید) ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── کارت‌ها: سفید با حاشیه ظریف و گوشه گرد ──
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          side: BorderSide(color: AppColors.border),
        ),
      ),

      // ── فیلدهای ورودی ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.6),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, width: 1.6),
      ),

      // ── دکمه اصلی: نارنجی گرم ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── دکمه خط‌دار ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          side: const BorderSide(color: AppColors.primary),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
          ),
          textStyle: textTheme.labelLarge
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),

      // ── دکمه متنی ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: textTheme.labelLarge
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),

      // ── چیپ‌ها (فیلترها) ──
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        deleteIconColor: AppColors.textSecondary,
        labelStyle: textTheme.bodyMedium
            ?.copyWith(color: AppColors.textPrimary, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.border)),
      ),

      // ── نوار ناوبری پایین (Material 3) ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        elevation: 0,
        height: 68,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>(
          (Set<WidgetState> states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (Set<WidgetState> states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),

      // ── BottomNavigationBar کلاسیک ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),

      // ── اسنک‌بار ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // ── سایر اجزا ──
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_buttonRadius)),
        ),
      ),
    );
  }
}
