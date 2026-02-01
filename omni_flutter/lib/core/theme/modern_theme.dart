import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ModernTheme {
  // Core Colors
  static const Color background = Color(0xFFF8F9FE); // Clean off-white
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF6366F1); // Modern Indigo
  static const Color secondary = Color(0xFFEC4899); // Modern Pink
  static const Color textMain = Color(0xFF1E293B); // Slate 800
  static const Color textSub = Color(0xFF64748B); // Slate 500
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color error = Color(0xFFEF4444);

  // Gradients (Subtle or removed as requested, keeping flat mostly)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primary], // Fallback to solid
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles
  static TextStyle get header => GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textMain,
    letterSpacing: -0.5,
  );

  static TextStyle get subHeader => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textMain,
    letterSpacing: -0.5,
  );

  static TextStyle get body => GoogleFonts.inter(
    fontSize: 16,
    color: textSub,
    height: 1.5,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 14,
    color: textSub,
    fontWeight: FontWeight.w500,
  );

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
    border: Border.all(color: Colors.white, width: 1),
  );

  // Theme Data
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      onPrimary: Colors.white,
      onSurface: textMain,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: header.copyWith(fontSize: 20),
      iconTheme: const IconThemeData(color: textMain),
      scrolledUnderElevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),
  );
}
