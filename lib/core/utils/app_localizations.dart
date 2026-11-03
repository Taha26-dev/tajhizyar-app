import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// پیکربندی بومی‌سازی (فارسی) و راست‌چین‌سازی اپلیکیشن.
abstract final class AppLocalization {
  /// زبان و منطقه پیش‌فرض اپلیکیشن.
  static const Locale locale = Locale('fa', 'IR');

  /// زبان‌های پشتیبانی‌شده — فارسی به‌عنوان زبان اصلی.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fa', 'IR'),
    Locale('en', 'US'),
  ];

  /// دلیگیت‌های بومی‌سازی Material / Widgets / Cupertino.
  static final List<LocalizationsDelegate<Object>> delegates =
      <LocalizationsDelegate<Object>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
