// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  // Keys for SharedPreferences
  static const String _themeModeKey = 'themeMode';
  static const String _fontScaleKey = 'fontScale';
  static const String _notificationsKey = 'notificationsEnabled';

  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Loads theme and notification settings from local storage.
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme, defaulting to system if not found.
    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];

    // Load font scale, defaulting to 1.0.
    _fontScale = prefs.getDouble(_fontScaleKey) ?? 1.0;

    // Load notification setting, defaulting to true.
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;

    // No need to notify listeners, this is called before the UI is built.
  }

  /// Saves all current settings to SharedPreferences.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
    await prefs.setDouble(_fontScaleKey, _fontScale);
    await prefs.setBool(_notificationsKey, _notificationsEnabled);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _saveSettings();
    notifyListeners();
  }

  void cycleTheme() {
    // The order is System -> Light -> Dark -> System
    final nextIndex = (_themeMode.index + 1) % ThemeMode.values.length;
    setThemeMode(ThemeMode.values[nextIndex]);
  }

  void cycleFontSize() {
    // Cycle through 0.9 (Small), 1.0 (Normal), 1.1 (Large)
    if (_fontScale >= 1.1) {
      _fontScale = 0.9; // If large or larger, go to small
    } else if (_fontScale >= 1.0) _fontScale = 1.1; // If normal, go to large
    else _fontScale = 1.0; // If small, go to normal
    _saveSettings();
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _saveSettings();
    notifyListeners();
  }
}