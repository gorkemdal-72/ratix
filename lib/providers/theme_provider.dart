import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider({ThemeMode? initialTheme}) {
    if (initialTheme != null) {
      _themeMode = initialTheme;
    }
  }

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Temayı değiştiren fonksiyon
  void toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // Tüm uygulamaya haber ver!
    
    // Tercihi kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);
  }
}