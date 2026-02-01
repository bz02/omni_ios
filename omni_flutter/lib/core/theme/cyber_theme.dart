import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cyber_colors.dart';

/// Cyber-Taoist Theme Configuration
class CyberTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: CyberColors.voidBlack,
      primaryColor: CyberColors.neonPurple,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: CyberColors.neonPurple,
        secondary: CyberColors.cosmicBlue,
        error: CyberColors.glitchRed,
        surface: CyberColors.voidBlack,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: CyberColors.holoSilver,
        onError: Colors.white,
      ),
      
      // Typography
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.cinzel(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: CyberColors.holoSilver,
          letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.cinzel(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: CyberColors.holoSilver,
          letterSpacing: 1.2,
        ),
        headlineSmall: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: CyberColors.holoSilver,
        ),
        bodyLarge: GoogleFonts.spaceMono(
          fontSize: 16,
          color: CyberColors.holoSilver,
          letterSpacing: 0.5,
        ),
        bodyMedium: GoogleFonts.spaceMono(
          fontSize: 14,
          color: CyberColors.holoSilver,
        ),
        bodySmall: GoogleFonts.spaceMono(
          fontSize: 12,
          color: CyberColors.holoSilver.withOpacity(0.7),
        ),
        labelLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CyberColors.neonPurple,
          letterSpacing: 1.0,
        ),
      ),
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: CyberColors.voidBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: CyberColors.holoSilver,
          letterSpacing: 2.0,
        ),
        iconTheme: const IconThemeData(
          color: CyberColors.neonPurple,
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CyberColors.neonPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: CyberColors.neonPurple,
        size: 24,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CyberColors.glassBlack40,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CyberColors.glassWhite10,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CyberColors.glassWhite10,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: CyberColors.neonPurple,
            width: 2,
          ),
        ),
        labelStyle: GoogleFonts.spaceMono(
          color: CyberColors.holoSilver,
        ),
        hintStyle: GoogleFonts.spaceMono(
          color: CyberColors.holoSilver.withOpacity(0.5),
        ),
      ),
    );
  }
}
