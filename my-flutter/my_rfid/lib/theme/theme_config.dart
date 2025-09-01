import 'package:flutter/material.dart';
import 'color_palette.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: ColorPalette.primary500,
      primaryColorDark: ColorPalette.primary700,
      primaryColorLight: ColorPalette.primary300,
      scaffoldBackgroundColor: ColorPalette.background50,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.primary500,
        foregroundColor: ColorPalette.text50,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ColorPalette.text800,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ColorPalette.text800,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ColorPalette.text700,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ColorPalette.text600,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: ColorPalette.primary500,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary500,
          foregroundColor: ColorPalette.text50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.background100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // FIX: Use CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: ColorPalette.background100,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

   ThemeData get darkTheme {
    return ThemeData(
      primaryColor: ColorPalette.primary200,
      primaryColorDark: ColorPalette.primary400,
      primaryColorLight: ColorPalette.primary100,
      scaffoldBackgroundColor: ColorPalette.background900,
      appBarTheme: AppBarTheme(
        backgroundColor: ColorPalette.primary700,
        foregroundColor: ColorPalette.text50,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: ColorPalette.text200,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: ColorPalette.text200,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: ColorPalette.text300,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: ColorPalette.text400,
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: ColorPalette.primary200,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.primary200,
          foregroundColor: ColorPalette.text900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorPalette.background800,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // FIX: Use CardThemeData instead of CardTheme
      cardTheme: CardThemeData(
        color: ColorPalette.background800,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
