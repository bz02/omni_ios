import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glitch_text.dart';
import '../../../core/models/element.dart';
import '../models/pet_analysis.dart';

class ResultCard extends StatelessWidget {
  final PetAnalysis analysis;

  const ResultCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberColors.voidBlack,
      appBar: AppBar(
        title: const Text('ANALYSIS COMPLETE'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Archetype
            GlassContainer(
              child: Column(
                children: [
                  Text(
                    'SPIRITUAL ARCHETYPE',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: CyberColors.holoSilver.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlitchText(
                    text: analysis.archetype,
                    style: GoogleFonts.cinzel(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CyberColors.neonPurple,
                    ),
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: 600.ms)
              .shimmer(duration: 1500.ms, color: CyberColors.neonPurple),

            const SizedBox(height: 24),

            // Element & Power
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    child: Column(
                      children: [
                        Text(
                          'ELEMENT',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: CyberColors.holoSilver.withOpacity(0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          analysis.element.displayName,
                          style: GoogleFonts.cinzel(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getElementColor(analysis.element),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis.element.description,
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: CyberColors.holoSilver.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideX(begin: -0.2, end: 0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassContainer(
                    child: Column(
                      children: [
                        Text(
                          'POWER LEVEL',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: CyberColors.holoSilver.withOpacity(0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${analysis.powerLevel}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: analysis.powerLevel > 75
                                ? CyberColors.glitchRed
                                : analysis.powerLevel > 50
                                    ? CyberColors.neonPurple
                                    : CyberColors.zenGreen,
                          ),
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideX(begin: 0.2, end: 0),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // The Roast
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE ROAST',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: CyberColors.glitchRed,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '"${analysis.roast}"',
                    style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      color: CyberColors.holoSilver,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate()
              .fadeIn(duration: 600.ms, delay: 600.ms)
              .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // Done Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ACKNOWLEDGE'),
            ).animate()
              .fadeIn(duration: 600.ms, delay: 800.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
          ],
        ),
      ),
    );
  }

  Color _getElementColor(ChineseElement element) {
    switch (element) {
      case ChineseElement.wood:
        return CyberColors.zenGreen;
      case ChineseElement.fire:
        return CyberColors.glitchRed;
      case ChineseElement.earth:
        return CyberColors.mysticGold;
      case ChineseElement.metal:
        return CyberColors.holoSilver;
      case ChineseElement.water:
        return CyberColors.cosmicBlue;
    }
  }
}
