import 'package:flutter_test/flutter_test.dart';
import 'package:omni_flutter/core/engine/astro_math.dart';
import 'package:omni_flutter/core/engine/western_chart.dart';

void main() {
  group('sun sign boundaries', () {
    test('flips at the exact equinox, not on a fixed calendar date', () {
      // The 2024 March equinox falls at 03:06 UTC on the 20th.
      final before = computeWesternChart(
          birthLocal: DateTime(2024, 3, 20, 2), utcOffsetHours: 0);
      final after = computeWesternChart(
          birthLocal: DateTime(2024, 3, 20, 4), utcOffsetHours: 0);
      expect(before.sun.sign, ZodiacSign.pisces);
      expect(after.sun.sign, ZodiacSign.aries);
    });

    test('warns when a placement sits on a cusp', () {
      final chart = computeWesternChart(
          birthLocal: DateTime(2024, 3, 20, 2), utcOffsetHours: 0);
      expect(chart.cuspWarnings, contains('Sun'));
    });

    test('visits all twelve signs across a year', () {
      final signs = <ZodiacSign>{};
      for (var day = 0; day < 365; day += 7) {
        signs.add(computeWesternChart(
                birthLocal: DateTime(2024, 1, 1).add(Duration(days: day)),
                utcOffsetHours: 0,
                hourIsKnown: false)
            .sun
            .sign);
      }
      expect(signs.length, 12);
    });
  });

  group('time zones', () {
    test('the same instant recorded in two zones gives one chart', () {
      final newYork = computeWesternChart(
          birthLocal: DateTime(1990, 7, 4, 8, 30),
          utcOffsetHours: -4,
          latitudeNorth: 40.71,
          longitudeEast: -74.01);
      final greenwich = computeWesternChart(
          birthLocal: DateTime(1990, 7, 4, 12, 30),
          utcOffsetHours: 0,
          latitudeNorth: 40.71,
          longitudeEast: -74.01);
      expect(newYork.sun.formatted, greenwich.sun.formatted);
      expect(newYork.moon!.formatted, greenwich.moon!.formatted);
      expect(newYork.ascendant!.formatted, greenwich.ascendant!.formatted);
    });
  });

  group('precision degrades honestly', () {
    test('time and place known gives all three placements', () {
      final chart = computeWesternChart(
          birthLocal: DateTime(1990, 7, 4, 8, 30),
          utcOffsetHours: -4,
          latitudeNorth: 40.71,
          longitudeEast: -74.01);
      expect(chart.precision, ChartPrecision.full);
      expect(chart.ascendant, isNotNull);
      expect(chart.bigThree.split('·').length, 3);
    });

    test('no birthplace drops the ascendant rather than guessing', () {
      final chart = computeWesternChart(
          birthLocal: DateTime(1990, 7, 4, 8, 30), utcOffsetHours: -4);
      expect(chart.precision, ChartPrecision.noBirthPlace);
      expect(chart.ascendant, isNull);
      expect(chart.moon, isNotNull);
    });

    test('no birth time drops the Moon as well', () {
      final chart = computeWesternChart(
          birthLocal: DateTime(1990, 7, 4),
          utcOffsetHours: -4,
          hourIsKnown: false);
      expect(chart.precision, ChartPrecision.dateOnly);
      expect(chart.moon, isNull);
      expect(chart.ascendant, isNull);
      expect(chart.bigThree, 'Cancer Sun');
    });
  });

  group('aspects', () {
    test('recognizes the five Ptolemaic aspects', () {
      expect(aspectBetween(10, 12)!.aspect, Aspect.conjunction);
      expect(aspectBetween(10, 70)!.aspect, Aspect.sextile);
      expect(aspectBetween(10, 100)!.aspect, Aspect.square);
      expect(aspectBetween(10, 130)!.aspect, Aspect.trine);
      expect(aspectBetween(350, 170)!.aspect, Aspect.opposition);
    });

    test('returns null outside orb', () {
      expect(aspectBetween(10, 55), isNull);
    });

    test('is symmetric', () {
      expect(aspectBetween(10, 130)!.aspect, aspectBetween(130, 10)!.aspect);
    });
  });

  test('placement reports degrees within the sign', () {
    const placement = Placement(125.5);
    expect(placement.sign, ZodiacSign.leo);
    expect(placement.degreeInSign, closeTo(5.5, 1e-9));
    expect(placement.isOnCusp, isFalse);
  });
}
