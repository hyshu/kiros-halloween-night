import 'package:flutter/material.dart';
import '../l10n/strings.g.dart';

class LocaleManager {
  static AppLocale get currentLocale => LocaleSettings.currentLocale;

  static void setLocale(AppLocale locale) {
    LocaleSettings.setLocale(locale);
  }

  static void setLocaleFromString(String localeCode) {
    final locale = AppLocale.values.firstWhere(
      (l) => l.languageCode == localeCode,
      orElse: () => AppLocale.en,
    );
    setLocale(locale);
  }

  static List<Locale> get supportedLocales {
    return AppLocale.values.map((locale) => locale.flutterLocale).toList();
  }

  static AppLocale getLocaleFromDeviceLanguage(String deviceLanguageCode) {
    return AppLocale.values.firstWhere(
      (locale) => locale.languageCode == deviceLanguageCode,
      orElse: () => AppLocale.en,
    );
  }
}
