import 'package:flutter/material.dart';

class Apptheme {
  static const Color bluecolor = Color(0xFF0066FF);
  static const Color ambercolor = Color(0xFFFBAE3D);
  static const Color blackcolor = Color(0xFF0D171B);
  static const Color offwhitecolor = Color(0xFFECEFEA);

  Apptheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: offwhitecolor,

      colorScheme: const ColorScheme.light(
        primary: bluecolor,
        secondary: ambercolor,
        surface: offwhitecolor,
        onPrimary: Colors.white,
        onSecondary: blackcolor,
        onSurface: blackcolor,
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          color: blackcolor,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          color: blackcolor,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          color: blackcolor,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          color: blackcolor,
          fontWeight: FontWeight.w300,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bluecolor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bluecolor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            color: blackcolor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
