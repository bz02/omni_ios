import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/cyber_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../core/widgets/glitch_text.dart';
import '../../../core/models/element.dart';
import '../logic/affinity_calculator.dart';

class MatchmakingScreen extends StatefulWidget {
  final ChineseElement petElement;

  const MatchmakingScreen({
    super.key,
    required this.petElement,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  int _selectedYear = DateTime.now().year - 20;
  String? _affinity;

  void _calculateAffinity() {
    final userElement = ChineseElement.getElementFromYear(_selectedYear);
    final result = AffinityCalculator.calculateAffinity(userElement, widget.petElement);
    
    setState(() {
      _affinity = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userElement = ChineseElement.getElementFromYear(_selectedYear);

    return Scaffold(
      backgroundColor: CyberColors.voidBlack,
      appBar: AppBar(
        title: const Text('KARMIC CONTRACT'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const GlitchText(
              text: 'INTERSPECIES COMPATIBILITY',
            ),
            
            const SizedBox(height: 32),

            // Pet Element
            GlassContainer(
              child: Column(
                children: [
                  Text(
                    'DIVINE BEAST ELEMENT',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: CyberColors.holoSilver.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.petElement.displayName,
                    style: GoogleFonts.cinzel(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CyberColors.neonPurple,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Year Picker
            GlassContainer(
              child: Column(
                children: [
                  Text(
                    'YOUR BIRTH YEAR',
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      color: CyberColors.holoSilver.withOpacity(0.7),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: 50,
                      ),
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedYear = DateTime.now().year - 100 + index;
                          _affinity = null; // Reset affinity
                        });
                      },
                      children: List.generate(
                        100,
                        (index) {
                          final year = DateTime.now().year - 100 + index;
                          return Center(
                            child: Text(
                              '$year',
                              style: GoogleFonts.spaceMono(
                                fontSize: 20,
                                color: CyberColors.holoSilver,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Element: ${userElement.displayName}',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      color: CyberColors.zenGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Calculate Button
            ElevatedButton(
              onPressed: _calculateAffinity,
              child: const Text('REVEAL FATE'),
            ),

            if (_affinity != null) ...[
              const SizedBox(height: 32),
              
              // Affinity Result
              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KARMIC BOND',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: CyberColors.neonPurple,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlitchText(
                      text: _affinity!,
                      style: GoogleFonts.spaceMono(
                        fontSize: 16,
                        color: CyberColors.holoSilver,
                        height: 1.5,
                      ),
                      glitchIntensity: 1,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
