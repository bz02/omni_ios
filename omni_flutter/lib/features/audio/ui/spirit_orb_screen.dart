import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/cyber_colors.dart';
import '../providers/audio_provider.dart';

class SpiritOrbScreen extends ConsumerWidget {
  const SpiritOrbScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amplitudeStream = ref.watch(amplitudeStreamProvider);

    return Scaffold(
      backgroundColor: CyberColors.voidBlack,
      appBar: AppBar(
        title: const Text('SPIRIT COMMUNICATOR'),
      ),
      body: Center(
        child: amplitudeStream.when(
          data: (amplitude) {
            final controller = ref.read(amplitudeStreamProvider.notifier);
            final state = controller.getState(amplitude);
            
            // Trigger haptic on Fire state
            if (state == AudioState.fire) {
              HapticFeedback.lightImpact();
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spirit Orb
                SpiritOrb(
                  amplitude: amplitude,
                  state: state,
                ),
                
                const SizedBox(height: 48),
                
                // State Message
                Text(
                  state.message,
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    color: state == AudioState.fire 
                        ? CyberColors.glitchRed
                        : state == AudioState.water
                            ? CyberColors.cosmicBlue
                            : CyberColors.holoSilver,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ).animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 500.ms)
                  .then()
                  .fadeOut(duration: 500.ms),
                
                const SizedBox(height: 24),
                
                // Amplitude Display
                Text(
                  '${amplitude.toStringAsFixed(1)} dB',
                  style: GoogleFonts.spaceMono(
                    fontSize: 32,
                    color: CyberColors.neonPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(
            color: CyberColors.neonPurple,
          ),
          error: (error, stack) => Text(
            'SPIRIT CONNECTION LOST',
            style: GoogleFonts.spaceMono(
              color: CyberColors.glitchRed,
            ),
          ),
        ),
      ),
    );
  }
}

class SpiritOrb extends StatelessWidget {
  final double amplitude;
  final AudioState state;

  const SpiritOrb({
    super.key,
    required this.amplitude,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate size based on amplitude
    final size = (100 + (amplitude * 2).abs().clamp(0, 200)).toDouble();
    
    // Determine color based on state
    final color = state == AudioState.fire
        ? CyberColors.glitchRed
        : state == AudioState.water
            ? CyberColors.cosmicBlue
            : CyberColors.zenGreen;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 20,
          ),
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 80,
            spreadRadius: 40,
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(
        duration: 2000.ms,
        color: Colors.white.withOpacity(0.3),
      );
  }
}
