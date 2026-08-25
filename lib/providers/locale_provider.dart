import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_strings.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('tr', 'TR');

  LocaleProvider({String? initialLanguageCode}) {
    if (initialLanguageCode != null) {
      _locale = Locale(initialLanguageCode, initialLanguageCode == 'en' ? 'US' : 'TR');
      AppStrings.currentLanguage = initialLanguageCode;
    } else {
      AppStrings.currentLanguage = 'tr';
    }
  }

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';
  String get currentLanguageCode => _locale.languageCode;

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    AppStrings.currentLanguage = newLocale.languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLocale.languageCode);
  }
}
