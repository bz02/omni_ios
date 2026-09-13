import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/mystical_colors.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/shimmer_button.dart';
import 'fortune_result_screen.dart';

class FortuneInputScreen extends StatefulWidget {
  const FortuneInputScreen({super.key});

  @override
  State<FortuneInputScreen> createState() => _FortuneInputScreenState();
}

class _FortuneInputScreenState extends State<FortuneInputScreen> {
  DateTime? _birthDate;
  bool _loading = false;

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MysticalColors.lavender,
              onPrimary: Colors.white,
              surface: MysticalColors.pearlWhite,
              onSurface: MysticalColors.twilightPurple,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _revealDestiny() {
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birth date ✨')),
      );
      return;
    }

    setState(() => _loading = true);

    // Simulate loading for mystical effect
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FortuneResultScreen(birthDate: _birthDate!),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MysticalColors.auroraGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Header with floating animation
                Center(
                  child: Column(
                    children: [
                      GradientText(
                        text: '✨ Discover Your Destiny ✨',
                        gradient: MysticalColors.roseGoldGradient,
                        style: GoogleFonts.cinzel(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate()
                        .fadeIn(duration: 800.ms)
                        .slideY(begin: -0.3, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'The universe has a message just for you',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: MysticalColors.twilightPurple,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ).animate()
                        .fadeIn(delay: 300.ms, duration: 800.ms),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Birth date input card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: MysticalColors.lavender.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'When were you born?',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: MysticalColors.twilightPurple,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date display/selector
                      InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                MysticalColors.pearlWhite,
                                MysticalColors.blushPink.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: MysticalColors.roseQuartz.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _birthDate == null
                                    ? 'Select your birth date'
                                    : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: _birthDate == null
                                      ? MysticalColors.twilightPurple.withOpacity(0.5)
                                      : MysticalColors.twilightPurple,
                                  fontWeight: _birthDate == null
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: MysticalColors.roseQuartz,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Text(
                        'The stars were aligned in a unique way on your special day ✨',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: MysticalColors.twilightPurple.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(delay: 500.ms, duration: 800.ms)
                  .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 60),
                
                // Reveal button
                Center(
                  child: ShimmerButton(
                    text: _loading ? '' : 'Reveal My Destiny',
                    onPressed: _revealDestiny,
                    gradient: MysticalColors.sunsetGradient,
                    loading: _loading,
                  ).animate()
                    .fadeIn(delay: 800.ms, duration: 800.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                ),
                
                const SizedBox(height: 24),
                
                // Mystical note
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Your reading is created with ancient wisdom combined with modern insights, uniquely for you 💫',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: MysticalColors.twilightPurple.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ).animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).fadeIn(duration: 2000.ms),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
