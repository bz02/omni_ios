/// The chart wheel.
///
/// Every competitor draws one, so this is table stakes rather than a
/// differentiator — but it is the object users screenshot, and a wheel that
/// stacks three glyphs on top of each other is the fastest way to look like a
/// weekend project. The geometry lives in `core/engine/wheel_layout.dart`
/// where it can be tested; this file only turns angles into paint.
///
/// Glyphs are drawn in the platform's default font rather than the app's
/// Google font, because the astrological symbols are not in the webfont and
/// would come back as tofu. The labels around them still use the app's type.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/engine/houses.dart';
import '../../core/engine/wheel_layout.dart';
import '../../core/engine/western_chart.dart';
import '../../core/theme/modern_theme.dart';

const double _deg = math.pi / 180.0;

/// Radius of the ring the planet glyphs sit on, as a fraction of the wheel.
const double planetRingFraction = 0.715;

/// Planet glyph size, as a fraction of [planetRingFraction]'s radius. Paired
/// with `glyphSeparationDegrees`, which has to clear it — see the test.
const double planetGlyphFraction = 0.155;

/// Fonts that actually contain the zodiac and planet symbols, in the order
/// each platform is likely to have one. The app's Google font has none of
/// them, and a wheel of empty boxes is worse than no wheel — this matters most
/// on web, which is the platform that takes money first.
const List<String> glyphFontFallback = [
  'Apple Symbols',
  'Segoe UI Symbol',
  'Noto Sans Symbols 2',
  'Noto Sans Symbols',
  'DejaVu Sans',
  'FreeSerif',
];

/// Colors by element, shared with the rest of the app so a Fire sign is the
/// same color here as it is in the element bar.
Color elementColor(WesternElement element) => switch (element) {
      WesternElement.fire => ModernTheme.vermilion,
      WesternElement.earth => ModernTheme.jade,
      WesternElement.air => ModernTheme.gold,
      WesternElement.water => ModernTheme.primary,
    };

/// Colors by aspect. Hard aspects red, soft aspects blue, conjunction neutral
/// — the convention in printed charts, and the one an experienced reader will
/// check first.
Color aspectColor(Aspect aspect) => switch (aspect) {
      Aspect.conjunction => const Color(0xFF9AA3B2),
      Aspect.sextile || Aspect.trine => const Color(0xFF5B8DEF),
      Aspect.square || Aspect.opposition => const Color(0xFFE0645C),
    };

class ChartWheel extends StatelessWidget {
  const ChartWheel({
    super.key,
    required this.chart,
    this.showAspects = true,
  });

  final WesternChart chart;
  final bool showAspects;

  @override
  Widget build(BuildContext context) {
    final layout = layoutWheel(chart);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          size: Size.square(constraints.maxWidth),
          painter: _WheelPainter(layout: layout, showAspects: showAspects),
          // The wheel is a picture, not a control, so it gets one label rather
          // than a screen reader walking twelve unlabelled glyphs.
          child: Semantics(
            label: 'Natal chart wheel. ${chart.bigThree}.',
            image: true,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.layout, required this.showAspects});

  final WheelLayout layout;
  final bool showAspects;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Ring radii as fractions of the outer radius. Tuned so the smallest a
    // wheel is ever drawn — a 150px card thumbnail — still has a legible
    // planet glyph.
    final signOuter = r * 0.995;
    final signInner = r * 0.845;
    final trueTick = r * 0.805;
    final planetRing = r * planetRingFraction;
    // The house ring has to clear the retrograde mark hanging below a glyph,
    // which the first render did not: they landed within three thousandths of
    // the radius of each other and read as one smudge.
    final houseOuter = r * 0.585;
    final houseNumber = r * 0.530;
    final aspectRing = r * 0.475;

