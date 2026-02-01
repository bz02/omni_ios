import 'package:flutter/material.dart';

/// Mystical color palette for emotionally resonant fortune telling
class MysticalColors {
  // Primary - Soft and dreamy
  static const Color lavender = Color(0xFFC4A2D8);
  static const Color roseQuartz = Color(0xFFFFB6D9);
  static const Color moonlightBlue = Color(0xFFB4D4FF);
  static const Color peachGlow = Color(0xFFFFD4B2);
  
  // Accents
  static const Color pearlWhite = Color(0xFFFFF5EE);
  static const Color softPurple = Color(0xFFE5D4ED);
  static const Color blushPink = Color(0xFFFFE5EC);
  static const Color mintDream = Color(0xFFD4F1F4);
  
  // Deep mystical
  static const Color twilightPurple = Color(0xFF9B7EBD);
  static const Color cosmicIndigo = Color(0xFF7B68EE);
  static const Color roseGold = Color(0xFFE8B4B8);
  
  // Gradients
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD4B2), // peach
      Color(0xFFFFB6D9), // rose
      Color(0xFFC4A2D8), // lavender
    ],
  );
  
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFB4D4FF), // moonlight blue
      Color(0xFFE5D4ED), // soft purple
      Color(0xFFFFE5EC), // blush pink
    ],
  );
  
  static const LinearGradient moonlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9B7EBD), // twilight purple
      Color(0xFFB4D4FF), // moonlight blue
      Color(0xFFD4F1F4), // mint dream
    ],
  );
  
  static const LinearGradient roseGoldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFFFB6D9), // rose quartz
      Color(0xFFE8B4B8), // rose gold
      Color(0xFFFFD4B2), // peach glow
    ],
  );
  
  // Element-specific colors
  static const Color woodElement = Color(0xFF98D8AA);
  static const Color fireElement = Color(0xFFFF9999);
  static const Color earthElement = Color(0xFFE8C4A0);
  static const Color metalElement = Color(0xFFE0E0E0);
  static const Color waterElement = Color(0xFF9DCEFF);
  
  // Get gradient for element
  static LinearGradient getElementGradient(String element) {
    switch (element.toLowerCase()) {
      case 'wood':
        return const LinearGradient(
          colors: [Color(0xFF98D8AA), Color(0xFFD4F1F4)],
        );
      case 'fire':
        return const LinearGradient(
          colors: [Color(0xFFFF9999), Color(0xFFFFD4B2)],
        );
      case 'earth':
        return const LinearGradient(
          colors: [Color(0xFFE8C4A0), Color(0xFFFFD4B2)],
        );
      case 'metal':
        return const LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFFB4D4FF)],
        );
      case 'water':
        return const LinearGradient(
          colors: [Color(0xFF9DCEFF), Color(0xFFB4D4FF)],
        );
      default:
        return sunsetGradient;
    }
  }
  
  // Shimmer/holographic effect colors
  static const List<Color> shimmerColors = [
    Color(0xFFFFFFFF),
    Color(0xFFFFF5EE),
    Color(0xFFFFE5EC),
    Color(0xFFE5D4ED),
    Color(0xFFB4D4FF),
  ];

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pearlWhite,
      colorScheme: const ColorScheme.light(
        primary: twilightPurple,
        secondary: roseQuartz,
        surface: pearlWhite,
        onPrimary: Colors.white,
        onSurface: twilightPurple,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: twilightPurple),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: twilightPurple),
        bodyMedium: TextStyle(color: twilightPurple),
      ),
    );
  }
}
