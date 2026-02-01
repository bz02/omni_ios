import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/cyber_colors.dart';

/// Glitch text effect widget
/// Creates RGB split effect with random offset animation
class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final double glitchIntensity;
  
  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.glitchIntensity = 2.0,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> {
  Timer? _glitchTimer;
  double _offsetX = 0;
  double _offsetY = 0;

  @override
  void initState() {
    super.initState();
    _startGlitch();
  }

  @override
  void dispose() {
    _glitchTimer?.cancel();
    super.dispose();
  }

  void _startGlitch() {
    _glitchTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (mounted) {
          setState(() {
            _offsetX = (DateTime.now().millisecond % 2 == 0) 
                ? widget.glitchIntensity 
                : -widget.glitchIntensity;
            _offsetY = (DateTime.now().millisecond % 3 == 0) 
                ? widget.glitchIntensity 
                : 0;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = widget.style ?? 
        GoogleFonts.cinzel(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: CyberColors.holoSilver,
        );

    return Stack(
      children: [
        // Red channel (offset left)
        Transform.translate(
          offset: Offset(-_offsetX, -_offsetY),
          child: Text(
            widget.text,
            style: effectiveStyle.copyWith(
              color: CyberColors.glitchRed.withOpacity(0.7),
            ),
          ),
        ),
        // Cyan channel (offset right)
        Transform.translate(
          offset: Offset(_offsetX, _offsetY),
          child: Text(
            widget.text,
            style: effectiveStyle.copyWith(
              color: CyberColors.cosmicBlue.withOpacity(0.7),
            ),
          ),
        ),
        // Original text (center)
        Text(
          widget.text,
          style: effectiveStyle,
        ),
      ],
    );
  }
}
