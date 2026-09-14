/// The image people post.
///
/// Compatibility is the category's growth loop — it needs two birthdays, so
/// getting a result means messaging someone — and the object that actually
/// travels is a screenshot. So this is designed to be legible at thumbnail
/// size in an Instagram story: one enormous number, two names, and the one
/// line that makes somebody ask what app that is.
///
/// The line that does that work here is the disagreement. "Chinese astrology
/// says 88, Western says 41" is a far more postable result than a single
/// averaged score, and no competitor can produce it.
library;

import 'package:flutter/material.dart';

import '../../core/engine/compatibility.dart';
import '../../core/theme/modern_theme.dart';

/// Instagram story proportions. Everything is sized against [width] so the
/// same widget renders correctly at preview scale and at capture scale.
const double shareCardWidth = 1080;
const double shareCardHeight = 1920;

class CompatibilityShareCard extends StatelessWidget {
  const CompatibilityShareCard({
    super.key,
    required this.result,
    required this.yourName,
    required this.theirName,
  });

  final CompatibilityResult result;
  final String yourName;
  final String theirName;

  @override
  Widget build(BuildContext context) {
    // One scale factor drives every dimension, so the card is identical at
    // any render size.
    const w = shareCardWidth;
    final accent = ModernTheme.forScore(result.score);

    return SizedBox(
      width: w,
      height: shareCardHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: ModernTheme.ink),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(96, 130, 96, 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${yourName.toUpperCase()}  ×  ${theirName.toUpperCase()}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 40,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 60),
              Text(
                '${result.score}',
                style: TextStyle(
                  color: accent,
                  fontSize: 340,
                  height: 0.85,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                result.band.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 72),

              // The two traditions, scored apart. This is the part nobody else
              // has, so it gets its own block rather than a footnote.
              Row(
                children: [
                  Expanded(
                    child: _Half(
                      label: '東  CHINESE',
                      score: result.easternScore,
                      color: ModernTheme.jade,
                    ),
                  ),
                  Container(width: 2, height: 150, color: Colors.white12),
                  Expanded(
                    child: _Half(
                      label: '西  WESTERN',
                      score: result.westernScore,
                      color: const Color(0xFF8AA0FF),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 64),
              Container(height: 2, color: Colors.white12),
              const SizedBox(height: 48),

              Expanded(
                child: Text(
                  result.headline,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Wordmark over tagline, not beside it. Side by side they
              // overflow the 888px inner width by nearly 300 pixels once the
              // tagline is set large enough to survive a thumbnail.
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('☯',
                          style:
                              TextStyle(color: Colors.white, fontSize: 44)),
                      SizedBox(width: 20),
                      Text(
                        'OMNI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          letterSpacing: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'astrology that shows its work',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 30,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({required this.label, required this.score, required this.color});

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 30,
                letterSpacing: 5,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 18),
          Text('$score',
              style: TextStyle(
                color: color,
                fontSize: 110,
                height: 1,
                fontWeight: FontWeight.w800,
              )),
        ],
      );
}
