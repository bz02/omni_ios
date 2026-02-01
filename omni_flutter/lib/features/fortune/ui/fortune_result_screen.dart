import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/mystical_colors.dart';
import '../../../core/models/element.dart';
import '../../../core/models/ba_gua.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../services/fortune_service.dart';
import '../../../config/app_config.dart';

class FortuneResultScreen extends StatefulWidget {
  final DateTime birthDate;

  const FortuneResultScreen({super.key, required this.birthDate});

  @override
  State<FortuneResultScreen> createState() => _FortuneResultScreenState();
}

class _FortuneResultScreenState extends State<FortuneResultScreen> {
  late ChineseElement element;
  late BaGua trigram;
  String? fortune;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _calculateFortune();
  }

  Future<void> _calculateFortune() async {
    // Calculate element and trigram
    element = ChineseElement.getElementFromYear(widget.birthDate.year);
    trigram = BaGua.values[(widget.birthDate.month + widget.birthDate.day) % 8];

    // Generate fortune
    final service = FortuneService(apiKey: AppConfig.geminiApiKey);
    final reading = await service.generateFortune(
      birthDate: widget.birthDate,
      element: element,
      trigram: trigram,
    );

    if (mounted) {
      setState(() {
        fortune = reading;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: MysticalColors.getElementGradient(element.displayName),
        ),
        child: SafeArea(
          child: loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          MysticalColors.lavender,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'The universe is preparing your reading...',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ).animate(
                        onPlay: (controller) => controller.repeat(),
                      ).fadeIn(duration: 1500.ms),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Cosmic Identity Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: element == ChineseElement.fire
                                  ? MysticalColors.fireElement.withOpacity(0.3)
                                  : MysticalColors.lavender.withOpacity(0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            GradientText(
                              text: '✨ Your Cosmic Identity ✨',
                              gradient: MysticalColors.roseGoldGradient,
                              style: GoogleFonts.cinzel(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Element
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: MysticalColors.getElementGradient(
                                  element.displayName,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    element.displayName.split(' ').first,
                                    style: GoogleFonts.cinzel(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    element.displayName.split(' ').last.toUpperCase(),
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Trigram
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    MysticalColors.lavender.withOpacity(0.2),
                                    MysticalColors.roseQuartz.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: MysticalColors.lavender.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    trigram.symbol,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${trigram.displayName} ${trigram.chineseName}',
                                    style: GoogleFonts.cinzel(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: MysticalColors.twilightPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    trigram.traits,
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      color: MysticalColors.twilightPurple
                                          .withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      // Fortune Reading
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: MysticalColors.moonlightBlue.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GradientText(
                              text: 'Your Destiny Reading',
                              gradient: MysticalColors.moonlightGradient,
                              style: GoogleFonts.cinzel(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              fortune ?? '',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                height: 1.8,
                                color: MysticalColors.twilightPurple,
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: 300.ms, duration: 800.ms)
                        .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 40),

                      // Share button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: MysticalColors.sunsetGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: MysticalColors.roseQuartz.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.share, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              'Share Your Reading',
                              style: GoogleFonts.lato(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ).animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                      ).shimmer(duration: 2000.ms),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