    _paintSignRing(canvas, center, signOuter, signInner);
    _paintDegreeTicks(canvas, center, signInner, trueTick);
    _paintHouseRing(canvas, center, signInner, houseOuter, houseNumber,
        aspectRing);
    if (showAspects) _paintAspects(canvas, center, aspectRing);
    _paintBodies(canvas, center, signInner, trueTick, planetRing);
  }

  Offset _point(Offset center, double radius, double longitude) {
    final angle = layout.screenAngle(longitude) * _deg;
    // Screen y grows downwards, so counterclockwise needs the sine negated.
    return Offset(
      center.dx + radius * math.cos(angle),
      center.dy - radius * math.sin(angle),
    );
  }

  void _paintSignRing(
      Canvas canvas, Offset center, double outer, double inner) {
    for (final sign in ZodiacSign.values) {
      final start = sign.index * 30.0;
      final color = elementColor(sign.element);

      final path = Path()
        ..addArc(Rect.fromCircle(center: center, radius: outer),
            -layout.screenAngle(start) * _deg, -30 * _deg)
        ..arcTo(Rect.fromCircle(center: center, radius: inner),
            -layout.screenAngle(start + 30) * _deg, 30 * _deg, false)
        ..close();
      canvas.drawPath(path, Paint()..color = color.withOpacity(0.14));

      // Boundary spokes.
      canvas.drawLine(
        _point(center, inner, start),
        _point(center, outer, start),
        Paint()
          ..color = Colors.white.withOpacity(0.22)
          ..strokeWidth = 1,
      );

      _text(
        canvas,
        _point(center, (outer + inner) / 2, start + 15),
        sign.glyph,
        TextStyle(
          // Not a Google font: the zodiac glyphs are absent from the webfont.
          fontSize: outer * 0.085,
          color: color,
          fontWeight: FontWeight.w600,
          fontFamilyFallback: glyphFontFallback,
        ),
      );
    }

    for (final radius in [outer, inner]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = Colors.white.withOpacity(0.28),
      );
    }
  }

  void _paintDegreeTicks(
      Canvas canvas, Offset center, double inner, double tick) {
    final paint = Paint()..color = Colors.white.withOpacity(0.13);
    for (var d = 0; d < 360; d += 5) {
      final long = d.toDouble();
      final length = d % 30 == 0 ? (inner - tick) : (inner - tick) * 0.4;
      paint.strokeWidth = d % 30 == 0 ? 1.2 : 0.7;
      canvas.drawLine(
        _point(center, inner, long),
        _point(center, inner - length, long),
        paint,
      );
    }
  }

  void _paintHouseRing(Canvas canvas, Offset center, double signInner,
      double outer, double numberRadius, double aspectRing) {
    canvas.drawCircle(
      center,
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.18),
    );

    for (var i = 0; i < 12; i++) {
      final cusp = layout.cusps[i];
      // The Ascendant and Midheaven axes are the chart's skeleton and are
      // drawn heavier than the other cusps.
      final isAxis = layout.hasHouses && (i == 0 || i == 3 || i == 6 || i == 9);
      canvas.drawLine(
        _point(center, outer, cusp),
        _point(center, aspectRing, cusp),
        Paint()
          ..color = Colors.white.withOpacity(isAxis ? 0.4 : 0.16)
          ..strokeWidth = isAxis ? 1.4 : 0.8,
      );

      if (!layout.hasHouses) continue;
      final next = layout.cusps[(i + 1) % 12];
      final span = ((next - cusp) % 360 + 360) % 360;
      _text(
        canvas,
        _point(center, numberRadius, cusp + span / 2),
        '${i + 1}',
        TextStyle(
          fontSize: outer * 0.115,
          color: Colors.white.withOpacity(0.45),
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  void _paintAspects(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withOpacity(0.12),
    );

    for (final line in layout.aspects) {
      // Wide aspects fade rather than disappear: a seven-degree square is
      // real, and a reader who cannot see it thinks the chart is wrong.
      final opacity = 0.18 + 0.55 * line.strength;
      canvas.drawLine(
        _point(center, radius, line.from.longitude),
        _point(center, radius, line.to.longitude),
        Paint()
          ..color = aspectColor(line.aspect).withOpacity(opacity)
          ..strokeWidth = 0.7 + 1.1 * line.strength
          ..isAntiAlias = true,
      );
    }
  }

  void _paintBodies(Canvas canvas, Offset center, double signInner,
      double trueTick, double planetRing) {
    for (final glyph in layout.glyphs) {
      final body = glyph.body;
      final color = body.isAngle
          ? Colors.white.withOpacity(0.75)
          : elementColor(body.sign.element);

      // A mark at the true degree, so the wheel never hides where a body
      // actually is even when its glyph had to move.
      canvas.drawLine(
        _point(center, signInner, body.longitude),
        _point(center, trueTick, body.longitude),
        Paint()
          ..color = color
          ..strokeWidth = 1.6,
      );

      if (glyph.isDisplaced) {
        canvas.drawLine(
          _point(center, trueTick, body.longitude),
          _point(center, planetRing + planetRing * 0.09,
              glyph.displayLongitude),
          Paint()
            ..color = color.withOpacity(0.5)
            ..strokeWidth = 0.9,
        );
      }

      final at = _point(center, planetRing, glyph.displayLongitude);
      _text(
        canvas,
        at,
        body.glyph,
        TextStyle(
          fontSize: planetRing * (body.isAngle ? 0.11 : planetGlyphFraction),
          color: color,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: glyphFontFallback,
        ),
      );

      if (body.isRetrograde) {
        _text(
          canvas,
          _point(center, planetRing - planetRing * 0.125,
              glyph.displayLongitude),
          '℞',
          TextStyle(
            fontSize: planetRing * 0.08,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontFamilyFallback: glyphFontFallback,
          ),
        );
      }
    }
  }

  void _text(Canvas canvas, Offset at, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      at - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.layout != layout || old.showAspects != showAspects;
}

/// The wheel plus the legend it needs to be readable, on the app's dark chart
/// surface.
class ChartWheelPanel extends StatelessWidget {
  const ChartWheelPanel({
    super.key,
    required this.chart,
    this.showLegend = true,
  });

  final WesternChart chart;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final layout = layoutWheel(chart);
    return Container(
      decoration: BoxDecoration(
        color: ModernTheme.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartWheel(chart: chart),
          if (showLegend) ...[
            const SizedBox(height: 16),
            _Legend(layout: layout, hasHouses: layout.hasHouses),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.layout, required this.hasHouses});

  final WheelLayout layout;
  final bool hasHouses;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two columns of glyph plus placement. Wraps to one on a narrow
          // phone rather than overflowing.
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              for (final glyph in layout.glyphs)
                _LegendRow(body: glyph.body, hasHouses: hasHouses),
            ],
          ),
          if (!hasHouses) ...[
            const SizedBox(height: 14),
            Text(
              'No birth time, so no houses and no rising sign. The ring '
              'outside is the signs; the wheel starts at 0° Aries.',
              style: ModernTheme.caption.copyWith(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ],
      );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.body, required this.hasHouses});

  final WheelBody body;
  final bool hasHouses;

  @override
  Widget build(BuildContext context) {
    final color = body.isAngle
        ? Colors.white.withOpacity(0.75)
        : elementColor(body.sign.element);
    final degree = (body.longitude % 30).floor();
    return SizedBox(
      width: 148,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              body.glyph,
              style: TextStyle(
                fontSize: body.isAngle ? 12 : 16,
                color: color,
                fontWeight: FontWeight.w700,
                fontFamilyFallback: glyphFontFallback,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '$degree° ${body.sign.glyph}'
              '${body.isRetrograde ? ' ℞' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.82),
                fontWeight: FontWeight.w500,
                fontFamilyFallback: glyphFontFallback,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen wheel with the house system it was drawn in, and a switch.
class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key, required this.chart});

  final WesternChart chart;

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> {
  late HouseSystem _system = widget.chart.houseSystem;
  bool _aspects = true;

  @override
  Widget build(BuildContext context) {
    // Re-deriving the chart for the other house system would need the birth
    // data, which this screen does not have; the cusps are a pure function of
    // the ascendant, so they are recomputed here instead.
    final chart = widget.chart.ascendant == null
        ? widget.chart
        : WesternChart(
            sun: widget.chart.sun,
            moon: widget.chart.moon,
            ascendant: widget.chart.ascendant,
            midheaven: widget.chart.midheaven,
            planets: widget.chart.planets,
            precision: widget.chart.precision,
            houseSystem: _system,
            cusps: houseCusps(
              ascendantLongitude: widget.chart.ascendant!.longitude,
              system: _system,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wheel'),
        actions: [
          IconButton(
            tooltip: _aspects ? 'Hide aspects' : 'Show aspects',
            icon: Icon(_aspects
                ? Icons.hub_outlined
                : Icons.radio_button_unchecked),
            onPressed: () => setState(() => _aspects = !_aspects),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            decoration: BoxDecoration(
              color: ModernTheme.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChartWheel(chart: chart, showAspects: _aspects),
                const SizedBox(height: 16),
                _Legend(
                  layout: layoutWheel(chart),
                  hasHouses: chart.cusps != null,
                ),
              ],
            ),
          ),
          if (widget.chart.ascendant != null) ...[
            const SizedBox(height: 20),
            Text('HOUSE SYSTEM',
                style: ModernTheme.caption.copyWith(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final system in HouseSystem.values)
              RadioListTile<HouseSystem>(
                value: system,
                groupValue: _system,
                onChanged: (value) => setState(() => _system = value!),
                contentPadding: EdgeInsets.zero,
                title: Text(system.label,
                    style: ModernTheme.subHeader.copyWith(fontSize: 15)),
                subtitle: Text(system.explanation,
                    style: ModernTheme.caption.copyWith(fontSize: 12)),
              ),
          ],
          const SizedBox(height: 16),
          _AspectKey(),
        ],
      ),
    );
  }
}

class _AspectKey extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: ModernTheme.cardDecoration,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What the lines mean',
                style: ModernTheme.subHeader.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            for (final aspect in Aspect.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 3,
                      decoration: BoxDecoration(
                        color: aspectColor(aspect),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${aspect.label} · ${aspect.exactDegrees}° · '
                        '${aspect.gist}',
                        style: ModernTheme.caption.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Brighter lines are closer to exact. A glyph joined to its '
              'degree mark by a thin line was nudged sideways so it did not '
              'sit on its neighbor — the mark on the ring is the real '
              'position.',
              style: ModernTheme.caption.copyWith(fontSize: 12, height: 1.5),
            ),
          ],
        ),
      );
}
