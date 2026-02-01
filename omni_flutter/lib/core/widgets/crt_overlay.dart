import 'package:flutter/material.dart';
import '../theme/cyber_colors.dart';

/// CRT scanline overlay effect
/// Adds retro monitor scanlines across the entire app
class CRTOverlay extends StatelessWidget {
  const CRTOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: List.generate(
              100,
              (index) => index % 2 == 0
                  ? CyberColors.voidBlack.withOpacity(0.05)
                  : Colors.transparent,
            ),
            stops: List.generate(100, (index) => index / 100),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Colors.transparent,
                CyberColors.voidBlack.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
