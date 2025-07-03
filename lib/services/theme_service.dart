import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get notificationsEnabled => _notificationsEnabled;

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  void cycleTheme() {
    if (_themeMode == ThemeMode.system) {
      setThemeMode(ThemeMode.light);
    } else if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.system);
    }
  }

  void cycleFontSize() {
    if (_fontScale == 1.0) {
      _fontScale = 1.1; // Large
    } else if (_fontScale == 1.1) {
      _fontScale = 0.9; // Small
    } else {
      _fontScale = 1.0; // Normal
    }
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
  }
}