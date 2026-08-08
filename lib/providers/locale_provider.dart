import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('hr');

  Locale get locale => _locale;
  bool get isEnglish => _locale.languageCode == 'en';

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLocaleKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
    notifyListeners();
  }

  void toggleLocale() {
    setLocale(_locale.languageCode == 'hr' ? const Locale('en') : const Locale('hr'));
  }
}
