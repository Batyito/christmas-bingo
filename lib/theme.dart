import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: Colors.teal,
      secondary: Colors.cyan,
      surface: Colors.grey[800]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
      headlineSmall: TextStyle(
        color: Colors.cyan,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static final ThemeData christmasTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: Colors.red[800]!,
      secondary: Colors.green[700]!,
      surface: Colors.red[900]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
    ),
    scaffoldBackgroundColor: Colors.red[900],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
      headlineSmall: TextStyle(
        color: Colors.green,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static final ThemeData easterTheme = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: Colors.pink[400]!,
      secondary: Colors.purple[200]!,
      surface: Colors.purple[900]!,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white70,
    ),
    scaffoldBackgroundColor: Colors.purple[900],
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 14,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
      headlineSmall: TextStyle(
        color: Colors.pink,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamilyFallback: [
          'Material Icons',
          'Apple Color Emoji',
          'Noto Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink[400],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
