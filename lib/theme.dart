import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepOrange,
      brightness: Brightness.dark,
      primary: Colors.deepOrange,
      onPrimary: Colors.white,
      secondary: Colors.orangeAccent,
      onSecondary: Colors.black,
      surface: const Color(0xFF1F1F1F), // Slightly lighter than background
      onSurface: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1F1F1F),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1F1F1F),
      indicatorColor: Colors.deepOrange,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme).copyWith(
      bodyLarge: const TextStyle(color: Colors.white70),
      bodyMedium: const TextStyle(color: Colors.white70),
      titleLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    ),
  );
}
