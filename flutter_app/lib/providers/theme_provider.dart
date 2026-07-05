import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _languageCode = 'ar';

  bool get isDarkMode => _isDarkMode;
  String get languageCode => _languageCode;

  void setDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }
}
