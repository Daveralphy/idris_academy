// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemes {
  // Helper function to scale a TextTheme
  static TextTheme _scaleTextTheme(TextTheme base, double scale) {
    // Helper to safely scale a TextStyle
    TextStyle? scaleStyle(TextStyle? style) {
      // If the style or its font size is null, return the original style.
      if (style?.fontSize == null) return style;
      // Otherwise, return a new style with the scaled font size.
      return style?.copyWith(fontSize: (style.fontSize ?? 14.0) * scale);
    }

    return base.copyWith(
      displayLarge: scaleStyle(base.displayLarge),
      displayMedium: scaleStyle(base.displayMedium),
      displaySmall: scaleStyle(base.displaySmall),
      headlineLarge: scaleStyle(base.headlineLarge),
      headlineMedium: scaleStyle(base.headlineMedium),
      headlineSmall: scaleStyle(base.headlineSmall),
      titleLarge: scaleStyle(base.titleLarge),
      titleMedium: scaleStyle(base.titleMedium),
      titleSmall: scaleStyle(base.titleSmall),
      bodyLarge: scaleStyle(base.bodyLarge),
      bodyMedium: scaleStyle(base.bodyMedium),
      bodySmall: scaleStyle(base.bodySmall),
      labelLarge: scaleStyle(base.labelLarge),
      labelMedium: scaleStyle(base.labelMedium),
      labelSmall: scaleStyle(base.labelSmall),
    );
  }

  static ThemeData getLightTheme(double fontScale) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFFF07C3B), // Orange/Rust
      onPrimary: Colors.black,
      secondary: const Color(0xFF74C7A3), // Light Green/Teal
      onSecondary: Colors.black,
      tertiary: const Color(0xFF5C4D3E), // Dark Brown
      onTertiary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      surface: const Color(0xFFF2EDD7), // Lighter Card Beige
      onSurface: const Color(0xFF5C4D3E),
      scrim: Colors.black.withOpacity(0.7),
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F8F8),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF07C3B), // Orange/Rust
        foregroundColor: Colors.black, // For title text and icons
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFFF07C3B), // Orange/Rust
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black.withOpacity(0.7),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFFF2EDD7), // Lighter Card Beige for the menu background
        elevation: 8,
        textStyle: TextStyle(color: Color(0xFF5C4D3E)), // onSurface color for readability
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return baseTheme.copyWith(
      textTheme: _scaleTextTheme(baseTheme.textTheme, fontScale),
    );
  }

  static ThemeData getDarkTheme(double fontScale) {
    final baseTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: const Color(0xFFF07C3B), // Orange/Rust
        onPrimary: Colors.black,
        secondary: const Color(0xFF74C7A3), // Light Green/Teal
        onSecondary: Colors.black,
        tertiary: const Color(0xFFF2EDD7), // Lighter Card Beige as tertiary
        onTertiary: Colors.black,
        error: Colors.redAccent,
        onError: Colors.white, // Light grey text
        surface: const Color(0xFF2A2A2A), // A lighter grey for cards to stand out
        onSurface: const Color(0xFFE0E0E0),
        scrim: Colors.black.withOpacity(0.8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E), // Use surface color for dark AppBar
        foregroundColor: Color(0xFFE0E0E0), // Use onSurface color for text/icons
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E), // Use surface color
        selectedItemColor: const Color(0xFFF07C3B), // Use primary color for selected item
        unselectedItemColor: const Color(0xFFE0E0E0).withOpacity(0.7), // Use onSurface with opacity
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        elevation: 8,
        textStyle: TextStyle(color: Color(0xFFE0E0E0)),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2), // A bit more visible border
          ),
        ),
      ),
    );
    return baseTheme.copyWith(
      textTheme: _scaleTextTheme(baseTheme.textTheme, fontScale),
    );
  }
}