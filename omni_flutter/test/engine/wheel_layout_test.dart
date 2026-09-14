/// The wheel's geometry, checked as invariants rather than by eye.
///
/// A glyph layout is either readable or it is not, and "looks fine on my
/// chart" is not a test. The three things a reader depends on — nothing
/// overlapping, cyclic order untouched, nothing moved further than it had to
/// be — are each stated here and checked over thousands of random skies.
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/astro_math.dart';
import 'package:omni_flutter/core/engine/houses.dart';
import 'package:omni_flutter/core/engine/wheel_layout.dart';
import 'package:omni_flutter/core/engine/western_chart.dart';

/// Shortest distance between two longitudes, 0 to 180.
double _separation(double a, double b) {
  final d = normalizeDegrees(a - b);
  return d > 180 ? 360 - d : d;
}

/// The smallest gap between any neighboring pair around the circle.
double _minGap(List<double> angles) {
  final sorted = [for (final a in angles) normalizeDegrees(a)]..sort();
  var smallest = 360.0;
  for (var i = 0; i < sorted.length; i++) {
    final gap = normalizeDegrees(sorted[(i + 1) % sorted.length] - sorted[i]);
    if (sorted.length > 1 && gap < smallest) smallest = gap;
  }
  return smallest;
}

/// True when [after] visits its elements in the same cyclic order as [before].
bool _sameCyclicOrder(List<double> before, List<double> after) {
  final n = before.length;
  final byBefore = List<int>.generate(n, (i) => i)
    ..sort((a, b) =>
        normalizeDegrees(before[a]).compareTo(normalizeDegrees(before[b])));
  final byAfter = List<int>.generate(n, (i) => i)
    ..sort((a, b) =>
        normalizeDegrees(after[a]).compareTo(normalizeDegrees(after[b])));
  // Same ring, possibly starting at a different element.
  for (var shift = 0; shift < n; shift++) {
    var matches = true;
    for (var i = 0; i < n; i++) {
      if (byBefore[i] != byAfter[(i + shift) % n]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}

void main() {
  group('spreadGlyphs', () {
    test('leaves a well-separated sky exactly where it is', () {
      final input = [10.0, 80.0, 150.0, 220.0, 300.0];
      final out = spreadGlyphs(input, minSeparation: 7);
      for (var i = 0; i < input.length; i++) {
        expect(out[i], closeTo(input[i], 1e-9));
      }
    });

    test('separates a stellium to exactly the minimum, no further', () {
      // Sun, Mercury and Venus piled inside three degrees, which is an
      // ordinary configuration and the case that ruins a naive wheel.
      final out = spreadGlyphs([100.0, 101.0, 102.5], minSeparation: 7);
      expect(_minGap(out), closeTo(7.0, 1e-9));
      // The center of mass does not move: pushing the whole cluster sideways
      // would misreport which sign the group sits in.
      const before = (100.0 + 101.0 + 102.5) / 3;
      final after = out.reduce((a, b) => a + b) / 3;
      expect(after, closeTo(before, 1e-9));
    });

    test('preserves order through a cluster', () {
      final out = spreadGlyphs([100.0, 101.0, 102.5], minSeparation: 7);
      expect(out[0], lessThan(out[1]));
      expect(out[1], lessThan(out[2]));
    });

    test('spreads a cluster sitting on 0° Aries without reordering it', () {
      // The seam is where hand-rolled implementations break: 359° and 1° are
      // two degrees apart, not 358.
      final input = [357.0, 359.0, 1.0, 3.0];
      final out = spreadGlyphs(input, minSeparation: 7);
      expect(_minGap(out), greaterThanOrEqualTo(7.0 - 1e-9));
      expect(_sameCyclicOrder(input, out), isTrue);
    });

    test('falls back to even spacing when the circle cannot hold them', () {
      // Twelve glyphs cannot all be 40° apart. The only feasible answer is 30°.
      final out = spreadGlyphs(
        [for (var i = 0; i < 12; i++) i * 2.0],
        minSeparation: 40,
      );
      expect(_minGap(out), closeTo(30.0, 1e-9));
    });

    test('handles the empty and single cases', () {
      expect(spreadGlyphs(const []), isEmpty);
      expect(spreadGlyphs([371.0]).single, closeTo(11.0, 1e-9));
    });

    test('holds its invariants over ten thousand random skies', () {
      final random = math.Random(20260914);
      for (var trial = 0; trial < 10000; trial++) {
        final n = 1 + random.nextInt(12);
        final input = <double>[];
        if (random.nextBool()) {
          // Uniform sky.
          for (var i = 0; i < n; i++) {
            input.add(random.nextDouble() * 360);
          }
        } else {
          // Clumped sky, which is what real charts look like: everything
          // within a couple of signs of the Sun.
          final center = random.nextDouble() * 360;
          for (var i = 0; i < n; i++) {
            input.add(normalizeDegrees(center + (random.nextDouble() - 0.5) * 20));
          }
        }
        final out = spreadGlyphs(input, minSeparation: 7);
        final feasible = math.min(7.0, 360.0 / n);

        expect(out.length, n);
        if (n > 1) {
          expect(_minGap(out), greaterThanOrEqualTo(feasible - 1e-9),
              reason: 'overlap on trial $trial with $input');
        }
        expect(_sameCyclicOrder(input, out), isTrue,
            reason: 'reordered on trial $trial with $input');
        for (var i = 0; i < n; i++) {
          // Nothing needs to travel more than half the circle to make room.
          expect(_separation(out[i], input[i]), lessThanOrEqualTo(180.0 + 1e-9),
              reason: 'wild displacement on trial $trial');
        }
      }
    });

    test('moves glyphs no further than a correct alternative would', () {
      // Isotonic regression returns the exact minimum, so a naive "walk right
      // until there is room" pass cannot beat it. Compare against one.
      //
      // The baseline only makes sense on a sky that does not cross 0° Aries:
      // as a straight line it has no seam to satisfy, so across one it happily
      // returns a cheaper answer that overlaps. Inputs are kept clear of the
      // seam, and the baseline is checked to be feasible before its cost is
      // allowed to mean anything.
      final random = math.Random(7);
      for (var trial = 0; trial < 500; trial++) {
        final n = 2 + random.nextInt(8);
        final center = 40 + random.nextDouble() * 200;
        final input = [
          for (var i = 0; i < n; i++) center + random.nextDouble() * 30,
        ]..sort();

        final ours = spreadGlyphs(input, minSeparation: 7);

        // Naive: keep the first, push each later one to clear its neighbor.
        final naive = [input.first];
        for (var i = 1; i < n; i++) {
          naive.add(math.max(input[i], naive.last + 7));
        }
        expect(_minGap(naive), greaterThanOrEqualTo(7.0 - 1e-9),
            reason: 'baseline is not a valid layout on trial $trial');

        var ourCost = 0.0;
        var naiveCost = 0.0;
        for (var i = 0; i < n; i++) {
          ourCost += math.pow(_separation(ours[i], input[i]), 2);
          naiveCost += math.pow(_separation(naive[i], input[i]), 2);
        }
        expect(ourCost, lessThanOrEqualTo(naiveCost + 1e-6),
            reason: 'beaten by the naive pass on trial $trial');
      }
    });

    test('spreads across the seam where a line-based pass would not', () {
      // The regression that motivates the note above: three bodies straddling
      // 0° Aries look well separated to anything that sorts by longitude and
      // walks right, because 356° and 0° are 356 apart on a line and four on a
      // circle.
      final input = [356.28, 0.25, 12.44];
      final out = spreadGlyphs(input, minSeparation: 7);
      expect(_minGap(input), lessThan(7.0));
      expect(_minGap(out), greaterThanOrEqualTo(7.0 - 1e-9));
      expect(_sameCyclicOrder(input, out), isTrue);
    });
  });

  group('layoutWheel', () {
    WesternChart chartFor({bool hourIsKnown = true, bool withPlace = true}) =>
        computeWesternChart(
          birthLocal: DateTime(1990, 6, 15, 14, 30),
          utcOffsetHours: -7,
          latitudeNorth: withPlace ? 34.05 : null,
          longitudeEast: withPlace ? -118.24 : null,
          hourIsKnown: hourIsKnown,
        );

    test('puts the ascendant at nine o’clock', () {
      final chart = chartFor();
      final layout = layoutWheel(chart);
      expect(layout.screenAngle(chart.ascendant!.longitude), closeTo(180, 1e-9));
    });

    test('quarters the wheel from the first cusp', () {
      // Screen angles are counterclockwise from three o’clock, so the bottom
      // of a chart is 270°. Getting this backwards mirrors the whole wheel.
      //
      // Note the fourth cusp is *not* at the bottom under Whole Sign: the
      // first house there is the entire rising sign, so the angles float
      // inside the houses rather than sitting on them. That is the system
      // working, and the equal-house case below pins the orientation instead.
      final chart = chartFor();
      final layout = layoutWheel(chart);
      expect(layout.hasHouses, isTrue);
      expect(layout.screenAngle(layout.cusps[3]),
          closeTo(normalizeDegrees(layout.screenAngle(layout.cusps[0]) + 90), 1e-9));
      expect(layout.screenAngle(chart.ascendant!.longitude), closeTo(180, 1e-9));
    });

    test('puts the equal-house fourth cusp at the bottom of the screen', () {
      final chart = computeWesternChart(
        birthLocal: DateTime(1990, 6, 15, 14, 30),
        utcOffsetHours: -7,
        latitudeNorth: 34.05,
        longitudeEast: -118.24,
        houseSystem: HouseSystem.equal,
      );
      final layout = layoutWheel(chart);
      expect(layout.screenAngle(layout.cusps[3]), closeTo(270, 1e-9));
    });

    test('draws every body without overlap', () {
      final layout = layoutWheel(chartFor());
      final angles = [for (final g in layout.glyphs) g.displayLongitude];
      expect(_minGap(angles), greaterThanOrEqualTo(7.0 - 1e-9));
      expect(layout.glyphs.length, 12); // Sun, Moon, eight planets, AC, MC.
    });

    test('never aspects an angle', () {
      final layout = layoutWheel(chartFor());
      for (final line in layout.aspects) {
        expect(line.from.isAngle, isFalse);
        expect(line.to.isAngle, isFalse);
      }
    });

    test('aspect strength peaks at exact and vanishes at the edge of orb', () {
      const tight = AspectLine(
          from: WheelBody(label: 'a', glyph: 'a', longitude: 0),
          to: WheelBody(label: 'b', glyph: 'b', longitude: 120),
          aspect: Aspect.trine,
          orb: 0);
      const wide = AspectLine(
          from: WheelBody(label: 'a', glyph: 'a', longitude: 0),
          to: WheelBody(label: 'b', glyph: 'b', longitude: 128),
          aspect: Aspect.trine,
          orb: 8);
      expect(tight.strength, closeTo(1.0, 1e-9));
      expect(wide.strength, closeTo(0.0, 1e-9));
    });

    test('still draws a chart with no birth time, and claims no houses', () {
      final layout = layoutWheel(chartFor(hourIsKnown: false));
      expect(layout.hasHouses, isFalse);
      // Sign boundaries, not houses: the ring must not be labeled 1 to 12.
      expect(layout.cusps.first, 0.0);
      expect(layout.rotationLongitude, 0.0);
      expect(layout.glyphs, isNotEmpty);
      expect(
        layout.glyphs.where((g) => g.body.label == 'Ascendant'),
        isEmpty,
      );
    });

    test('marks a nudged glyph as displaced so a leader line is drawn', () {
      final random = math.Random(3);
      var sawDisplaced = false;
      for (var i = 0; i < 200 && !sawDisplaced; i++) {
        final layout = layoutWheel(computeWesternChart(
          birthLocal: DateTime(1960 + random.nextInt(60), 1 + random.nextInt(12),
              1 + random.nextInt(28), random.nextInt(24)),
          utcOffsetHours: -5,
          latitudeNorth: 40.7,
          longitudeEast: -74.0,
        ));
        sawDisplaced = layout.glyphs.any((g) => g.isDisplaced);
      }
      expect(sawDisplaced, isTrue,
          reason: 'twelve bodies on one circle always collide somewhere');
    });

    test('respects the equal house system when asked for it', () {
      final chart = computeWesternChart(
        birthLocal: DateTime(1990, 6, 15, 14, 30),
        utcOffsetHours: -7,
        latitudeNorth: 34.05,
        longitudeEast: -118.24,
        houseSystem: HouseSystem.equal,
      );
      final layout = layoutWheel(chart);
      expect(layout.cusps.first, closeTo(chart.ascendant!.longitude, 1e-9));
    });
  });
}
