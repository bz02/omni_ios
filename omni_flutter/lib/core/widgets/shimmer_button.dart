import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Button with holographic shimmer effect
class ShimmerButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient gradient;
  final bool loading;
  
  const ShimmerButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    this.loading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            child: loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3));
  }
}
